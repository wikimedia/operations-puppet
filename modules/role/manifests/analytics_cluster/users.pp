# == Class role::analytics_cluster::users
# Installs any special system users needed on analytics namenodes or clients.
# This is used for ensuring that users exist for use in HDFS.
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
        system => true
    }

    # analytics-wmde will be used to run hive
    # queries using scripts contained in the
    # analytics/wmde/scripts repository
    # The analytics-wmde-users group will be allowed to
    # sudo -u analytics-wmde.
    include statistics::wmde::user
}
