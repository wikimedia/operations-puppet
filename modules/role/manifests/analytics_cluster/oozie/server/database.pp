# == Class role::analytics_cluster::oozie::server::database
# Includes the role::analytics_cluster::database::meta class
# to install a database for analytics cluster meta data,
# includes the cdh::oozie::database::mysql
# to ensure that the hive_metastore database is created,
# and then finally ensures grants and permissions are
# set so that configured hosts can properly connect to this database.
#
class role::analytics_cluster::oozie::server::database {
    # Install a database server (MariaDB)
    require ::role::analytics_cluster::database::meta

    # Ensure that the oozie db is created.
    class { '::cdh::oozie::database::mysql':
        require => Class['role::analytics_cluster::database::meta'],
    }

    # NOTE: on 2016-02-23, Otto and Joal
    # added an INDEX on the oozie.WF_JOBS created_time field:
    #  ALTER TABLE oozie.WF_JOBS ADD INDEX (created_time);
    # The WF_JOBS table was 38G, and oozie was getting stuck
    # on long running queries sorting by created_time.

    # cdh::oozie::database::mysql only ensures that
    # the Oozie MySQL user has permissions to connect
    # via localhost.  If you plan on running
    # the oozie server daemon on a different node
    # than where you run this MySQL database, then you need
    # to make sure that node has proper permissions to
    # access MySQL via the hive user and pw.

    # If labs, just allow access from all hosts
    if $::realm == 'labs' {
        cdh::oozie::database::mysql::grant { '%': }
    }
}
