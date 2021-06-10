# Class: puppetmaster::gitclone
#
# This class handles the repositories from which the puppetmasters pull
#
# === Parameters
# [*secure_private*]
# If false, /etc/puppet/private will be labs/private.git.
# Otherwise, some magic is done to have local repositories and sync between puppetmasters.
#
# [*is_git_master*]
# If True, the git private repository here will be considered a master.
#
# [*prevent_cherrypicks*]
# If true, setup git hooks to prevent manual modification of the git repos.
#
# [*user*]
# The user which should own the git repositories
#
# [*group*]
# The group which should own the git repositories
class puppetmaster::gitclone(
    Boolean   $secure_private      = true,
    Boolean   $is_git_master       = false,
    Boolean   $prevent_cherrypicks = true,
    String[1] $user                = 'gitpuppet',
    String[1] $group               = 'gitpuppet',
    Hash[String, Puppetmaster::Backends] $servers = {},
){

    include puppetmaster
    $is_master = $servers.has_key($facts['fqdn'])

    class  { 'puppetmaster::base_repo':
        gitdir   => $puppetmaster::gitdir,
        gitowner => $user,
    }

    $cherrypick_hook_ensure = $prevent_cherrypicks ? {
        true    => file,
        default => absent,
    }

    file {"${puppetmaster::gitdir}/operations/puppet/.git/hooks/post-merge":
        ensure  => absent,
    }
    file {
        default:
            ensure  => $cherrypick_hook_ensure,
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
    file {[$puppetmaster::volatiledir, "${puppetmaster::volatiledir}/misc"]:
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
                ensure  => present,
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
                ensure  => present,
                owner   => $user,
                group   => $group,
                mode    => '0550',
                source  => 'puppet:///modules/puppetmaster/private-repo-pre-commit.sh',
                require => Exec['/srv/private init'],
            }

            file { "${private_repo_dir}/.git/hooks/commit-msg":
                ensure  => present,
                source  => 'puppet:///modules/puppetmaster/git/private/commit-msg-master',
                owner   => $user,
                group   => $group,
                mode    => '0550',
                require => Exec['/srv/private init'],
            }

            # Syncing hooks
            # This hook updates /var/lib and pushes changes to the backend workers
            file { "${private_repo_dir}/.git/hooks/post-commit":
                ensure  => present,
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
                source  => 'puppet:///modules/puppetmaster/git/private/gitconfig-master',
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

    # These symlinks will allow us to use /etc/puppet for the puppetmaster to
    # run out of.
    file { '/etc/puppet/templates':
        ensure => link,
        target => "${puppetmaster::gitdir}/operations/puppet/templates",
        force  => true,
    }
    file { '/etc/puppet/files':
        ensure => link,
        target => "${puppetmaster::gitdir}/operations/puppet/files",
        force  => true,
    }
    file { '/etc/puppet/manifests':
        ensure => link,
        target => "${puppetmaster::gitdir}/operations/puppet/manifests",
        force  => true,
    }
    file { '/etc/puppet/modules':
        ensure => link,
        target => "${puppetmaster::gitdir}/operations/puppet/modules",
        force  => true,
    }
    file { '/etc/puppet/hieradata':
        ensure => link,
        target => "${puppetmaster::gitdir}/operations/puppet/hieradata",
        force  => true,
    }
    file { '/etc/puppet/environments':
        ensure => link,
        target => "${puppetmaster::gitdir}/operations/puppet/environments",
        force  => true,
    }
}
