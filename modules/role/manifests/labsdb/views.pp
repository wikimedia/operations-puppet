class role::labsdb::views {

    git::clone { 'operations/mediawiki-config':
        ensure             => 'latest',
        directory          => '/usr/local/lib',
        owner              => 'root',
        group              => 'root',
        before             => File['/usr/local/sbin/maintain-views'],
        recurse_submodules => true,
    }

    $view_user = $passwords::mysql::maintain-views::user
    $view_pass = $passwords::mysql::maintain-views::password
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
