# == Class: vagrant
#
# Provision Vagrant
#
# === Parameters:
# [*vagrant_home*]
#   Directory where Vagrant stores global state.
#   (default: '/srv/vagrant-data')
#
class vagrant(
    $vagrant_home = '/srv/vagrant-data',
) {
    requires_os('ubuntu >= trusty')

    # Installing vagrant plugins often requires compiling ruby gems
    # FIXME: this should probably come from somewhere else
    package { 'build-essential':
        ensure => present,
    }

    # FIXME: vagrant-lxc needs vagrant 1.7+; 14.04 ships 1.4.3
    # This ugly hack installs the deb downloaded from the main vagrant
    # distribution site. It would be nicer to import this to our local apt
    # repo.
    exec { 'download_vagrant_deb':
        command => '/usr/bin/wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2_x86_64.deb',
        cwd     => '/tmp',
        creates => '/tmp/vagrant_1.7.2_x86_64.deb',
    }
    exec { 'install_vagrant_deb':
        command => '/usr/bin/dpkg -i /tmp/vagrant_1.7.2_x86_64.deb',
        unless  => '/usr/bin/dpkg-query -l vagrant',
        require => Exec['download_vagrant_deb'],
    }

    file { $vagrant_home:
        ensure => 'directory',
        owner  => 'vagrant',
        group  => 'vagrant',
    }

    sudo::group { 'wikidev_vagrant':
        privileges => [
            'ALL=(vagrant) NOPASSWD: ALL',
        ],
        group => 'wikidev',
    }

    # Wrapper script to make it easier to invoke vagrant in a shared
    # environment.
    file { '/usr/local/bin/mwvagrant':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('vagrant/mwvagrant.erb'),
    }
}
