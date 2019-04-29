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
    $secure_private = true,
    $is_git_master = false,
    $prevent_cherrypicks = true,
    $user = 'gitpuppet',
    $group = 'gitpuppet',
){
    $servers = hiera('puppetmaster::servers', {})

    class  { '::puppetmaster::base_repo':
        gitdir   => $::puppetmaster::gitdir,
        gitowner => $user,
    }

    if $prevent_cherrypicks {
        $cherrypick_hook_ensure = present
    } else {
        $cherrypick_hook_ensure = absent
    }

    file {
        "${puppetmaster::gitdir}/operations/puppet/.git/hooks/post-merge":
            ensure  => absent;
        "${puppetmaster::gitdir}/operations/puppet/.git/hooks/pre-commit":
            ensure  => $cherrypick_hook_ensure,
            require => Git::Clone['operations/puppet'],
            owner   => $user,
            group   => $group,
            source  => 'puppet:///modules/puppetmaster/git/pre-commit',
            mode    => '0550';
        "${puppetmaster::gitdir}/operations/puppet/.git/hooks/pre-merge":
            ensure  => $cherrypick_hook_ensure,
            require => Git::Clone['operations/puppet'],
            owner   => $user,
            group   => $group,
            source  => 'puppet:///modules/puppetmaster/git/pre-merge',
            mode    => '0550';
        "${puppetmaster::gitdir}/operations/puppet/.git/hooks/pre-rebase":
            ensure  => $cherrypick_hook_ensure,
            require => Git::Clone['operations/puppet'],
            owner   => $user,
            group   => $group,
            source  => 'puppet:///modules/puppetmaster/git/pre-rebase',
            mode    => '0550';
        "${puppetmaster::gitdir}/operations/software/.git/hooks/pre-commit":
            ensure  => $cherrypick_hook_ensure,
            require => Git::Clone['operations/software'],
            owner   => $user,
            group   => $group,
            source  => 'puppet:///modules/puppetmaster/git/pre-commit',
            mode    => '0550';
        $puppetmaster::volatiledir:
            ensure => directory,
            owner  => 'root',
            group  => 'puppet',
            mode   => '0750';
        "${puppetmaster::volatiledir}/misc":
            ensure => directory,
            owner  => 'root',
            group  => 'puppet',
            mode   => '0750';
    }

    if $secure_private {
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
            file { '/srv/private':
                ensure  => directory,
                owner   => $user,
                group   => $group,
                mode    => '0640', # Will become 0755 for dir automatically
                recurse => true,
            }

            # On a private master, /srv/private is a real repository
            exec { '/srv/private init':
                command => '/usr/bin/git init',
                user    => 'root',
                group   => 'root',
                cwd     => '/srv/private',
                creates => '/srv/private/.git',
                require => File['/srv/private'],
            }
            # Ssh wrapper to use the gitpuppet private key
            file { '/srv/private/.git/ssh_wrapper.sh':
                ensure  => present,
                source  => 'puppet:///modules/puppetmaster/git/private/ssh_wrapper.sh',
                owner   => 'root',
                group   => 'root',
                mode    => '0555',
                require => Exec['/srv/private init'],
            }

            # Audit hook, add username of commiter in message
            file { '/srv/private/.git/hooks/commit-msg':
                ensure  => present,
                source  => 'puppet:///modules/puppetmaster/git/private/commit-msg-master',
                owner   => $user,
                group   => $group,
                mode    => '0550',
                require => Exec['/srv/private init'],
            }

            # Syncing hooks
            # This hook updates /var/lib and pushes changes to the backend workers
            file { '/srv/private/.git/hooks/post-commit':
                ensure  => present,
                content => template('puppetmaster/git-master-postcommit.erb'),
                owner   => $user,
                group   => $group,
                mode    => '0550',
                require => Exec['/srv/private init'],
            }

            # Post receive script in case the push is from another master
            # This will reset to head, and transmit data to /var/lib
            file { '/srv/private/.git/hooks/post-receive':
                source  => 'puppet:///modules/puppetmaster/git/private/post-receive-master',
                owner   => $user,
                group   => $group,
                mode    => '0550',
                require => File['/srv/private'],
            }
            file { '/srv/private/.git/config':
                source  => 'puppet:///modules/puppetmaster/git/private/gitconfig-master',
                owner   => $user,
                group   => $group,
                mode    => '0550',
                require => File['/srv/private'],
            }
        } else {
            puppetmaster::gitprivate { '/srv/private':
                bare     => true,
                dir_mode => '0700',
                owner    => $user,
                group    => $group,
            }

            # This will transmit data to /var/lib...
            file { '/srv/private/hooks/post-receive':
                source  => 'puppet:///modules/puppetmaster/git/private/post-receive',
                owner   => $user,
                group   => $group,
                mode    => '0550',
                require => Puppetmaster::Gitprivate['/srv/private'],
            }
        }

        # What is in the private repo must also be in operations/private in
        # /var/lib/git...

        $private_dir = "${puppetmaster::gitdir}/operations/private"

        puppetmaster::gitprivate { $private_dir:
            origin   => '/srv/private',
            owner    => $user,
            group    => 'puppet',
            dir_mode => '0750',
        }

        if $is_git_master {
            Exec['/srv/private init'] -> Puppetmaster::Gitprivate[$private_dir]
        } else {
            Puppetmaster::Gitprivate['/srv/private'] -> Puppetmaster::Gitprivate[$private_dir]
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
    #  so we need a check-out.
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

    git::clone {
        'operations/software':
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
