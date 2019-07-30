# == Class cdh::hive::metastore::mysql::jar
# Installs libmysql-java and symlinks the .jar artifact
# into /usr/lib/hive/lib.
#
# This is a standalone class so that it is possible to safely
# include it from multiple classes (e.g. cdh::hive::metastore::mysql
# and cdh::hive::metastore).
#
class cdh::hive::metastore::mysql::jar {
    Package['hive'] -> Class['cdh::hive::metastore::mysql::jar']

    cdh::mysql_jdbc { 'hive-mysql-jar':
        link_path     => '/usr/lib/hive/lib/libmysql-java.jar',
        use_mysql_jar => true,
    }
}
