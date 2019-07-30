# == Class cdh::sqoop
# Installs Sqoop 1
#
#
# NOTE: There is no sqoop-conf alternative defined,
# because there is not yet any sqoop specific
# configuartion handled by this puppet module.
#
class cdh::sqoop {
    # Sqoop requires Hadoop configs installed.
    Class['cdh::hadoop'] -> Class['cdh::sqoop']

    package { 'sqoop':
        ensure => 'installed',
    }

    # symlink the Mysql/Mariadb JDBC connector into /usr/lib/sqoop/lib
    # TODO: Can I create this symlink as mysql.jar?
    cdh::mysql_jdbc { 'sqoop-mysql-connector':
        link_path => '/usr/lib/sqoop/lib/mysql-connector-java.jar',
        require   => Package['sqoop'],
    }
}