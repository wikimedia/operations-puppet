# analytics servers (RT-1985)

@monitor_group { 'analytics_eqiad': description => 'analytics servers in eqiad' }

# == Class role::analytics
# Base class for all analytics nodes.
# All analytics nodes should include this.
class role::analytics {
    system::role { 'role::analytics': description => 'analytics server' }

    if !defined(Package['openjdk-7-jdk']) {
        package { 'openjdk-7-jdk':
            ensure => 'installed',
        }
    }
}

# == Class role::analytics::clients
# Includes common client classes for
# working with hadoop and other analytics services.
# This class is often included by including
# role::analytics::kraken, but you may include
# it on its own if you don't need any kraken code.
class role::analytics::clients {
    include role::analytics

    # Include Hadoop ecosystem client classes.
    include role::analytics::hadoop::client,
        role::analytics::hive::client,
        role::analytics::oozie::client,
        role::analytics::pig,
        role::analytics::sqoop

    # jq is very useful, install it.
    if !defined(Package['jq']) {
        package { 'jq':
            ensure => 'installed',
        }
    }
}

