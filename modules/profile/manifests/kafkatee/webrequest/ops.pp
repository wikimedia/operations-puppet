# == Class role::logging::kafkatee::webrequest::ops
# Includes output filters useful for operational debugging.
#
class profile::kafkatee::webrequest::ops (
    $logstash_host = hiera('logstash_host'),
    $logstash_port = hiera('logstash_json_lines_port'),
) {
    include ::profile::kafkatee::webrequest::base
    include ::geoip

    require_package('socat')

    $log_directory = '/srv/log'
    $webrequest_log_directory = "${log_directory}/webrequest"
    $webrequest_log_archive_directory = "${log_directory}/webrequest/archive"
    file { [$log_directory, $webrequest_log_directory, $webrequest_log_archive_directory]:
        ensure  => 'directory',
        owner   => 'kafkatee',
        group   => 'kafkatee',
        require => Package['kafkatee'],
    }

    # Rotate kafkatee output logs in $webrequest_log_directory.
    logrotate::conf { 'kafkatee-ops':
        content => template('profile/kafkatee/kafkatee_ops_logrotate.erb'),
    }

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

    # Send 5xx to syslog, append "type: webrequest" and "@cee: " for syslog structured logging
    # These logs will be injected into the logging pipeline and thus to logstash
    kafkatee::output { 'logstash-5xx':
        instance_name => 'webrequest',
        destination   => "/bin/grep --line-buffered '\"http_status\":\"5' | jq --compact-output --arg type webrequest '. + {type: \$type}' | sed 's/^/@cee: /' | logger -t webrequest",
        type          => 'pipe',
    }
}
