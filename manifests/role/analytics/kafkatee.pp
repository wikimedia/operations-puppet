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

    # Include this to infer mobile varnish frontend hostnames on which to filter.
    include role::cache::configuration
    $cache_configuration = $role::cache::configuration::active_nodes['production']['mobile']
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
        destination => "/usr/bin/udp-filter -F '\t' -r -s '^5' | awk -W interactive '$9 !~ \"upload.wikimedia.org\"' >> ${webrequest_log_directory}/5xx.tsv.log",
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

    # webstatscollector package creates this directory.
    # webstats-collector process writes dump files here.
    $webstats_dumps_directory = '/srv/log/webstats/dumps'
    # collector creates temporary Berkeley DB files that have
    # very high write IO.  Upstart will chdir into
    # this temp directory before starting collector.
    $webstats_temp_directory   = '/run/webstats'

    $collector_host           = $::fqdn
    $collector_port           = 3815

    file { $webstats_temp_directory:
        ensure => 'directory',
        owner  => 'nobody',
        group  => 'nogroup',
    }
    # Mount the temp directory as a tmpfs in /run
    mount { $webstats_temp_directory:
        ensure  => 'mounted',
        device  => 'tmpfs',
        fstype  => 'tmpfs',
        options => 'uid=nobody,gid=nogroup,mode=0755,noatime,defaults,size=2000m',
        pass    => 0,
        dump    => 0,
        require => File[$webstats_temp_directory],
    }

    # Create the dumps/ directory in which
    # we want collector to output hourly dump files.
    file { $webstats_dumps_directory:
        ensure  => 'directory',
        owner   => 'nobody',
        group   => 'nogroup',
        require => Mount[$webstats_temp_directory],
    }
    # collector writes dumps to $cwd/dumps.  We are going
    # run collector in $webstats_temp_directory, but we want dumps to be
    # on the normal filesystem.  Symlink $webstats_temp_directory/dumps
    # to the dumps directory.
    file { "${webstats_temp_directory}/dumps":
        ensure  => 'link',
        target  => $webstats_dumps_directory,
        require => File[$webstats_dumps_directory],
    }

    package { 'webstatscollector':
        ensure => 'installed',
    }
    # Install a custom webstats-collector init script to use
    # custom temp directory.
    file { '/etc/init/webstats-collector.conf':
        content => template('webstatscollector/webstats-collector.init.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['webstatscollector'],
    }

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
        destination => "/usr/local/bin/filter | /usr/bin/log2udp -h ${collector_host} -p ${collector_port}",
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


