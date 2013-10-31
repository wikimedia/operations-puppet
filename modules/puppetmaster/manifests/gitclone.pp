# Class: puppetmaster::gitclone
#
# This class handles the repositories from which the puppetmasters pull
class puppetmaster::gitclone {
    file {
        $puppetmaster::gitdir:
            ensure  => directory,
            owner   => 'root',
            group   => 'root';
        "${puppetmaster::gitdir}/operations":
            ensure  => directory,
            owner   => 'root',
            group   => 'root';
        "${puppetmaster::gitdir}/operations/puppet":
            ensure  => directory,
            owner   => 'gitpuppet',
            group   => 'root',
            require => File["${puppetmaster::gitdir}/operations"];
        "${puppetmaster::gitdir}/operations/software":
            ensure  => directory,
            owner   => 'gitpuppet',
            group   => 'root',
            require => File["${puppetmaster::gitdir}/operations"];
        "${puppetmaster::gitdir}/operations/puppet/.git/hooks/post-merge":
            require => Git::Clone['operations/puppet'],
            owner   => 'gitpuppet',
            content => template('puppetmaster/post-merge.erb'),
            mode    => '0550';
        "${puppetmaster::gitdir}/operations/puppet/.git/hooks/pre-commit":
            require => Git::Clone['operations/puppet'],
            owner   => 'gitpuppet',
            source  => 'puppet:///modules/puppetmaster/git/pre-commit',
            mode    => '0550';
        "${puppetmaster::gitdir}/operations/puppet/.git/hooks/pre-merge":
            require => Git::Clone['operations/puppet'],
            owner   => 'gitpuppet',
            source  => 'puppet:///modules/puppetmaster/git/pre-merge',
            mode    => '0550';
        "${puppetmaster::gitdir}/operations/puppet/.git/hooks/pre-rebase":
            require => Git::Clone['operations/puppet'],
            owner   => 'gitpuppet',
            source  => 'puppet:///modules/puppetmaster/git/pre-rebase',
            mode    => '0550';
        "${puppetmaster::gitdir}/operations/software/.git/hooks/pre-commit":
            require => Git::Clone['operations/software'],
            source  => 'puppet:///modules/puppetmaster/git/pre-commit',
            mode    => '0550';
        $puppetmaster::volatiledir:
            ensure  => directory,
            mode    => '0750',
            owner   => 'root',
            group   => 'puppet';
        "$puppetmaster::volatiledir/misc":
            ensure  => directory,
            mode    => '0750',
            owner   => 'root',
            group   => 'puppet';
    }

    if ! $::is_labs_puppet_master {
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
                mode    => '0750';
            "${puppetmaster::gitdir}/operations/private/.git/hooks/post-merge":
                source  => 'puppet:///modules/puppetmaster/git/private/post-merge',
                owner   => 'gitpuppet',
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
        'operations/puppet':
            require     => File["${puppetmaster::gitdir}/operations/puppet"],
            directory   => "${puppetmaster::gitdir}/operations/puppet",
            owner       => 'gitpuppet',
            branch      => 'production',
            origin      => 'https://gerrit.wikimedia.org/r/p/operations/puppet';
        'operations/software':
            require     => File["${puppetmaster::gitdir}/operations/software"],
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
}
