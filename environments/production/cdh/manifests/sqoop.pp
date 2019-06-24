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

    if (!defined(Package['libmysql-java'])) {
        package { 'libmysql-java':
            ensure => 'installed',
        }
    }
    # symlink the mysql-connector-java.jar that is installed by
    # libmysql-java into /usr/lib/sqoop/lib
    # TODO: Can I create this symlink as mysql.jar?
    file { '/usr/lib/sqoop/lib/mysql-connector-java.jar':
        ensure  => 'link',
        target  => '/usr/share/java/mysql-connector-java.jar',
        require => [Package['sqoop'], Package['libmysql-java']],
    }
}