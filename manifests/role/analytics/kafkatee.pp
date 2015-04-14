# == Class role::analytics::kafkatee
# Base role class for installing kafkatee.
# Your kafkatee outputs should store output
# $log_directory (/srv/log).
#
class role::analytics::kafkatee {
    require role::analytics::kafka::config

    # Install kafkatee configured to consume from
    # the Kafka cluster.  The default
    # $output_format for this class will work for us,
    # so we do not set it manually here.
    class { '::kafkatee':
        kafka_brokers           => $role::analytics::kafka::config::brokers_array,
        log_statistics_interval => 15,
    }
    include kafkatee::monitoring

    # Declare packaged rsyslog config to ensure it isn't purged.
    file { '/etc/rsyslog.d/75-kafkatee.conf':
        ensure  => file,
        require => Class['::kafkatee'],
    }

    $log_directory            = '/srv/log'
    file { $log_directory:
        ensure      => 'directory',
        owner       => 'kafkatee',
        group       => 'kafkatee',
        require     => Class['::kafkatee'],
    }

}


# == Class role::analytics::kafkatee::webrequest
# Base role class for webrequest data logging via
# kafkatee.  This class installs kafkatee and
# sets up webrequest log and archive directories
# and logrotate rules.
#
class role::analytics::kafkatee::webrequest inherits role::analytics::kafkatee {
    $webrequest_log_directory     = "${log_directory}/webrequest"
    $webrequest_archive_directory = "${$webrequest_log_directory}/archive"
    file { [$webrequest_log_directory, $webrequest_archive_directory]:
        ensure      => 'directory',
        owner       => 'kafkatee',
        group       => 'kafkatee',
        require     => Class['::kafkatee'],
    }

    # if the logs in $log_directory should be rotated
    # then configure a logrotate.d script to do so.
    file { '/etc/logrotate.d/kafkatee-webrequest':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('kafkatee/logrotate.erb'),
    }

    $hosts_allow = ['stat1002.eqiad.wmnet']
    include rsync::server
    rsync::server::module { 'webrequest':
        comment     => 'kafkatee generated webrequest log files',
        path        => $webrequest_log_directory,
        read_only   => 'yes',
        hosts_allow => $hosts_allow,
    }
}


# == Class role::analytics::kafkatee::input::webrequest::mobile
# Sets up kafkatee to consume from webrequest_mobile topic and
# output desired files sampling and filtering this topic.
#
class role::analytics::kafkatee::webrequest::mobile inherits role::analytics::kafkatee::webrequest {
    include role::analytics::kafkatee::input::webrequest::mobile

    # Include this to infer mobile varnish frontend hostnames on which to filter.
    include role::cache::configuration
    $cache_configuration = $::cache::nodes['mobile']
    $mobile_hosts_regex = inline_template('(<%= @cache_configuration.values.flatten.sort.join(\'|\') %>)')

    # 1/100 sampling of traffic from mobile varnishes
    ::kafkatee::output { 'mobile-sampled-100':
        destination => "/bin/grep -P '${mobile_hosts_regex}' >> ${webrequest_log_directory}/mobile-sampled-100.tsv.log",
        sample      => 100,
        type        => 'pipe',
    }

    # Capture all logs with 'zero=' set.  The X-Analytics header is set with this
    # by mobile varnish frontends upon getting a Wikipedia Zero request.
    ::kafkatee::output { 'zero':
        destination => "/bin/grep -P 'zero=\\d' >> ${webrequest_log_directory}/zero.tsv.log",
        type        => 'pipe',
    }
}

# == Class role::analytics::kafkatee::webrequest::sampled
# Sets up kafkatee to consume from all 4 webrequest topics output
# to a file with no filtering, but with 1/1000 requests sampled.
#
class role::analytics::kafkatee::webrequest::sampled inherits role::analytics::kafkatee::webrequest {
    include role::analytics::kafkatee::input::webrequest

    ::kafkatee::output { 'sampled-1000':
        destination => "${webrequest_log_directory}/sampled-1000.tsv.log",
        sample      => 1000,
    }
}

# == Class role::analytics::kafkatee::webrequest::edits
# Filter for all edit webrequests
#
class role::analytics::kafkatee::webrequest::edits inherits role::analytics::kafkatee::webrequest {
    include role::analytics::kafkatee::input::webrequest

    ::kafkatee::output { 'edits':
        destination => "/usr/bin/udp-filter -F '\t' -p action=submit,action=edit >> ${webrequest_log_directory}/edits.tsv.log",
        type        => 'pipe',
    }
}

# == Class role::analytics::kafkatee::webrequest::5xx
# Filter for all webrequest 5xx HTTP response status not from upload hosts.
#
class role::analytics::kafkatee::webrequest::5xx inherits role::analytics::kafkatee::webrequest {
    include role::analytics::kafkatee::input::webrequest

    ::kafkatee::output { '5xx':
        destination => "/usr/bin/udp-filter -F '\t' -r -s '^5' | awk -W interactive '\$9 !~ \"upload.wikimedia.org\"' >> ${webrequest_log_directory}/5xx.tsv.log",
        type        => 'pipe',
    }
}

# == Class role::analytics::kafkatee::webrequest::api
# Filter for all API webrequests, sampling 1 out of 100 requests
#
class role::analytics::kafkatee::webrequest::api inherits role::analytics::kafkatee::webrequest {
    include role::analytics::kafkatee::input::webrequest

    ::kafkatee::output { 'api':
        destination => "/usr/bin/udp-filter -F '\t' -p /w/api.php >> ${webrequest_log_directory}/api-usage.tsv.log",
        type        => 'pipe',
        sample      => 100,
    }
}

# == Class role::analytics::kafkatee::webrequest::glam_nara
# Filter for GLAM NARA / National Archives - RT 2212, sampled 1 / 10 requests.
#
class role::analytics::kafkatee::webrequest::glam_nara inherits role::analytics::kafkatee::webrequest {
    include role::analytics::kafkatee::input::webrequest

    ::kafkatee::output { 'glam_nara':
        destination => "/usr/bin/udp-filter -F '\t' -p _NARA_ -g -b country >> ${webrequest_log_directory}/glam_nara.tsv.log",
        type        => 'pipe',
        sample      => 10,
    }
}



# == Class role::analytics::kafkatee::input::webrequest
# Includes each of the 4 webrequest topics as input
# You can use this class, or if you want to consume
# only an individual topic, include one of the
# topic specific classes manually.
class role::analytics::kafkatee::input::webrequest {
    include role::analytics::kafkatee::input::webrequest::mobile
    include role::analytics::kafkatee::input::webrequest::text
    include role::analytics::kafkatee::input::webrequest::bits
    include role::analytics::kafkatee::input::webrequest::upload
}



# == Class role::analytics::kafkatee::input::webrequest::mobile
# Sets up a kafkatee input to consume from the webrequest_mobile topic
# This is its own class so that if a kafkatee instance wants
# to consume from multiple topics, it may include each
# topic as a class.
#
class role::analytics::kafkatee::input::webrequest::mobile {
    ::kafkatee::input { 'kafka-webrequest_mobile':
        topic       => 'webrequest_mobile',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'stored',
    }
}
# == Class role::analytics::kafkatee::input::webrequest::text
# Sets up a kafkatee input to consume from the webrequest_text topic
# This is its own class so that if a kafkatee instance wants
# to consume from multiple topics, it may include each
# topic as a class.
#
class role::analytics::kafkatee::input::webrequest::text {
    ::kafkatee::input { 'kafka-webrequest_text':
        topic       => 'webrequest_text',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'stored',
    }
}
# == Class role::analytics::kafkatee::input::webrequest::bits
# Sets up a kafkatee input to consume from the webrequest_bits topic
# This is its own class so that if a kafkatee instance wants
# to consume from multiple topics, it may include each
# topic as a class.
#
class role::analytics::kafkatee::input::webrequest::bits {
    ::kafkatee::input { 'kafka-webrequest_bits':
        topic       => 'webrequest_bits',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'stored',
    }
}
# == Class role::analytics::kafkatee::input::webrequest::upload
# Sets up a kafkatee input to consume from the webrequest_upload topic
# This is its own class so that if a kafkatee instance wants
# to consume from multiple topics, it may include each
# topic as a class.
#
class role::analytics::kafkatee::input::webrequest::upload {
    ::kafkatee::input { 'kafka-webrequest_upload':
        topic       => 'webrequest_upload',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'stored',
    }
}


