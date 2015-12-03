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
class toollabs::hba {

    file { '/usr/local/sbin/project-make-shosts':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/toollabs/project-make-shosts',
    }

    exec { 'make-shosts':
        command => '/usr/local/sbin/project-make-shosts >/etc/ssh/shosts.equiv~',
        require => File['/usr/local/sbin/project-make-shosts'],
        onlyif  => "/usr/bin/test -n \"\$(/usr/bin/find /data/project/.system/store -maxdepth 1 \\( -type d -or -type f -name submithost-\\* \\) -newer /etc/ssh/shosts.equiv~)\" -o ! -s /etc/ssh/shosts.equiv~",
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
        command => '/usr/local/sbin/project-make-access >/etc/project.access',
        require => File['/usr/local/sbin/project-make-access'],
        onlyif  => "/usr/bin/test -n \"\$(/usr/bin/find /data/project/.system/store -maxdepth 1 \\( -type d -or -type f -name submithost-\\* \\) -newer /etc/project.access)\" -o ! -s /etc/project.access",
    }

    security::access { 'toollabs-hba':
        source  => '/etc/project.access',
    }

}
