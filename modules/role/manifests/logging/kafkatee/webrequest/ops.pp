# == Class role::logging::kafkatee::webrequest::ops
# Includes output filters useful for operational debugging.
#
class role::logging::kafkatee::webrequest::ops {

    include role::logging::kafkatee::webrequest::base

    $webrequest_log_directory = $::role::logging::kafkatee::webrequest::base::webrequest_log_directory

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
}
