# == Class role::analytics_cluster::java
# Installs the version of Java used for Analytics Cluster.
class role::analytics_cluster::java {
    require_package('openjdk-7-jdk')

    # This packages conflicts with the hadoop-fuse-dfs
    # and with impalad in that two libjvm.so files get added
    # to LD_LIBRARY_PATH.  We dont't need this
    # package anyway, so ensure it is absent.
    package { 'icedtea-7-jre-jamvm':
        ensure => 'absent'
    }
}
