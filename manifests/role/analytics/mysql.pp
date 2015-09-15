# == Class role::analytics::mysql::meta
# Installs a MySQL/MariaDB server for use with Hive and Oozie
#
class role::analytics::mysql::meta {
    include mariadb::packages
    # This will be included once analytics1015 has been productionized
    # - otto 2015-09-15
    # include role::mariadb::monitor

    class { 'mariadb::config':
        config    => 'mariadb/analytics-meta.my.cnf.erb',
        datadir   => '/var/lib/mysql',
    }
}
