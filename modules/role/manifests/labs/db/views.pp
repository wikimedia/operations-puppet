class role::labs::db::views {

    package {
        ['python3-yaml', 'python3-pymysql']:
            ensure => present,
            before => File['/usr/local/sbin/maintain-views'],
    }

    git::clone { 'operations/mediawiki-config':
        ensure             => 'latest',
        directory          => '/usr/local/lib/mediawiki-config',
        recurse_submodules => true,
        before             => File['/usr/local/sbin/maintain-views'],
    }

    include passwords::labsdb::maintainviews
    $view_user = $::passwords::labsdb::maintainviews::user
    $view_pass = $::passwords::labsdb::maintainviews::db_pass
    file { '/etc/maintain-views.yaml':
        ensure  => file,
        content => template('role/labs/db/views/maintain-views.yaml'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/usr/local/sbin/maintain-views':
        ensure => file,
        source => 'puppet:///modules/role/labs/db/views/maintain-views.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
    }

    file { '/usr/local/sbin/maintain-meta_p':
        ensure => file,
        source => 'puppet:///modules/role/labs/db/views/maintain-meta_p.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
    }

    file { '/usr/local/src/heartbeat-views.sql':
        ensure => file,
        source => 'puppet:///modules/role/labs/db/views/heartbeat-views.sql',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
