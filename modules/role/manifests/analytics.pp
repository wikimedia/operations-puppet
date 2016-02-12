# analytics servers (RT-1985)
# == Class role::analytics
# Base class for all analytics nodes.
# All analytics nodes should include this.
class role::analytics {
    system::role { 'role::analytics': description => 'analytics server' }

    require_package('openjdk-7-jdk')

    # This packages conflicts with the hadoop-fuse-dfs
    # and with impalad in that two libjvm.so files get added
    # to LD_LIBRARY_PATH.  We dont't need this
    # package anyway, so ensure it is absent.
    package { 'icedtea-7-jre-jamvm':
        ensure => 'absent'
    }
}
