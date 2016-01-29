# == Class role::analytics::oozie::server::database
# Includes the role::analytics::database::meta class
# to install a database for analytics cluster meta data,
# includes the cdh::oozie::database::mysql
# to ensure that the hive_metastore database is created,
# and then finally ensures grants and permissions are
# set so that configured hosts can properly connect to this database.
#
class role::analytics_new::oozie::server::database {
    # Install a database server (MariaDB)
    include role::analytics_new::database::meta

    # Ensure that the oozie db is created.
    class { 'cdh::oozie::database::mysql':
        require => Class['role::analytics_new::database::meta'],
    }

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
