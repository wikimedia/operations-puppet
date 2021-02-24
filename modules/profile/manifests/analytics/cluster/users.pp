# == Class profile::analytics::cluster::users
#
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
class profile::analytics::cluster::users {
    # analytics-search user will be used to deploy
    # wikimedia/discovery/analytics into HDFS.
    # The analytics-search-users group will be allowed to
    # sudo -u analytics-search.
    if debian::codename::ge('buster') {
        $analytics_search_uid = 911
        $analytics_search_gid = 911
    } else {
        $analytics_search_uid = undef
        $analytics_search_gid = undef
    }
    group { 'analytics-search':
        gid => $analytics_search_gid,
    }
    user { 'analytics-search':
        ensure => present,
        uid    => $analytics_search_uid,
        gid    => $analytics_search_gid,
        system => true,
    }

    # The analytics user will be used to run any Analytics
    # job running on Yarn/HDFS (as replacement for 'hdfs').
    # T220971
    # The analytics user needs to be able to change group ownership of
    # directories that it owns to analytics:druid. The Hive workflows/actions
    # that we use for Druid leverage a separate scratch dir to work on the data,
    # that is moved and chowned as last step to its final location on HDFS.
    # If the analytics user is not in the druid group it will not be able (via Hive etc..)
    # to chgrp the final directory (and its files) to a group like 'druid'.
    if debian::codename::ge('buster') {
        $analytics_uid = 906
        $analytics_gid = 906
    } else {
        $analytics_uid = undef
        $analytics_gid = undef
    }
    group { 'analytics':
        gid => $analytics_gid,
    }
    user { 'analytics':
        ensure  => present,
        uid     => $analytics_uid,
        gid     => $analytics_gid,
        system  => true,
        groups  => 'druid',
        require => Class['::druid::bigtop::hadoop::user'],
    }

    # The analytics-privatedata user will be used to run
    # cronjobs and similar by users.
    # T238306
    if debian::codename::ge('buster') {
        $analytics_privatedata_uid = 909
        $analytics_privatedata_gid = 909
    } else {
        $analytics_privatedata_uid = undef
        $analytics_privatedata_gid = undef
    }
    group { 'analytics-privatedata':
        gid => $analytics_privatedata_gid,
    }
    user { 'analytics-privatedata':
        ensure => present,
        uid    => $analytics_privatedata_uid,
        gid    => $analytics_privatedata_gid,
        system => true,
    }
    # The analytics-product user will be used to run
    # cronjobs and similar by Product Analytics.
    # T255039
    if debian::codename::ge('buster') {
        $analytics_product_uid = 910
        $analytics_product_gid = 910
    } else {
        $analytics_product_uid = undef
        $analytics_product_gid = undef
    }
    group { 'analytics-product':
        gid => $analytics_product_gid,
    }
    user { 'analytics-product':
        ensure => present,
        uid    => $analytics_product_uid,
        gid    => $analytics_product_gid,
        system => true,
    }
    # When Kerberos is enabled, indexation jobs will run on workers
    # as user 'druid'.
    class { '::druid::bigtop::hadoop::user': }
}
