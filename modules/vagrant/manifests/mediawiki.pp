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
    include ::deployment::umask_wikidev

    # Add a local NFS server to export the /srv/mediawiki-vagrant files to the
    # LXC container. NFS is actually slower than native LXC sharing but it
    # allows us to work around permissions problems that would otherwise
    # require adding various user accounts to the host VM and ensuring that
    # their UIDs match with the LXC guest.
    file { '/etc/exports':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/vagrant/etc-exports',
        # Do not replace an existing file. Vagrant will add exports, but we
        # seem to need to have something exported to get the NFS server to
        # start on Jessie hosts.
        replace => false,
    }

    package { 'nfs-kernel-server':
        ensure  => 'present',
        require => File['/etc/exports'],
    }

    service { 'nfs-kernel-server':
        ensure  => 'running',
        require => Package['nfs-kernel-server'],
    }

    # Add custom apparmor profile that allows NFS mounts
    file { '/etc/apparmor.d/abstractions/lxc/container-base':
        ensure => 'present',
        source => 'puppet:///modules/vagrant/lxc/container-base',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    if defined(Service['apparmor']) {
        File['/etc/apparmor.d/abstractions/lxc/container-base'] ~> Service['apparmor']
    }

    git::clone { 'mediawiki/vagrant':
        directory => $install_directory,
        origin    => 'https://gerrit.wikimedia.org/r/mediawiki/vagrant',
        owner     => 'mwvagrant',
        group     => 'wikidev',
        shared    => true,
        require   => User['mwvagrant'],
    }

    file { "${install_directory}/.settings.yaml":
        ensure  => 'present',
        source  => 'puppet:///modules/vagrant/default-settings.yaml',
        owner   => 'mwvagrant',
        group   => 'wikidev',
        replace => false,
        require => Git::Clone['mediawiki/vagrant'],
    }

    file { '/usr/local/bin/labs-vagrant':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('vagrant/labs-vagrant.erb'),
    }

    # T127129: Attempt to start an existing MediaWiki-Vagrant LXC container on
    # instance boot.
    file { '/usr/local/bin/start-mwvagrant.sh':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('vagrant/start-mwvagrant.sh.erb'),
    }

    systemd::service { 'mediawiki-vagrant':
        ensure  => present,
        content => systemd_template('mediawiki-vagrant'),
        restart => false,
        require => File['/usr/local/bin/start-mwvagrant.sh'],
    }
}
