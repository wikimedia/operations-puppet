# @summary This class handles the repositories from which the puppetmasters pull
#
# @param secure_private If false, /etc/puppet/private will be labs/private.git.
#         Otherwise, some magic is done to have local repositories and sync between puppetmasters.
# @param is_git_master If True, the git private repository here will be considered a master.
# @param prevent_cherrypicks If true, setup git hooks to prevent manual modification of the git repos.
# @param use_r10k If true, use r10k
# @param enable_netbox If true, enable netbox repos
# @param user The user which should own the git repositories
# @param group The group which should own the git repositories
# @param netbox_hiera_enable add the netbox-hiera repo
# @param netbox_hiera_source The git source of the nebox hiera repo
# @param netbox_hiera_path The repo path pf the nebox hiera repo
# @param servers list of puppetmaster backend servers
# @param r10k_sources r10k_sources configuration
class puppetmaster::gitclone(
    Boolean                                  $secure_private      = true,
    Boolean                                  $is_git_master       = false,
    Boolean                                  $prevent_cherrypicks = true,
    Boolean                                  $use_r10k            = false,
    Boolean                                  $netbox_hiera_enable = false,
    Stdlib::HTTPUrl                          $netbox_hiera_source = 'https://netbox-exports.wikimedia.org/netbox-hiera',
    Stdlib::Unixpath                         $netbox_hiera_path   = '/srv/netbox-hiera',
    String[1]                                $user                = 'gitpuppet',
    String[1]                                $group               = 'gitpuppet',
    Hash[String, Puppetmaster::Backends]     $servers             = {},
    Hash[String, Puppetmaster::R10k::Source] $r10k_sources        = {}
){

    include puppetmaster
    $is_master = $servers.has_key($facts['networking']['fqdn'])

    class  { 'puppetmaster::base_repo':
        gitdir   => $puppetmaster::gitdir,
        gitowner => $user,
    }

    file {"${puppetmaster::gitdir}/operations/puppet/.git/hooks/post-merge":
        ensure  => absent,
    }
    file {
        default:
            ensure  => stdlib::ensure($prevent_cherrypicks, 'file'),
            owner   => $user,
            group   => $group,
            mode    => '0550',
            require => Git::Clone['operations/puppet'];
        "${puppetmaster::gitdir}/operations/puppet/.git/hooks/pre-commit":
            source  => 'puppet:///modules/puppetmaster/git/pre-commit';
        "${puppetmaster::gitdir}/operations/puppet/.git/hooks/pre-merge":
            source  => 'puppet:///modules/puppetmaster/git/pre-merge';
        "${puppetmaster::gitdir}/operations/puppet/.git/hooks/pre-rebase":
            source  => 'puppet:///modules/puppetmaster/git/pre-rebase';
        "${puppetmaster::gitdir}/operations/software/.git/hooks/pre-commit":
            source  => 'puppet:///modules/puppetmaster/git/pre-commit',
            require => Git::Clone['operations/software'];
    }
    file {$puppetmaster::volatiledir:
        ensure => directory,
        owner  => 'root',
        group  => 'puppet',
        mode   => '0750';
    }

    if $secure_private {
        $private_repo_dir = '/srv/private'
        # Set up private repo.
        # Note that puppet does not actually clone the repo -- puppetizing that
        # turns out to be a big, insecure mess.
        #
        # However, it is enough to push from the private repo master
        # in order to create the repo.

        # on any master for private data,
        # /srv/private contains the actual repository.
        # On the non-masters, it is a bare git repo used only to receive
        # the push from upstream

        if $is_git_master {
            file { $private_repo_dir:
                ensure  => directory,
                owner   => $user,
                group   => $group,
                mode    => '0640', # Will become 0755 for dir automatically
                recurse => true,
            }

            # On a private master, /srv/private is a real repository
            exec { "${private_repo_dir} init":
                command => '/usr/bin/git init',
                user    => 'root',
                group   => 'root',
                cwd     => $private_repo_dir,
                creates => "${private_repo_dir}/.git",
                require => File[$private_repo_dir],
            }
            # Ssh wrapper to use the gitpuppet private key
            file { "${private_repo_dir}/.git/ssh_wrapper.sh":
                ensure  => file,
                source  => 'puppet:///modules/puppetmaster/git/private/ssh_wrapper.sh',
                owner   => 'root',
                group   => 'root',
                mode    => '0555',
                require => Exec['/srv/private init'],
            }

            # add config and pre-commit hook to perform yamllint on the hieradata dir
            ensure_packages(['yamllint'])
            $yamllint_conf_file = '/etc/puppet/yamllint.yaml'
            file {'/etc/puppet/yamllint.yaml':
                ensure => file,
                source => 'puppet:///modules/puppetmaster/git/yamllint.yaml',
            }
            file { "${private_repo_dir}/.git/hooks/pre-commit":
                ensure  => file,
                owner   => $user,
                group   => $group,
                mode    => '0550',
                source  => 'puppet:///modules/puppetmaster/private-repo-pre-commit.sh',
                require => Exec['/srv/private init'],
            }

            file { "${private_repo_dir}/.git/hooks/commit-msg":
                ensure  => 'absent', #T368023
                source  => 'puppet:///modules/puppetmaster/git/private/commit-msg-master',
                owner   => $user,
                group   => $group,
                mode    => '0550',
                require => Exec['/srv/private init'],
            }

            # Syncing hooks
            # This hook updates /var/lib and pushes changes to the backend workers
            $puppet_servers = wmflib::role::hosts('puppetserver')
            file { "${private_repo_dir}/.git/hooks/post-commit":
                ensure  => 'absent', #T368023
                content => template('puppetmaster/git-master-postcommit.erb'),
                owner   => $user,
                group   => $group,
                mode    => '0550',
                require => Exec['/srv/private init'],
            }

            # Post receive script in case the push is from another master
            # This will reset to head, and transmit data to /var/lib
            file { "${private_repo_dir}/.git/hooks/post-receive":
                source  => 'puppet:///modules/puppetmaster/git/private/post-receive-master',
                owner   => $user,
                group   => $group,
                mode    => '0550',
                require => File['/srv/private'],
            }
            file { "${private_repo_dir}/.git/config":
                source  => 'puppet:///modules/puppetmaster/git/private/config',
                owner   => $user,
                group   => $group,
                mode    => '0550',
                require => File['/srv/private'],
            }
        } else {
            puppetmaster::gitprivate { $private_repo_dir:
                bare     => true,
                dir_mode => '0700',
                owner    => $user,
                group    => $group,
            }

            # This will transmit data to /var/lib...
            file { "${private_repo_dir}/hooks/post-receive":
                source  => 'puppet:///modules/puppetmaster/git/private/post-receive',
                owner   => $user,
                group   => $group,
                mode    => '0550',
                require => Puppetmaster::Gitprivate[$private_repo_dir],
            }
        }

        # What is in the private repo must also be in operations/private in
        # /var/lib/git...

        $private_dir = "${puppetmaster::gitdir}/operations/private"

        puppetmaster::gitprivate { $private_dir:
            origin   => $private_repo_dir,
            owner    => $user,
            group    => 'puppet',
            dir_mode => '0750',
        }

        if $is_git_master {
            Exec["${private_repo_dir} init"] -> Puppetmaster::Gitprivate[$private_dir]
        } else {
            Puppetmaster::Gitprivate[$private_repo_dir] -> Puppetmaster::Gitprivate[$private_dir]
        }

        # ...and linked to /etc/puppet
        file { '/etc/puppet/private':
                ensure => link,
                target => "${puppetmaster::gitdir}/operations/private",
                force  => true;
        }
    } else {
        file { '/etc/puppet/private':
            ensure => link,
            target => "${puppetmaster::gitdir}/labs/private",
            force  => true,
        }
    }

    # The labs/private repo isn't used by production
    #  puppet, but it is maintained by puppet-merge
    #  so we need a check-out on the frontends.
    if $is_master or $::realm == 'labs' {
        file { '/var/lib/git/labs':
            ensure => directory,
            owner  => $user,
            group  => $group,
            mode   => '0755',
        }
        git::clone { 'labs/private':
            require   => File["${puppetmaster::gitdir}/labs"],
            owner     => $user,
            group     => $group,
            directory => "${puppetmaster::gitdir}/labs/private",
        }
    } else {
        file { '/var/lib/git/labs':
            ensure => absent,
            force  => true,
        }
    }

    git::clone {'operations/software':
        require   => File["${puppetmaster::gitdir}/operations"],
        owner     => $user,
        group     => $group,
        directory => "${puppetmaster::gitdir}/operations/software",
        origin    => 'https://gerrit.wikimedia.org/r/operations/software';
    }

    $link_sub_dirs = [ 'templates', 'files', 'manifests', 'modules', 'vendor_modules', 'hieradata', 'environments']
    if $use_r10k {
        $link_sub_dirs.each |$sub_dir| {
            file { "/etc/puppet/${sub_dir}":
                ensure => absent,
            }
        }
        class { 'puppetmaster::r10k':
            sources => $r10k_sources,
        }
    } else {
        # These symlinks will allow us to use /etc/puppet for the puppetmaster to
        # run out of.
        $link_sub_dirs.each |$sub_dir| {
            file { "/etc/puppet/${sub_dir}":
                ensure => link,
                target => "${puppetmaster::gitdir}/operations/puppet/${sub_dir}",
                force  => true,
            }
        }
    }
    if $netbox_hiera_enable {
        git::clone {'netbox-hiera':
            owner     => $user,
            group     => $group,
            directory => $netbox_hiera_path,
            origin    => $netbox_hiera_source,
        }
        # TODO: we should template the hiera yaml file to avoid this
        file { '/etc/puppet/netbox':
            ensure => link,
            target => $netbox_hiera_path,
        }
    }
}
