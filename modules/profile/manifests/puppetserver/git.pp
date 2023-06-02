# SPDX-License-Identifier: Apache-2.0
class profile::puppetserver::git (
    Wmflib::Ensure     $ensure       = lookup('profile::puppetserver::git::ensure'),
    Stdlib::Unixpath   $basedir      = lookup('profile::puppetserver::git::basedir'),
    String[1]          $user         = lookup('profile::puppetserver::git::user'),
    String[1]          $group        = lookup('profile::puppetserver::git::group'),
    String[1]          $control_repo = lookup('profile::puppetserver::git::control_repo'),
    Hash[String, Hash] $repos        = lookup('profile::puppetserver::git::repos'),
) {
    unless $repos.has_key($control_repo) {
        fail("\$control_repo (${control_repo}) must be defined in \$repos")
    }
    $control_repo_dir = "${basedir}/${control_repo}"
    file { $basedir:
        ensure => stdlib::ensure($ensure, 'directory'),
        owner  => $user,
        group  => $group,
    }
    $repos.each |$repo, $config| {
        $dir = "${basedir}/${repo}"
        ensure_resource('file', $dir.dirname, {
            ensure => stdlib::ensure($ensure, 'directory'),
            owner  => $user,
            group  => $group,
        })
        git::clone { $repo:
            ensure    => $ensure,
            directory => $dir,
            branch    => $config['branch'],
            origin    => "https://gerrit.wikimedia.org/r/${repo}",
            owner     => $user,
            group     => $group,
            require   => File[$dir.dirname],
            before    => Service['puppetserver'],
        }
        if $config.has_key('hooks') {
            $hooks_dir = "${dir}/.git/hooks"
            $config['hooks'].each |$hook, $source| {
                file { "${hooks_dir}/${hook}":
                    ensure  => stdlib::ensure($ensure, 'file'),
                    owner   => $user,
                    group   => $group,
                    mode    => '0550',
                    source  => $source,
                    require => Git::Clone[$repo],
                }
            }
        }
        if $config.has_key('link') {
            file { $config['link']:
                ensure => stdlib::ensure($ensure, 'link'),
                target => $dir,
                force  => true,
                before => Service['puppetserver'],
            }
        }
    }
}
