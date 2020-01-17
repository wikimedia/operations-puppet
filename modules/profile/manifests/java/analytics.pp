# == Class profile::java::analytics
#
# Installs Java packages chosen by the Analytics
# team and used among various projects like Hadoop,
# Druid, etc. Consistency is essential to allow
# interoperability among various clusters.
#
class profile::java::analytics {

    if os_version('debian == buster') {

        apt::package_from_component { 'openjdk-8':
            component => 'component/jdk8',
            packages  => ['openjdk-8-jdk'],
        }

        alternatives::select { 'java':
            path    => '/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java',
            require => Package['openjdk-8-jdk']
        }
    } else {
        package { 'openjdk-8-jdk':
            ensure  => present,
        }
    }

    # Make sure file.encoding is UTF-8 for all java processes.
    # This should help avoid bugs like T128295.
    file_line { 'java_tool_options_file_encoding_utf_8':
        line => 'JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"',
        path => '/etc/environment',
    }
}
