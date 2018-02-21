# == Class role::logging::kafkatee::webrequest::ops
# Includes output filters useful for operational debugging.
#
class profile::kafkatee::webrequest::ops {
    include ::profile::kafkatee::webrequest::base
    include ::geoip

    require_package('socat')

    $log_directory = '/srv/log'
    $webrequest_log_directory = "${log_directory}/webrequest"
    file { [$log_directory, $webrequest_log_directory]:
        ensure  => 'directory',
        owner   => 'kafkatee',
        group   => 'kafkatee',
        require => Package['kafkatee'],
    }

    # if the logs in $log_directory should be rotated
    # then configure a logrotate.d script to do so.
    logrotate::conf { 'kafkatee-webrequest':
        ensure  => 'present',
        content => template('role/logging/kafkatee_logrotate.erb'),
    }

    $logstash_host = hiera('logstash_host')
    $logstash_port = hiera('logstash_json_lines_port')


    # TODO: These webrequest-analytics outputs will be removed when the webrequest-analytics
    # kafkatee instance is removed as part of https://phabricator.wikimedia.org/T185136.
    kafkatee::output { 'sampled-1000':
        instance_name => 'webrequest-analytics',
        destination   => "${webrequest_log_directory}/sampled-1000.json",
        sample        => 1000,
    }

    kafkatee::output { '5xx':
        instance_name => 'webrequest-analytics',
        # Adding --line-buffered here ensures that the output file will only have full lines written to it.
        # Otherwise kafkatee buffers and sends to the pipe whenever it feels like, which causes grep to
        # work on non-full lines.
        destination   => "/bin/grep --line-buffered '\"http_status\":\"5' >> ${webrequest_log_directory}/5xx.json",
        type          => 'pipe',
    }

    # Send 5xx to logstash, append "type: webrequest" for logstash to pick up
    kafkatee::output { 'logstash-5xx':
        instance_name => 'webrequest-analytics',
        destination   => "/bin/grep --line-buffered '\"http_status\":\"5' | jq --compact-output --arg type webrequest '. + {type: \$type}' | socat - TCP:${logstash_host}:${logstash_port}",
        type          => 'pipe',
    }
    ### END webrequest-analytics outputs


    kafkatee::output { 'sampled-1000':
        instance_name => 'webrequest',
        destination   => "${webrequest_log_directory}/sampled-1000.json",
        sample        => 1000,
    }

    kafkatee::output { '5xx':
        instance_name => 'webrequest',
        # Adding --line-buffered here ensures that the output file will only have full lines written to it.
        # Otherwise kafkatee buffers and sends to the pipe whenever it feels like, which causes grep to
        # work on non-full lines.
        destination   => "/bin/grep --line-buffered '\"http_status\":\"5' >> ${webrequest_log_directory}/5xx.json",
        type          => 'pipe',
    }

    # Send 5xx to logstash, append "type: webrequest" for logstash to pick up
    kafkatee::output { 'logstash-5xx':
        instance_name => 'webrequest',
        destination   => "/bin/grep --line-buffered '\"http_status\":\"5' | jq --compact-output --arg type webrequest '. + {type: \$type}' | socat - TCP:${logstash_host}:${logstash_port}",
        type          => 'pipe',
    }
}
