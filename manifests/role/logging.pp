# logging (udp2log) servers

# base node definition from which logging nodes (erbium, etc)
# inherit. Note that there is no real node named "base_analytics_logging_node".
# This is done as a base node primarily so that we can override the
# $nagios_contact_group variable.
node "base_analytics_logging_node" {

    # include analytics in nagios_contact_group.
    # This is used by class base::monitoring::host for
    # notifications when a host or important service goes down.
    # NOTE:  This cannot be a fully qualified var
    # (i.e. $base::nagios_contact_group) because puppet does not
    # allow setting variables in other namespaces.  I could
    # parameterize class base AND class stanrdard and pass
    # the var down the chain, but that seems like too much
    # modification for just this.  Instead this overrides
    # the default contact_group of 'admins' set in class base.
    $nagios_contact_group = 'admins,analytics'

    include standard
    include role::logging
}

class role::logging
{
    system::role { 'role::logging':
        description => 'log collector',
    }

    include nrpe
    include geoip
}

# mediawiki udp2log instance.  Does not use monitoring.
class role::logging::mediawiki($monitor = true, $log_directory = '/home/wikipedia/logs' ) {
    system::role { 'role::logging:mediawiki':
        description => 'MediaWiki log collector',
    }

    class { 'misc::udp2log':
        monitor          => $monitor,
        default_instance => false,
    }

    include misc::udp2log::utilities
    include misc::udp2log::firewall

    $error_processor_host = $::realm ? {
        production => 'eventlog1001.eqiad.wmnet',
        labs       => "deployment-fluoride.${::site}.wmflabs",
    }

    $logstash_host = $::realm ? {
        # TODO: Find a way to use multicast that doesn't cause duplicate
        # messages to be stored in logstash. This is a SPOF.
        production => 'logstash1001.eqiad.wmnet',
        labs       => 'deployment-logstash1.eqiad.wmflabs',
    }

    $logstash_port = 8324

    misc::udp2log::instance { 'mw':
        log_directory       =>    $log_directory,
        monitor_log_age     =>    false,
        monitor_processes   =>    false,
        monitor_packet_loss =>    false,
        template_variables  => {
            error_processor_host => $error_processor_host,
            error_processor_port => 8423,

            # forwarding to logstash
            logstash_host        => $logstash_host,
            logstash_port        => $logstash_port,
        },
    }

    cron { 'mw-log-cleanup':
        command => '/usr/local/bin/mw-log-cleanup',
        user    => 'root',
        hour    => 2,
        minute  => 0
    }

    file { '/usr/local/bin/mw-log-cleanup':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///files/misc/scripts/mw-log-cleanup',
    }

    file { '/usr/local/bin/exceptionmonitor':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('misc/exceptionmonitor.erb'),
    }

    file { '/usr/local/bin/fatalmonitor':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///files/misc/scripts/fatalmonitor',
    }

    $cirrussearch_slow_log_check_interval = 5
    # Send CirrusSearch-slow.log entry rate to ganglia.
    logster::job { 'CirrusSearch-slow.log':
        parser          => 'LineCountLogster',
        logfile         => "${log_directory}/CirrusSearch-slow.log",
        logster_options => '--output ganglia --metric-prefix CirrusSearch-slow.log',
        minute          => "*/${cirrussearch_slow_log_check_interval}"
    }
    # The logster job runs every $cirrussearch_slow_log_check_interval
    # minutes.  We set retries to
    # 60 minutes / cirrussearch_slow_log_check_interval minutes)
    # This should keep icinga from alerting us unless the alert thresholds are
    # exceeded for more than an hour.
    monitoring::ganglia { 'CirrusSearch-slow-queries':
        description           => 'Slow CirrusSearch query rate',
        # this metric is output to ganglia by logster
        metric                => 'CirrusSearch-slow.log_line_rate',
        # warning  ->  36 queries/h
        # critical -> 360 queries/h
        warning               => '0.01',
        critical              => '0.1',
        normal_check_interval => $cirrussearch_slow_log_check_interval,
        retry_check_interval  => $cirrussearch_slow_log_check_interval,
        retries               => (60/$cirrussearch_slow_log_check_interval),
        require               => Logster::Job['CirrusSearch-slow.log'],
    }


}

# == Class role::logging::mediawiki::errors
# fluorine's udp2log instance forwards MediaWiki exceptions and fatals
# to eventlog*, as configured in templates/udp2log/filters.mw.erb. This
# role provisions a metric module that reports error counts to StatsD.
#
class role::logging::mediawiki::errors {
    system::role { 'role::logging::mediawiki::errors':
        description => 'Report MediaWiki exceptions and fatals to StatsD',
    }

    class { 'mediawiki::monitoring::errors': }
}

# == Class role::logging::relay::webrequest-multicast
# Sets up a multicast relay using socat for
# webrequest log streams (squid, varnish, nginx etc.).
# Anything sent to this node on port 8419 will be
# relayed to the 233.58.59.1:8420 multicast group.
#
class role::logging::relay::webrequest-multicast {
    system::role { 'role::logging::relay::webrequest-multicast':
        description => 'Webrequest log stream unicast to multicast relay',
    }

    misc::logging::relay { 'webrequest':
        listen_port      => '8419',
        destination_ip   => '233.58.59.1',
        destination_port => '8420',
        multicast        => true,
    }
}

# == Class role::logging::relay::eventlogging
# Relays EventLogging traffic over to eventlog*.
#
class role::logging::relay::eventlogging {
    system::role { 'misc::logging::relay::eventlogging':
        description => 'esams bits event logging to eventlog* relay',
    }

    misc::logging::relay { 'eventlogging':
        listen_port      => '8422',
        destination_ip   => '10.64.32.167', # eventlog1001
        destination_port => '8422',
    }
}


# udp2log base role class
class role::logging::udp2log {
    include misc::udp2log
    include misc::udp2log::utilities

    $log_directory = '/a/log'

    file { $log_directory:
        ensure => 'directory',
    }

    # Set up an rsync daemon module for udp2log logrotated
    # archives.  This allows stat1003 to copy logs from the
    # logrotated archive directory
    class { 'misc::udp2log::rsyncd':
        path    => $log_directory,
        require => File[$log_directory],
    }
}

# == Class role::logging::udp2log::erbium
# Erbium udp2log instance:
# - Fundraising: This requires write permissions on the netapp mount.
#
class role::logging::udp2log::erbium inherits role::logging::udp2log {
    include misc::fundraising::udp2log_rotation
    include role::logging::systemusers

    # udp2log::instance will ensure this is created
    $webrequest_log_directory    = "$log_directory/webrequest"

    # keep fundraising logs in a subdir
    $fundraising_log_directory = "${log_directory}/fundraising"

    file { $fundraising_log_directory:
        ensure  => 'directory',
        mode    => '0775',
        owner   => 'udp2log',
        group   => 'file_mover',
        require =>  User['file_mover'],
    }

    file { "${fundraising_log_directory}/logs":
        ensure  => 'directory',
        mode    => '2775',  # make sure setgid bit is set.
        owner   => 'udp2log',
        group   => 'file_mover',
        require =>  User['file_mover'],
    }

    misc::udp2log::instance { 'erbium':
        port               => '8419',
        packet_loss_log    => '/var/log/udp2log/packet-loss.log',
        log_directory      => $webrequest_log_directory,
        template_variables => {
            'fundraising_log_directory' => $fundraising_log_directory
        },
        require            => File["${fundraising_log_directory}/logs"],
    }
}

# misc udp2log instance, mainly for a post-udp2log era...one day :)
class role::logging::udp2log::misc {
    include misc::udp2log
    include misc::udp2log::utilities

    misc::udp2log::instance { 'misc':
        multicast       => true,
        packet_loss_log => '/var/log/udp2log/packet-loss.log',
        monitor_log_age => false,
    }
}

class role::logging::systemusers {

    group { 'file_mover':
        ensure => present,
        name   => 'file_mover',
        system => true,
    }

    user { 'file_mover':
        uid        => 30001,
        shell      => '/bin/bash',
        gid        => 30001,
        home       => '/var/lib/file_mover',
        managehome => true,
        system     => true,
    }

    file { '/var/lib/file_mover':
        ensure => directory,
        owner  => 'file_mover',
        group  => 'file_mover',
        mode   => '0755',
    }

    file { '/var/lib/file_mover/.ssh':
        ensure => directory,
        owner  => 'file_mover',
        group  => 'file_mover',
        mode   => '0700',
    }

    ssh_authorized_key { 'file_mover':
        ensure  => present,
        user    => 'file_mover',
        type    => 'ssh-rsa',
        key     => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA7c29cQHB7hbBwvp1aAqnzkfjJpkpiLo3gwpv73DAZ2FVhDR4PBCoksA4GvUwoG8s7tVn2Xahj4p/jRF67XLudceY92xUTjisSHWYrqCqHrrlcbBFjhqAul09Zwi4rojckTyreABBywq76eVj5yWIenJ6p/gV+vmRRNY3iJjWkddmWbwhfWag53M/gCv05iceKK8E7DjMWGznWFa1Q8IUvfI3kq1XC4EY6REL53U3SkRaCW/HFU0raalJEwNZPoGUaT7RZQsaKI6ec8i2EqTmDwqiN4oq/LDmnCxrO9vMknBSOJG2gCBoA/DngU276zYLg2wsElTPumN8/jVjTnjgtw==',
        require => File['/var/lib/file_mover/.ssh'],
    }
}

# == Class role::logging::kafkatee::webrequest
# TODO: This needs a not-stupid name.
#
# Uses kafkatee to consume webrequest logs from kafka.
# This class does not configure any kafkatee outputs.
# To do so, you should create a new class that inherits
# from this class, and configure the outputs there.
#
class role::logging::kafkatee::webrequest {
    require role::analytics::kafka::config

    # Install kafkatee configured to consume from
    # the Analytics Kafka cluster.  The webrequest logs are
    # in json, so we output them in the format they are received.
    class { '::kafkatee':
        kafka_brokers           => $role::analytics::kafka::config::brokers_array,
        output_encoding         => 'json',
        output_format           => undef,
    }
    include kafkatee::monitoring

    # TODO: Do we need all topics for ops debugging of webrequest logs?

    # Include all webrequest topics as inputs.
    # Note:  we used offset => 'end' rather than 'stored'
    # because we don't need to backfill these files from
    # buffered kafka data if kafkatee goes down.
    # These are just logs for ops debugging.
    kafkatee::input { 'kafka-webrequest_bits':
        topic       => 'webrequest_bits',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'end',
    }
    kafkatee::input { 'kafka-webrequest_misc':
        topic       => 'webrequest_misc',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'end',
    }
    kafkatee::input { 'kafka-webrequest_mobile':
        topic       => 'webrequest_mobile',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'end',
    }
    kafkatee::input { 'kafka-webrequest_text':
        topic       => 'webrequest_text',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'end',
    }
    kafkatee::input { 'kafka-webrequest_upload':
        topic       => 'webrequest_upload',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'end',
    }

    # Declare packaged rsyslog config to ensure it isn't purged.
    file { '/etc/rsyslog.d/75-kafkatee.conf':
        ensure  => file,
        require => Class['::kafkatee'],
    }

    $log_directory              = '/srv/log'
    $webrequest_log_directory   = "${log_directory}/webrequest"
    file { [$log_directory, $webrequest_log_directory]:
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

}

# == Class role::logging::kafkatee::webrequest::ops
# Includes output filters useful for operational debugging.
#
class role::logging::kafkatee::webrequest::ops inherits role::logging::kafkatee::webrequest  {
    kafkatee::output { 'sampled-1000':
        destination => "${webrequest_log_directory}/sampled-1000.json",
        sample      => 1000,
    }

    kafkatee::output { '5xx':
        destination => "/bin/grep '\"http_status\":\"5' >> ${webrequest_log_directory}/5xx.json",
        type        => 'pipe',
    }
}

# This does not inherit from role::logging::kafkatee::webrequest
# because we need to use a custom output format, and don't need
# all webrequest sources.
class role::logging::kafkatee::webrequest::fundraising {
    require role::analytics::kafka::config

    # The fundraising outputs use udp-filter
    require misc::udp2log::udp_filter


    # Install kafkatee configured to consume from
    # the Analytics Kafka cluster.  The webrequest logs are
    # in json, so we output them in the format they are received.
    class { '::kafkatee':
        kafka_brokers           => $role::analytics::kafka::config::brokers_array,
        # convert the json logs into the old udp2log tsv format.
        output_encoding         => 'string',
        output_format           => '%{hostname}	%{sequence}	%{dt}	%{time_firstbyte}	%{ip}	%{cache_status}/%{http_status}	%{response_size}	%{http_method}	http://%{uri_host}%{uri_path}%{uri_query}	-	%{content_type}	%{referer}	%{x_forwarded_for}	%{user_agent}	%{accept_language}	%{x_analytics}',
    }
    include kafkatee::monitoring

    # TODO: Do we need all topics for ops debugging of webrequest logs?

    # Fundraising logs only need mobile and text as inputs.
    # Setting offset to 'end' instead of 'stored', only
    # because that is how udp2log worked, and I don't want to
    # cause any weirdness with downstream consumers if an instance
    # starts up late and consumes older data.
    kafkatee::input { 'kafka-webrequest_mobile':
        topic       => 'webrequest_mobile',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'end',
    }
    kafkatee::input { 'kafka-webrequest_text':
        topic       => 'webrequest_text',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'end',
    }

    # Declare packaged rsyslog config to ensure it isn't purged.
    file { '/etc/rsyslog.d/75-kafkatee.conf':
        ensure  => file,
        require => Class['::kafkatee'],
    }

    # Temporarly use a different log directory than udp2log, while we run
    # both kafkatee and udp2log side by side so that FR techs can
    # validate that we can use kafkatee instead of udp2log.
    $log_directory              = '/a/log/fundraising-kafkatee'
    file { $log_directory:
        ensure      => 'directory',
        owner       => 'kafkatee',
        group       => 'kafkatee',
        require     => Class['::kafkatee'],
    }

    # if the logs in $log_directory should be rotated
    # then configure a logrotate.d script to do so.
    file { '/etc/logrotate.d/kafkatee-fundraising':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('kafkatee/logrotate_fundraising.erb'),
    }


    kafkatee::output { 'fundraising-landingpages':
        destination => "/usr/bin/udp-filter -F '\t' -d wikimediafoundation.org,donate.wikimedia.org >> ${log_directory}/landingpages.tsv.log",
        type        => 'pipe',
    }

    kafkatee::output { 'fundraising-bannerImpressions':
        destination => "/usr/bin/udp-filter -F '\t' -p Special:RecordImpression >> ${log_directory}/bannerImpressions-sampled100.tsv.log",
        sample      => 100,
        type        => 'pipe',
    }

    kafkatee::output { 'fundraising-bannerRequests':
        destination => "/usr/bin/udp-filter -F '\t' -p Special:BannerRandom >> ${log_directory}/bannerRequests-sampled100.tsv.log",
        sample      => 100,
        type        => 'pipe',
    }
}
