# SPDX-License-Identifier: Apache-2.0
# == Class bigtop::hive::metastore::mysql::jar
# Installs libmysql-java and symlinks the .jar artifact
# into /usr/lib/hive/lib.
#
# This is a standalone class so that it is possible to safely
# include it from multiple classes (e.g. bigtop::hive::metastore::mysql
# and bigtop::hive::metastore).
#
class bigtop::hive::metastore::mysql::jar {
    Package['hive'] -> Class['bigtop::hive::metastore::mysql::jar']

    bigtop::mysql_jdbc { 'hive-mysql-jar':
        link_path     => '/usr/lib/hive/lib/libmysql-java.jar',
        use_mysql_jar => true,
    }
}
