class role::labsdb::views {

    file { '/etc/maintain-views.json':
        ensure  => file,
        content => template('role/labsdb/maintain-views.json'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/usr/local/sbin/maintain-views':
        ensure => file,
        source => 'puppet:///modules/role/labsdb/maintain-views.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
    }

    file { '/usr/local/sbin/maintain-meta_p':
        ensure => file,
        source => 'puppet:///modules/role/labsdb/maintain-meta_p.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
    }

    file { '/usr/local/src/heartbeat-views.sql':
        ensure => file,
        source => 'puppet:///modules/role/labsdb/heartbeat-views.sql',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
