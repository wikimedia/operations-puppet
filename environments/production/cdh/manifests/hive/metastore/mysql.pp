# == Class cdh::hive::metastore::mysql
# Configures and sets up a MySQL metastore for Hive.
#
# Note that this class does not set up grants that allow other hosts
# to connect to this MySQL instance.  If you need remote hosts
# able to use the hive user to connect to this MySQL instances,
# use the cdh::hive:metastore::mysql::grant define.
# This class only grants permissions for localhost MySQL users.
#
# See: http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hive_metastore_configure.html
#
# == Parameters
# $db_root_username    - username for metastore database creation commands. Default: undef
# $db_root_password    - password for metastore database creation commands.
# $jdbc_database       - database name. Default: 'hive_metastore'
# $jdbc_username       - username to access the Hive database. Default: 'hive'
# $jdbc_password       - password to access the Hive database. Default: 'hive'
#
class cdh::hive::metastore::mysql(
    $db_root_username = undef,
    $db_root_password = undef,
    $jdbc_database    = 'hive_metastore',
    $jdbc_username    = 'hive',
    $jdbc_password    = hive,
) {
    # Need to hive package in order to have
    # /usr/lib/hive/bin/schematool installed.
    if !defined(Package['hive']) {
        package { 'hive':
            ensure => 'installed',
        }
    }

    # Install the libmysql-java .jar into Hive's classpath so that
    # hive schematool can run.
    include cdh::hive::metastore::mysql::jar

    # Only use -u or -p flag to mysql commands if
    # root username or root password are set.
    $username_option = $db_root_username ? {
        undef   => '',
        default => "-u'${db_root_username}'",
    }
    $password_option = $db_root_password? {
        undef   => '',
        default => "-p'${db_root_password}'",
    }

    $exec_path = '/usr/lib/hive/bin:/usr/local/bin:/usr/bin:/bin'
    # Hive metastore MySQL database need a hive database and user.
    exec { 'hive_mysql_create_database':
        path    => $exec_path,
        command => "mysql ${username_option} ${password_option} -e 'CREATE DATABASE ${jdbc_database}; USE ${jdbc_database};'",
        unless  => "mysql ${username_option} ${password_option} -e 'SHOW DATABASES' | grep -q ${jdbc_database}",
        user    => 'root',
    }
    exec { 'hive_mysql_create_user':
        path    => $exec_path,
        command => "mysql ${username_option} ${password_option} -e \"
CREATE USER '${jdbc_username}'@'localhost' IDENTIFIED BY '${jdbc_password}';
GRANT ALL PRIVILEGES ON ${jdbc_database}.* TO '${jdbc_username}'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON ${jdbc_database}.* TO '${jdbc_username}'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;\"",
        unless  => "mysql ${username_option} ${password_option} -e \"SHOW GRANTS FOR '${jdbc_username}'@'127.0.0.1'\" | grep -q \"TO '${jdbc_username}'\"",
        user    => 'root',
    }

    # Run hive schematool to initialize the Hive metastore schema.
    exec { 'hive_schematool_initialize_schema':
        path    => $exec_path,
        command => 'schematool -dbType mysql -initSchema',
        unless  => "mysql ${username_option} ${password_option} -D ${jdbc_database} -e \"SHOW TABLES;\" | grep -q 'VERSION'",
        user    => 'root',
        require => [
            Class['cdh::hive::metastore::mysql::jar'],
            Exec['hive_mysql_create_user'],
            Exec['hive_mysql_create_database'],
            Package['hive'],
        ],
    }
}