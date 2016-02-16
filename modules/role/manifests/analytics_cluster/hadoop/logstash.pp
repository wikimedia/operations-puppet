# == Class role::analytics_cluster::hadoop::logstash
# Enables gelf logging to logstash from Hadoop.
# As of 2016-02, this  is not used.
class role::analytics_cluster::hadoop::logstash {
    Class['cdh::hadoop'] -> Class['role::analytics_cluster::hadoop::logstash']

    file { '/usr/local/bin/hadoop-yarn-logging-helper.sh':
        content => template('role/analytics_cluster/hadoop/hadoop-yarn-logging-helper.erb'),
        mode    => '0744',
    }

    $patched_jar_exists_command = '/bin/ls /usr/lib/hadoop-yarn | /bin/grep -E  "hadoop-yarn-server-nodemanager.+gelf"'

    if $cdh::hadoop::gelf_logging_enabled {
        ensure_packages([
            # library dependency
            'libjson-simple-java',
            # the libary itself: logstash-gelf.jar
            'liblogstash-gelf-java',
        ])
        # symlink into hadoop classpath
        file { '/usr/lib/hadoop/lib/json_simple.jar':
            ensure  => 'link',
            target  => '/usr/share/java/json_simple.jar',
            require => Package['libjson-simple-java'],
        }

        # symlink into hadoop classpath
        file { '/usr/lib/hadoop/lib/logstash-gelf.jar':
            ensure  => 'link',
            target  => '/usr/share/java/logstash-gelf.jar',
            require => Package['liblogstash-gelf-java'],
        }

        # Patch container-log4j.properties inside nodemanager jar
        # See script source for details
        exec { 'hadoop-yarn-logging-helper-set':
            command   => '/usr/local/bin/hadoop-yarn-logging-helper.sh set',
            subscribe => File['/usr/local/bin/hadoop-yarn-logging-helper.sh'],
            unless    => $patched_jar_exists_command,
        }
    }
    else {
        # Revert to original unmodified jar
        exec { 'hadoop-yarn-logging-helper-reset':
            command   => '/usr/local/bin/hadoop-yarn-logging-helper.sh reset',
            subscribe => File['/usr/local/bin/hadoop-yarn-logging-helper.sh'],
            onlyif    => $patched_jar_exists_command,
        }
    }
}
