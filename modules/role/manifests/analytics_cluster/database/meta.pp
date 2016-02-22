# == Class role::analytics_cluster::database::meta
# Installs a MySQL/MariaDB server for use with Hive and Oozie
#
class role::analytics_cluster::database::meta {
    # Some CDH database init scripts need Java to run.
    require role::analytics_cluster::java

    class { 'mariadb::packages_wmf':
        mariadb10 => true
    }
    # TODO: This will be included once analytics1015 has been productionized
    # - otto 2015-09-15
    #include role::mariadb::monitor

    class { 'mariadb::config':
        config    => 'mariadb/analytics-meta.my.cnf.erb',
        datadir   => '/var/lib/mysql',
        require   => Class['mariadb::packages_wmf'],
    }

    file { '/etc/init.d/mysql':
        ensure  => link,
        target  => '/opt/wmf-mariadb10/service',
        require => Class['mariadb::packages_wmf'],
    }

    # Make /usr/local/bin/mysql and /usr/bin/mysql a pointer to
    # mariadb10 mysql client.  /usr/bin/mysql allows
    # cdh::hive::metastore::mysql execs to run.
    file { ['/usr/local/bin/mysql', '/usr/bin/mysql']:
        ensure  => link,
        target  => '/opt/wmf-mariadb10/bin/mysql',
        require => Class['mariadb::packages_wmf'],
    }

    # if labs, automate mysql_install_db.
    if $::realm == 'labs' {
        exec { 'analytics_meta_mysql_install_db':
            command => '/opt/wmf-mariadb10/scripts/mysql_install_db',
            cwd     => '/opt/wmf-mariadb10',
            creates => '/var/lib/mysql/ibdata1',
            require => Class['mariadb::config'],
            before  => Service['mysql'],
        }
    }

    service { 'mysql':
        ensure     => 'running',
        enable     => true,
        hasrestart => true,
        hasstatus  => true,
        require    => [File['/etc/init.d/mysql'], Class['mariadb::config']],
    }

    # Allow access to this analytics mysql instance from analytics networks
    ferm::service{ 'analytics-mysql-meta':
        proto  => 'tcp',
        port   => '3306',
        srange => '$ANALYTICS_NETWORKS',
    }
}
