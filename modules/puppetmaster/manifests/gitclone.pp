# Class: puppetmaster::gitclone
#
# This class handles the repositories from which the puppetmasters pull
class puppetmaster::gitclone {

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
            ensure  => directory,
            owner   => 'root',
            group   => 'puppet',
            mode    => '0750';
        "${puppetmaster::volatiledir}/misc":
            ensure  => directory,
            owner   => 'root',
            group   => 'puppet',
            mode    => '0750';
    }

    if ! $is_labs_puppet_master {
        # Set up private repo.
        # Note that puppet does not actually clone the repo -- puppetizing that
        # turns out to be a big, insecure mess.  On a new puppetmaster you will
        # will need to do a clone of
        #       ${puppetmaster::gitdir}/operations/puppet/private
        # by hand and with a forwarded key.
        file {
            "${puppetmaster::gitdir}/operations/private":
                ensure  => directory,
                owner   => 'gitpuppet',
                group   => 'puppet',
                mode    => '0750';
            "${puppetmaster::gitdir}/operations/private/.git/hooks/post-merge":
                source  => 'puppet:///modules/puppetmaster/git/private/post-merge',
                owner   => 'gitpuppet',
                group   => 'gitpuppet',
                mode    => '0550';
            "${puppetmaster::gitdir}/operations/private/.git/hooks/pre-commit":
                source  => 'puppet:///modules/puppetmaster/git/private/pre-commit',
                owner   => 'gitpuppet',
                group   => 'gitpuppet',
                mode    => '0550';
            "${puppetmaster::gitdir}/operations/private/.git/hooks/pre-merge":
                source  => 'puppet:///modules/puppetmaster/git/private/pre-merge',
                owner   => 'gitpuppet',
                group   => 'gitpuppet',
                mode    => '0550';
            "${puppetmaster::gitdir}/operations/private/.git/hooks/pre-rebase":
                source  => 'puppet:///modules/puppetmaster/git/private/pre-rebase',
                owner   => 'gitpuppet',
                group   => 'gitpuppet',
                mode    => '0550';
            '/etc/puppet/private':
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
            require     => File["${puppetmaster::gitdir}/operations"],
            owner       => 'gitpuppet',
            directory   => "${puppetmaster::gitdir}/operations/software",
            origin      => 'https://gerrit.wikimedia.org/r/p/operations/software';
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
