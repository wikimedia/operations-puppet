# == Class profile::java::analytics
#
# Installs Java packages chosen by the Analytics
# team and used among various projects like Hadoop,
# Druid, etc. Consistency is essential to allow
# interoperability among various clusters.
#
class profile::java::analytics {

    if os_version('debian == buster') {

        apt::repository { 'openjdk-8':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => 'buster-wikimedia',
            components => 'component/jdk8',
            notify     => Exec['apt_update_java8'],
        }

        exec {'apt_update_java8':
            command     => '/usr/bin/apt-get update',
            refreshonly => true,
        }

        package { 'openjdk-8-jdk':
            ensure  => present,
            require => [
                Apt::Repository['openjdk-8'],
                Exec['apt_update_java8'],
            ],
        }

        alternatives::select { 'java':
            path    => '/usr/lib/jvm/java-8-openjdk-amd64/bin/java',
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
