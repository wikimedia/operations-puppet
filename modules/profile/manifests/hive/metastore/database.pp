# == Class profile::hive::metastore::database
#
# Includes the role::analytics_cluster::database::meta class
# to install a database for analytics cluster meta data,
# includes the cdh::hive::metastore::mysql
# to ensure that the hive_metastore database is created,
# and then finally ensures grants and permissions are
# set so that configured hosts can properly connect to this database.
#
class profile::hive::metastore::database(
    $jdbc_database = hiera('profile::hive::metastore::database::jdbc_database', 'hive_metastore'),
    $jdbc_username = hiera('profile::hive::metastore::database::jdbc_username', 'hive'),
    $jdbc_password = hiera('profile::hive::metastore::database::jdbc_password', 'hive'),
) {
    # Install a database server (MariaDB)
    require ::profile::analytics::database::meta

    # Need to have hive package installed to
    # get /usr/lib/hive/bin/schematool.
    # require ::profile::hive::client

    # Ensure that the hive_metastore db is created.
    # TODO: In CDH 5.4,
    # /usr/lib/hive/bin/schematool -dbType mysql -initSchema
    # doesn't seem to be working with MariaDB properly.
    # For now, run:
    #   cd /usr/lib/hive/scripts/metastore/upgrade/mysql && sudo mysql hive_metastore < hive-schema-1.1.0.mysql.sql
    # after cdh::hive::metastore::mysql makes puppet fail.

    class { '::cdh::hive::metastore::mysql':
        db_root_username => undef,
        db_root_password => undef,
        jdbc_database    => $jdbc_database,
        jdbc_username    => $jdbc_username,
        jdbc_password    => $jdbc_password,
        require          => Class['profile::analytics::database::meta'],
    }

    # cdh::hive::metastore::mysql only ensures that
    # the Hive MySQL user has permissions to connect
    # via localhost.  If you plan on running
    # the hive-metastore daemon on a different node
    # than where you run this MySQL database, then you need
    # to make sure that node has proper permissions to
    # access MySQL via the hive user and pw.
    # You could use the cdh::hive::metastore::mysql::grant define to do this.
}
