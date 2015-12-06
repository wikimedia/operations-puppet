# == Class: vagrant::mediawiki
#
# Provision MediaWiki-Vagrant
#
# === Parameters:
# [*install_directory*]
#   Directory where Vagrant stores global state.
#   (default: '/srv/vagrant-data')
#
class vagrant::mediawiki(
    $install_directory = '/srv/mediawiki-vagrant',
) {
    require ::vagrant::lxc

    # Add a local NFS server to export the /srv/mediawiki-vagrant files to the
    # LXC container. NFS is actually slower than native LXC sharing but it
    # allows us to work around permissions problems that would otherwise
    # require adding various user accounts to the host VM and ensuring that
    # their UIDs match with the LXC guest.
    package { 'nfs-kernel-server':
        ensure => present,
    }

    # Add custom apparmor profile that allows NFS mounts
    file { '/etc/apparmor.d/abstractions/lxc/container-base':
        ensure  => 'present',
        source  => 'puppet:///modules/vagrant/lxc/container-base',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['apparmor'],
    }

    git::clone { 'mediawiki/vagrant':
        directory => $install_directory,
        origin    => 'https://gerrit.wikimedia.org/r/mediawiki/vagrant',
        owner     => 'mwvagrant',
        group     => 'wikidev',
        shared    => true,
        require   => User['mwvagrant'],
    }

    exec { 'mediawiki_vagrant_setup':
        command     => "${install_directory}/setup.sh --silent",
        # The first call to vagrant will fail if the plugin isn't installed at
        # all. The second call will exit with an error if the plugin is
        # installed but out of date.
        unless      => '/usr/bin/vagrant plugin list | /bin/grep -q mediawiki-vagrant && /usr/bin/vagrant config --list',
        cwd         => $install_directory,
        user        => 'mwvagrant',
        environment => [
            "VAGRANT_HOME=${::vagrant::vagrant_home}",
        ],
        require     => Git::Clone['mediawiki/vagrant'],
    }

    file { "${install_directory}/.settings.yaml":
        ensure  => 'present',
        source  => 'puppet:///modules/vagrant/default-settings.yaml',
        owner   => 'mwvagrant',
        group   => 'wikidev',
        replace => false,
        before  => Exec['mediawiki_vagrant_setup'],
        require => Git::Clone['mediawiki/vagrant'],
    }

    file { '/usr/local/bin/labs-vagrant':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('vagrant/labs-vagrant.erb'),
    }

    # Set umask for wikidev users so that newly-created files are g+w.
    # This makes shared ownership of $install_directory easier
    file { '/etc/profile.d/umask-wikidev.sh':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/vagrant/umask-wikidev-profile-d.sh',
    }
}
