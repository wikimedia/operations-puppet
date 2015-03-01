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
    require ::vagrant

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
        require => [ Package['lxc'], Package['lxc-templates'] ],
        notify  => Service['apparmor'],
    }

    git::clone { 'mediawiki/vagrant':
        directory => $install_directory,
        origin    => 'https://gerrit.wikimedia.org/r/mediawiki/vagrant',
        owner     => 'vagrant',
        group     => 'wikidev',
        shared    => true,
    }

    exec { 'mediawiki_vagrant_setup':
        command     => "${install_directory}/setup.sh",
        unless      => '/usr/bin/vagrant plugin list | /bin/grep -q mediawiki-vagrant',
        cwd         => $install_directory,
        user        => 'vagrant',
        environment => [
            "VAGRANT_HOME=${::vagrant::vagrant_home}",
        ],
        require     => Git::Clone['mediawiki/vagrant'],
    }
}
