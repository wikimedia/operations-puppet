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

    # stat1002.eqiad.wmnet == 10.64.0.16
    $hosts_allow = ['10.64.0.16']
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

    # 1/100 sampling of traffic to mobile varnishes
    ::kafkatee::output { 'mobile-sampled-100':
        destination => "${webrequest_log_directory}/mobile-sampled-100.tsv.log",
        sample      => 100,
    }
    # Capture all logs with 'zero=' set.  The X-Analytics header is set with this
    # by mobile varnish frontends upon getting a Wikipedia Zero request.
    ::kafkatee::output { 'zero':
        destination => "/bin/grep -P 'zero=\\d' >> ${webrequest_log_directory}/zero.tsv.log",
        type        => 'pipe',
    }
}

# == role::analytics::kafkatee::webstatscollector
# We want to run webstatscollector via kafkatee for testing.
# Some of the production (role::logging::webstatscollector)
# configs are not relevant here, so we copy the class
# and edit it.
#
# webstatscollector needs the mobile and text webrequest logs,
# so this class makes sure that these topics are consumed by kafkaee
# by including their kafkatee::input::* roles.
#
class role::analytics::kafkatee::webrequest::webstatscollector {
    include role::analytics::kafkatee::input::webrequest::mobile
    include role::analytics::kafkatee::input::webrequest::text

    # webstats-collector process writes dump files here.
    $webstats_dumps_directory = '/srv/webstats/dumps'

    package { 'webstatscollector': ensure => installed }
    service { 'webstats-collector':
        ensure     => 'running',
        hasstatus  => 'false',
        hasrestart => 'true',
        require    => Package['webstatscollector'],
    }

    # Gzip pagecounts files hourly.
    cron { 'webstats-dumps-gzip':
        command => "/bin/gzip ${webstats_dumps_directory}/pagecounts-????????-?????? 2> /dev/null",
        minute  => 2,
        user    => 'nobody',
        require => Service['webstats-collector'],
    }

    # Delete webstats dumps that are older than 10 days daily.
    cron { 'webstats-dumps-delete':
        command => "/usr/bin/find ${webstats_dumps_directory} -maxdepth 1 -type f -mtime +10 -delete",
        minute  => 28,
        hour    => 1,
        user    => 'nobody',
        require => Service['webstats-collector'],
    }

    # kafkatee outputs into webstats filter and forwards to webstats collector via log2udp
    ::kafkatee::output { 'webstatscollector':
        destination => "/usr/local/bin/filter | /usr/bin/log2udp -h localhost -p 3815",
        type        => 'pipe',
        require     => Service['webstats-collector'],
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


