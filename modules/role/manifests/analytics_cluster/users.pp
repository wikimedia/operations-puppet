# == Class role::analytics_cluster::users
# Installs any special system users needed on analytics namenodes or clients.
# This is used for ensuring that users exist for use in HDFS.
#
# NOTE: Puppet does not manage creation of system user HDFS home directories.
# you will need to do this manually.  To do so, run from any Hadoop node:
#   sudo -u hdfs hdfs dfs -mkdir /user/$user && \
#   sudo -u hdfs hdfs dfs -chown $user:$group /user/$user
# And optionally:
#   sudo -u hdfs hdfs dfs -chmod 775 /user/$user
#
class role::analytics_cluster::users {
    # analytics-search user will be use to deploy
    # wikimedia/discovery/analytics into HDFS.
    # The analytics-search-users group will be allowed to
    # sudo -u analytics-search.
    group { 'analytics-search':
        ensure => present,
    }

    user { 'analytics-search':
        ensure => present,
        gid    => 'analytics-search',
        system => true,
    }
}
