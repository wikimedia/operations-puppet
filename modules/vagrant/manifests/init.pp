# == Class: vagrant
#
# Provision Vagrant
#
# === Parameters:
# [*vagrant_home*]
#   Directory where Vagrant stores global state.
#   (default: '/srv/vagrant-data')
#
# [*sudo_flavor*]
#   Which sudo flavor to use, 'sudo' or 'sudo-ldap'.
#   Default: sudo-ldap
#
class vagrant(
    String $sudo_flavor  = 'sudo-ldap',
    $vagrant_home = '/srv/vagrant-data',
) {
    package { 'vagrant':
        ensure => present,
    }

    user { 'mwvagrant':
        ensure => present,
        gid    => 'wikidev',
        home   => $vagrant_home,
    }

    file { $vagrant_home:
        ensure => 'directory',
        owner  => 'mwvagrant',
        group  => 'wikidev',
        mode   => '0755',
    }

    # Set umask and VAGRANT_HOME for mwvagrant user
    file { "${vagrant_home}/.profile":
        ensure  => present,
        content => template('vagrant/mwvagrant-profile.erb'),
        owner   => 'mwvagrant',
        group   => 'wikidev',
        mode    => '0744',
    }

    sudo::group { 'wikidev_mwvagrant':
        privileges  => [
            'ALL=(mwvagrant) NOPASSWD: ALL',
        ],
        group       => 'wikidev',
        sudo_flavor => $sudo_flavor,
    }

    # Wrapper script to make it easier to invoke vagrant in a shared
    # environment.
    file { '/usr/local/bin/mwvagrant':
        ensure  => 'present',
        content => template('vagrant/mwvagrant.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

    # set umask for wikidev users so that newly-created files are g+w
    file { '/etc/profile.d/alias-vagrant.sh':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/vagrant/alias-vagrant-profile-d.sh',
    }
}
