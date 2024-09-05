# SPDX-License-Identifier: Apache-2.0
# @summary configuyre git repos
# @param ensure ensurable parameter
# @param basedir the git repo base dir
# @param user the owner of the git repo
# @param group the group owner of the git repo
# @param control_repo the name of the main puppet control repo
# @param repos additional repos to configure
# @param exclude_servers exclude servers under maintenance from various configs
class profile::puppetserver::git (
    Wmflib::Ensure      $ensure             = lookup('profile::puppetserver::git::ensure'),
    Stdlib::Unixpath    $basedir            = lookup('profile::puppetserver::git::basedir'),
    String[1]           $user               = lookup('profile::puppetserver::git::user'),
    String[1]           $group              = lookup('profile::puppetserver::git::group'),
    String[1]           $control_repo       = lookup('profile::puppetserver::git::control_repo'),
    Hash[String, Hash]  $repos              = lookup('profile::puppetserver::git::repos'),
    Stdlib::Unixpath    $code_dir           = lookup('profile::puppetserver::code_dir'),
    Array[Stdlib::Host] $exclude_servers    = lookup('profile::puppetserver::git::exclude_servers')
) {
    $servers = (wmflib::role::hosts('puppetmaster::frontend') +
                wmflib::role::hosts('puppetmaster::backend') +
                wmflib::role::hosts('puppetserver') -
                $exclude_servers).sort.unique
    unless $repos.has_key($control_repo) {
        fail("\$control_repo (${control_repo}) must be defined in \$repos")
    }

    $control_repo_dir = "${basedir}/${control_repo}"
    $home_dir = "/home/${user}"

    systemd::sysuser { $user:
        home_dir          => $home_dir,
        shell             => '/bin/sh',
        additional_groups => [ 'prometheus-node-exporter' ],
    }
    file { $home_dir:
        ensure  => directory,
        owner   => $user,
        group   => $user,
        mode    => '0755',
        require => Systemd::Sysuser[$user],
    }
    # TODO: refactor this so its closer to the g10k code
    # This is required to run g10k as root
    sudo::user { $user:
        privileges => [
            'ALL = NOPASSWD: /usr/local/bin/puppetserver-deploy-code',
        ],
    }

    file {"${home_dir}/.ssh":
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => '0700',
    }
    file {
        default:
            ensure    => file,
            owner     => $user,
            group     => $group,
            mode      => '0400',
            show_diff => false;
        "${home_dir}/.ssh/id_rsa":
            content   => secret('ssh/gitpuppet/gitpuppet.key');
        "${home_dir}/.ssh/gitpuppet-private-repo":
            content   => secret('ssh/gitpuppet/gitpuppet-private.key');
    }
    ssh::userkey { $user:
        content => template('profile/puppetserver/git/gitpuppet_authorized_keys.erb'),
    }

    unless $servers.empty() {
        ferm::service { 'open access for puppetservers':
            proto  => 'tcp',
            port   => 22,
            srange => $servers,
        }
    }

    wmflib::dir::mkdir_p([$basedir.dirname, $basedir], {
        owner  => $user,
        group  => $group
    })

    $repos.each |$repo, $config| {
        $dir = "${basedir}/${repo}"

        if $config.has_key('safedir') and $config['safedir'] {
            git::systemconfig { "mark puppet repo ${dir} as safe":
                settings => {
                    'safe' => {
                        'directory' => $dir,
                    },
                },
            }
        } else {
            # By default in environments like Cloud we want to leverage the git's
            # safe directory checks to avoid users messing up with repos that should
            # be managed only by system users (like gitpuppet).
            git::systemconfig { "mark puppet repo ${dir} as safe":
                ensure   => absent,
                settings => {},
            }
        }
        $origin = $config['origin'].lest || { "https://gerrit.wikimedia.org/r/${repo}" }
        ensure_resource('file', $dir.dirname, {
            ensure => stdlib::ensure($ensure, 'directory'),
            owner  => $user,
            group  => $group,
        })
        if $config['init'] {
            file { $dir:
                ensure => directory,
                owner  => $user,
                group  => $group,
            }
            exec { "git init ${dir}":
                command => '/usr/bin/git init',
                user    => $user,
                group   => $group,
                cwd     => $dir,
                creates => "${dir}/.git",
                require => File[$dir],
            }
            $git_require = Exec["git init ${dir}"]
        } else {
            git::clone { $repo:
                ensure    => $ensure,
                directory => $dir,
                branch    => $config['branch'],
                origin    => $origin,
                owner     => $user,
                group     => $group,
                require   => File[$dir.dirname],
                before    => Service['puppetserver'],
            }
            $git_require = Git::Clone[$repo]
        }
        if $config.has_key('hooks') {
            $hooks_dir = "${dir}/.git/hooks"
            $config['hooks'].each |$hook, $source| {
                $content = $source.stdlib::start_with('puppet:///modules/') ? {
                    true    => {'source' => $source},
                    default => {'content' => template($source)},
                }
                file { "${hooks_dir}/${hook}":
                    ensure  => stdlib::ensure($ensure, 'file'),
                    owner   => $user,
                    group   => $group,
                    mode    => '0550',
                    require => $git_require,
                    *       => $content,
                }
            }
        }
        if $config.has_key('link') {
            file { $config['link']:
                ensure  => stdlib::ensure($ensure, 'link'),
                target  => $dir,
                force   => true,
                before  => Service['puppetserver'],
                require => $git_require,
            }
        }
        if $config.has_key('config') {
            $content = $config['config'].stdlib::start_with('puppet:///modules/') ? {
                true    => {'source' => $config['config']},
                default => {'content' => template($config['config'])},
            }
            file { "${dir}/.git/config":
                ensure  => stdlib::ensure($ensure, 'file'),
                owner   => $user,
                group   => $group,
                require => $git_require,
                *       => $content,
            }
        }
    }

    exec { 'puppetserver-deploy-code':
        command   => '/usr/local/bin/puppetserver-deploy-code',
        creates   => "${code_dir}/environments/production",
        notify    => Service['puppetserver'],
        require   => [Package['g10k'], File['/usr/local/bin/puppetserver-deploy-code']],
        subscribe => [Git::Clone[$control_repo], Class['puppetserver::g10k']],
    }

    file { '/usr/local/bin/pgit':
        ensure  => file,
        content => "#!/bin/sh\nexec sudo -u ${user} git \"$@\"\n",
        mode    => '0555',
    }

    git::config { "${home_dir}/.gitconfig":
        settings => {
            'user' => {
                'name'  => $user,
                'email' => "${user}@${facts['networking']['fqdn']}",
            },
        },
    }
}
