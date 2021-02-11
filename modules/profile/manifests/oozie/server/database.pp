# == Class profile::oozie::server::database
#
# Includes the role::analytics_cluster::database::meta class
# to install a database for analytics cluster meta data,
# includes the bigtop::oozie::database::mysql
# to ensure that the hive_metastore database is created,
# and then finally ensures grants and permissions are
# set so that configured hosts can properly connect to this database.
#
class profile::oozie::server::database(
    String $jdbc_database = lookup('profile::oozie::server::database::jdbc_database', {'default_value' => 'oozie'}),
    String $jdbc_username = lookup('profile::oozie::server::database::jdbc_username', {'default_value' => 'oozie'}),
    String $jdbc_password = lookup('profile::oozie::server::database::jdbc_password', {'default_value' => 'oozie'}),
) {
    # Install a database server (MariaDB)
    require ::profile::analytics::database::meta

    # Ensure that the oozie db is created.
    class { '::bigtop::oozie::database::mysql':
        db_root_username => undef,
        db_root_password => undef,
        jdbc_database    => $jdbc_database,
        jdbc_username    => $jdbc_username,
        jdbc_password    => $jdbc_password,
        require          => Class['profile::analytics::database::meta'],
    }

    # NOTE: on 2016-02-23, Otto and Joal
    # added an INDEX on the oozie.WF_JOBS created_time field:
    #  ALTER TABLE oozie.WF_JOBS ADD INDEX (created_time);
    # The WF_JOBS table was 38G, and oozie was getting stuck
    # on long running queries sorting by created_time.

    # bigtop::oozie::database::mysql only ensures that
    # the Oozie MySQL user has permissions to connect
    # via localhost.  If you plan on running
    # the oozie server daemon on a different node
    # than where you run this MySQL database, then you need
    # to make sure that node has proper permissions to
    # access MySQL via the hive user and pw.

    # If labs, just allow access from all hosts
    if $::realm == 'labs' {
        bigtop::oozie::database::mysql::grant { '%': }
    }
}
