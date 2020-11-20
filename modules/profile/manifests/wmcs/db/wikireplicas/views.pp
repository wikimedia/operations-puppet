# deploy scripts and its dependencies to create replica views
class profile::wmcs::db::wikireplicas::views (
    String $view_user = lookup('profile::wmcs::db::wikireplicas::views::maintainviews::user'),
    String $view_pass = lookup('profile::wmcs::db::wikireplicas::views::maintainviews::db_pass'),
    String $idx_user  = lookup('profile::wmcs::db::wikireplicas::maintainindexes::user'),
    String $idx_pass  = lookup('profile::wmcs::db::wikireplicas::maintainindexes::db_pass'),
    Optional[Hash[String, Stdlib::Datasize]] $instances = lookup('profile::wmcs::db::wikireplicas::mariadb_multiinstance::instances', { 'default_value' => undef }),
){
    require ::profile::wmcs::db::scriptconfig

    package { [
        'python-pymysql',
        'python-requests',
        'python-simplejson',
        'python3-psutil'
    ]:
        ensure => present,
    }

    file { '/etc/maintain-views.yaml':
        ensure  => file,
        content => template('profile/wmcs/db/wikireplicas/maintain-views.yaml'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
    }

    file { '/usr/local/sbin/maintain-views':
        ensure  => file,
        source  => 'puppet:///modules/profile/wmcs/db/wikireplicas/views/maintain-views.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => [Package['python3-yaml', 'python3-pymysql'],
                    Git::Clone['operations/mediawiki-config'],
        ],
    }

    file { '/etc/index-conf.yaml':
        ensure  => file,
        content => template('profile/wmcs/db/wikireplicas/index-conf.yaml'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
    }

    file { '/usr/local/sbin/maintain-replica-indexes':
        ensure  => file,
        source  => 'puppet:///modules/profile/wmcs/db/wikireplicas/maintain_replica_indexes.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => [Package['python3-yaml', 'python3-pymysql', 'python3-psutil'],
                    Git::Clone['operations/mediawiki-config'],
        ],
    }

    file { '/usr/local/sbin/maintain-meta_p':
        ensure  => file,
        source  => 'puppet:///modules/profile/wmcs/db/wikireplicas/maintain-meta_p.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => [Package['python-simplejson', 'python-pymysql']],
    }

    file { '/usr/local/src/heartbeat-views.sql':
        ensure => file,
        source => 'puppet:///modules/profile/wmcs/db/wikireplicas/views/heartbeat-views.sql',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
