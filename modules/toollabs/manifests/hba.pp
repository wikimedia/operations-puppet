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
    # Execution hosts have funky access requirements; they need to be
    # ssh-able by service accounts, and they need to use host-based
    # authentication.

    # We override /etc/ssh/shosts.equiv and /etc/security/access.conf
    # accordingly from information collected from the project store.

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
        onlyif  => "/usr/bin/test -n \"\$(/usr/bin/find ${store} -maxdepth 1 \\( -type d -or -type f -name submithost-\\* \\) -newer /etc/ssh/shosts.equiv~)\"",
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
        onlyif  => "/usr/bin/test -n \"\$(/usr/bin/find ${store} -maxdepth 1 \\( -type d -or -type f -name submithost-\\* \\) -newer /etc/security/access.conf~)\"",
    }

    File <| title == '/etc/security/access.conf' |> {
        content => undef,
        source  => '/etc/security/access.conf~',
        require => Exec['make-access'],
    }
}
