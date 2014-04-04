# Class: toollabs::hba
#
# This role sets up an instance to allow HBA from bastions
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::hba($store) {

    file { '/usr/local/sbin/project-make-shosts':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/toollabs/project-make-shosts',
    }

    exec { 'make-shosts':
        command => '/usr/local/sbin/project-make-shosts >/etc/ssh/shosts.equiv~',
        require => File['/usr/local/sbin/project-make-shosts', $store],
    }

    file { '/etc/ssh/shosts.equiv':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => '/etc/ssh/shosts.equiv~',
        require => Exec['make-shosts'],
    }

    file { '/usr/local/sbin/project-make-access':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/toollabs/project-make-access',
    }

    exec { 'make-access':
        command => '/usr/local/sbin/project-make-access >/etc/security/access.conf~',
        require => File['/usr/local/sbin/project-make-access', $store],
    }

    File <| title == '/etc/security/access.conf' |> {
        content => undef,
        source  => '/etc/security/access.conf~',
        require => Exec['make-access'],
    }

}
