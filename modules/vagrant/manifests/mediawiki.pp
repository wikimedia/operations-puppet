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
        command     => "${install_directory}/setup.sh --silent",
        # The first call to vagrant will fail if the plugin isn't installed at
        # all. The second call will exit with an error if the plugin is
        # installed but out of date.
        unless      => '/usr/bin/vagrant plugin list | /bin/grep -q mediawiki-vagrant && /usr/bin/vagrant config --list',
        cwd         => $install_directory,
        user        => 'vagrant',
        environment => [
            "VAGRANT_HOME=${::vagrant::vagrant_home}",
        ],
        require     => Git::Clone['mediawiki/vagrant'],
    }

    file { "${install_directory}/puppet/hieradata/local.yaml":
        ensure  => 'present',
        source  => 'puppet:///modules/vagrant/hieradata/local.yaml',
        owner   => 'vagrant',
        group   => 'wikidev',
        mode    => '0664',
        replace => false,
        require => Git::Clone['mediawiki/vagrant'],
    }
}
