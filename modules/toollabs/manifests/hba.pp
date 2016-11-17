# Establish the ability to do Host Based Auth from bastions to execs/webgrid

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
        onlyif  => "/usr/bin/test -n \"\$(/usr/bin/find /data/project/.system/store -maxdepth 1 \\( -type d -or -type f -name submithost-\\* \\) -newer /etc/ssh/shosts.equiv~)\" -o ! -s /etc/ssh/shosts.equiv~",
        require => File['/usr/local/sbin/project-make-shosts'],
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
        onlyif  => "/usr/bin/test -n \"\$(/usr/bin/find /data/project/.system/store -maxdepth 1 \\( -type d -or -type f -name submithost-\\* \\) -newer /etc/project.access)\" -o ! -s /etc/project.access",
        require => File['/usr/local/sbin/project-make-access'],
    }

    security::access::config { 'toollabs-hba':
        source  => '/etc/project.access',
        require => Exec['make-access'],
    }
}
