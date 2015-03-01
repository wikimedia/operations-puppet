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

    package { 'vagrant':
        ensure => present,
    }

    # Installing vagrant plugins often requires compiling ruby gems
    # FIXME: this should probably come from somewhere else
    package { 'build-essential':
        ensure => present,
    }

    file { $vagrant_home:
        ensure => 'directory',
        owner  => 'vagrant',
        group  => 'vagrant',
        mode   => '0755',
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
