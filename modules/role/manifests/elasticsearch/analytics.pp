# Supports CirrusSearch usage on the analytics cluster
class role::elasticsearch::analytics {
    # wikimedia/discovery/analytics will be deployed to this node
    package { 'wikimedia/discovery/analytics':
        provider => 'trebuchet',
    }

    # analytics-search user will be use to deploy wikimedia/discovery/analytics
    # into HDFS
    group { 'analytics-search':
        ensure => present,
    }

    user { 'analytics-search':
        ensure => present,
        gid    => 'analytics-search',
        system => true
    }
}
