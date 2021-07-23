# == Class profile::analytics::cluster::users
#
# Installs any special system users needed on all analytics cluster nodes.
# This is used for ensuring that users exist for use in HDFS.
# We want uids and gids to be synchronized everywhere.
# 'service' system users are declared in puppet classes, so only
# those need to be included here.  'user' system users,
# which exist to allow human users to sudo and run jobs as that
# user, are declared in the admin module's data.yaml.
#
# NOTE: Puppet does not manage creation of system user HDFS home directories.
# you will need to do this manually.  To do so, run from any Hadoop node:
#   sudo -u hdfs hdfs dfs -mkdir /user/$user && \
#   sudo -u hdfs hdfs dfs -chown $user:$group /user/$user
# And optionally:
#   sudo -u hdfs hdfs dfs -chmod 775 /user/$user
#
class profile::analytics::cluster::users {
    # When Kerberos is enabled, indexation jobs will run on workers as user 'druid'.
    class { '::druid::bigtop::hadoop::user': }
}
