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
class puppetmaster::gitclone(
    $secure_private = true,
    $is_git_master = false,
){
    $servers = hiera('puppetmaster::servers', {})

    class  { '::puppetmaster::base_repo':
        gitdir   => $::puppetmaster::gitdir,
        gitowner => 'gitpuppet'
    }

    file {
        "${puppetmaster::gitdir}/operations/puppet/.git/hooks/post-merge":
            require => Git::Clone['operations/puppet'],
            owner   => 'gitpuppet',
            group   => 'gitpuppet',
            content => template('puppetmaster/post-merge.erb'),
            mode    => '0550';
        "${puppetmaster::gitdir}/operations/puppet/.git/hooks/pre-commit":
            require => Git::Clone['operations/puppet'],
            owner   => 'gitpuppet',
            group   => 'gitpuppet',
            source  => 'puppet:///modules/puppetmaster/git/pre-commit',
            mode    => '0550';
        "${puppetmaster::gitdir}/operations/puppet/.git/hooks/pre-merge":
            require => Git::Clone['operations/puppet'],
            owner   => 'gitpuppet',
            group   => 'gitpuppet',
            source  => 'puppet:///modules/puppetmaster/git/pre-merge',
            mode    => '0550';
        "${puppetmaster::gitdir}/operations/puppet/.git/hooks/pre-rebase":
            require => Git::Clone['operations/puppet'],
            owner   => 'gitpuppet',
            group   => 'gitpuppet',
            source  => 'puppet:///modules/puppetmaster/git/pre-rebase',
            mode    => '0550';
        "${puppetmaster::gitdir}/operations/software/.git/hooks/pre-commit":
            require => Git::Clone['operations/software'],
            owner   => 'gitpuppet',
            group   => 'gitpuppet',
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
        '/var/log/puppet-post-merge.log':
            ensure  => file,
            replace => false,
            owner   => 'gitpuppet',
            group   => 'gitpuppet',
            mode    => '0640';
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
                owner   => 'gitpuppet',
                group   => 'gitpuppet',
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
                content => 'puppet:///modules/puppetmaster/git/private/commit-msg-master',
                owner   => 'gitpuppet',
                group   => 'gitpuppet',
                mode    => '0550',
                require => Exec['/srv/private init'],
            }

            # Syncing hooks
            # This hook updates /var/lib and pushes changes to the backend workers
            file { '/srv/private/.git/hooks/post-commit':
                ensure  => present,
                content => template('puppetmaster/git-master-postcommit.erb'),
                owner   => 'gitpuppet',
                group   => 'gitpuppet',
                mode    => '0550',
                require => Exec['/srv/private init'],
            }

            # Post receive script in case the push is from another master
            # This will reset to head, and transmit data to /var/lib
            file { '/srv/private/.git/hooks/post-receive':
                source  => 'puppet:///modules/puppetmaster/git/private/post-receive-master',
                owner   => 'gitpuppet',
                group   => 'gitpuppet',
                mode    => '0550',
                require => File['/srv/private']
            }
            file { '/srv/private/.git/config':
                source  => 'puppet:///modules/puppetmaster/git/private/gitconfig-master',
                owner   => 'gitpuppet',
                group   => 'gitpuppet',
                mode    => '0550',
                require => File['/srv/private']
            }
        } else {
            puppetmaster::gitprivate { '/srv/private':
                bare     => true,
                dir_mode => '0700',
                owner    => 'gitpuppet',
                group    => 'gitpuppet',
            }

            # This will transmit data to /var/lib...
            file { '/srv/private/hooks/post-receive':
                source  => 'puppet:///modules/puppetmaster/git/private/post-receive',
                owner   => 'gitpuppet',
                group   => 'gitpuppet',
                mode    => '0550',
                require => Puppetmaster::Gitprivate['/srv/private']
            }
        }

        # What is in the private repo must also be in operations/private in
        # /var/lib/git...

        $private_dir = "${puppetmaster::gitdir}/operations/private"

        puppetmaster::gitprivate { $private_dir:
            origin   => '/srv/private',
            owner    => 'gitpuppet',
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
            target => "${puppetmaster::gitdir}/operations/labs/private",
            force  => true,
        }
    }

    git::clone {
        'operations/software':
            require   => File["${puppetmaster::gitdir}/operations"],
            owner     => 'gitpuppet',
            directory => "${puppetmaster::gitdir}/operations/software",
            origin    => 'https://gerrit.wikimedia.org/r/p/operations/software';
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
}
