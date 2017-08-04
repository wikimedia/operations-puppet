# == Class java::analytics
#
# Installs Java packages chosen by the Analytics
# team and used among various projects like Hadoop,
# Druid, etc. Consistency is essential to allow
# interoperability among various clusters.
#
class java::analytics {
    if os_version('debian >= stretch') {
        require_package('openjdk-8-jdk')
    }
    else {
        require_package('openjdk-7-jdk')
        # This packages conflicts with the hadoop-fuse-dfs
        # and with impalad in that two libjvm.so files get added
        # to LD_LIBRARY_PATH.  We dont't need this
        # package anyway, so ensure it is absent.
        package { 'icedtea-7-jre-jamvm':
            ensure => 'absent',
        }
    }

    # Make sure file.encoding is UTF-8 for all java processes.
    # This should help avoid bugs like T128295.
    file_line { 'java_tool_options_file_encoding_utf_8':
        line => 'JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"',
        path => '/etc/environment',
    }
}