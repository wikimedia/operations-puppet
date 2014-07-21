class mediawiki::cgroup {
    package { 'cgroup-bin':
        ensure => present,
    }

    file { '/etc/init/mw-cgroup.conf':
        source  => 'puppet:///modules/mediawiki/cgroup/mw-cgroup.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['cgroup-bin'],
    }

    service { 'mw-cgroup':
        ensure   => running,
        provider => 'upstart',
        require  => File['/etc/init/mw-cgroup.conf'],
    }

    file { '/usr/local/bin/cgroup-mediawiki-clean':
        source => 'puppet:///modules/mediawiki/cgroup/cgroup-mediawiki-clean',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
