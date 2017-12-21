# == Class role::logging::kafkatee::webrequest::ops
# Includes output filters useful for operational debugging.
#
class role::logging::kafkatee::webrequest::ops {

    include ::standard
    include ::profile::base::firewall
    include ::geoip  # lint:ignore:wmf_styleguide

    include role::logging::kafkatee::webrequest::base

    require_package('socat')

    $webrequest_log_directory = $::role::logging::kafkatee::webrequest::base::webrequest_log_directory
    $logstash_host = hiera('logstash_host')
    $logstash_port = hiera('logstash_json_lines_port')

    kafkatee::output { 'sampled-1000':
        destination => "${webrequest_log_directory}/sampled-1000.json",
        sample      => 1000,
    }

    kafkatee::output { '5xx':
        # Adding --line-buffered here ensures that the output file will only have full lines written to it.
        # Otherwise kafkatee buffers and sends to the pipe whenever it feels like, which causes grep to
        # work on non-full lines.
        destination => "/bin/grep --line-buffered '\"http_status\":\"5' >> ${webrequest_log_directory}/5xx.json",
        type        => 'pipe',
    }

    # Send 5xx to logstash, append "type: webrequest" for logstash to pick up
    kafkatee::output { 'logstash-5xx':
        destination => "/bin/grep --line-buffered '\"http_status\":\"5' | jq --compact-output --arg type webrequest '. + {type: \$type}' | socat - TCP:${logstash_host}:${logstash_port}",
        type        => 'pipe',
    }
}
