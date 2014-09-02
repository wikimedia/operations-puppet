# logging (udp2log) servers

# base node definition from which logging nodes (erbium, oxygen, etc)
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
    $nagios_contact_group = "admins,analytics"

    include
        standard,
        role::logging
}

class role::logging
{
    system::role { "role::logging": description => "log collector" }

    include nrpe
    include geoip
}

# mediawiki udp2log instance.  Does not use monitoring.
class role::logging::mediawiki($monitor = true, $log_directory = '/home/wikipedia/logs' ) {
    system::role { "role::logging:mediawiki": description => "MediaWiki log collector" }

    class { "misc::udp2log": monitor => $monitor }
    include misc::udp2log::utilities,
        misc::udp2log::iptables

    $error_processor_host = $::realm ? {
        production => 'vanadium.eqiad.wmnet',
        labs       => "deployment-fluoride.${::site}.wmflabs",
    }

    # TODO remove once beta cluster is migrated to eqiad
    $logtash_host_beta = $::site ? {
        eqiad => 'deployment-logstash1.eqiad.wmflabs',
        pmtpa => 'logstash.pmtpa.wmflabs',
    }
    $logstash_host = $::realm ? {
        # TODO: Find a way to use multicast that doesn't cause duplicate
        # messages to be stored in logstash. This is a SPOF.
        production => 'logstash1001.eqiad.wmnet',
        labs       => $logtash_host_beta,
    }

    $logstash_port = 8324

    misc::udp2log::instance { "mw":
        log_directory    =>    $log_directory,
        monitor_log_age    =>    false,
        monitor_processes    =>    false,
        monitor_packet_loss    =>    false,
        template_variables => {
            error_processor_host => $error_processor_host,
            error_processor_port => 8423,

            # forwarding to logstash
            logstash_host => $logstash_host,
            logstash_port => $logstash_port,
        },
    }

    cron { "mw-log-cleanup":
        command => "/usr/local/bin/mw-log-cleanup",
        user => root,
        hour => 2,
        minute => 0
    }

    file { "/usr/local/bin/mw-log-cleanup":
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => "puppet:///files/misc/scripts/mw-log-cleanup",
    }

    file { '/usr/local/bin/exceptionmonitor':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('misc/exceptionmonitor.erb'),
    }

    $cirrussearch_slow_log_check_interval = 5
    # Send CirrusSearch-slow.log entry rate to ganglia.
    logster::job { 'CirrusSearch-slow.log':
        parser          => 'LineCountLogster',
        logfile         => "${log_directory}/CirrusSearch-slow.log",
        logster_options => '--output ganglia --metric-prefix CirrusSearch-slow.log',
        minute          => "*/${cirrussearch_slow_log_check_interval}"
    }
    # Alert if CirrusSearch-slow.log shows more than
    # 10 slow searches within an hour.  The logster
    # job runs every $cirrussearch_slow_log_check_interval
    # minutes.  We set retries to
    # 60 minutes / cirrussearch_slow_log_check_interval minutes)
    # This should keep icinga from alerting
    # us unless the alert thresholds are exceeded
    # for more than an hour.
    monitor_ganglia { 'CirrusSearch-slow-queries':
        description           => 'Slow CirrusSearch query rate',
        # this metric is output to ganglia by logster
        metric                => 'CirrusSearch-slow.log_line_rate',
        # line_rate metric is per second, so we need to alert if this
        # metric goes over 0.000046296 / second.  Let's round
        # down to warning on 0.00004, or critical on 0.00008.
        warning               => '0.00004',
        critical              => '0.00008',
        normal_check_interval => $cirrussearch_slow_log_check_interval,
        retry_check_interval  => $cirrussearch_slow_log_check_interval,
        retries               => (60/$cirrussearch_slow_log_check_interval),
        require               => Logster::Job['CirrusSearch-slow.log'],
    }


}

class role::beta::logging::mediawiki {

    class { 'role::logging::mediawiki':
        log_directory => '/data/project/logs';
    }

}

# == Class role::logging::mediawiki::errors
# fluorine's udp2log instance forwards MediaWiki exceptions and fatals
# to vanadium, as configured in templates/udp2log/filters.mw.erb. This
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
# Relays EventLogging traffic over to Vandadium.
#
class role::logging::relay::eventlogging {
    system::role { 'misc::logging::relay::eventlogging':
        description => 'esams bits event logging to vanadium relay',
    }

    misc::logging::relay { 'eventlogging':
        listen_port      => '8422',
        destination_ip   => '10.64.21.123',
        destination_port => '8422',
    }
}


# udp2log base role class
class role::logging::udp2log {
    include misc::udp2log,
        misc::udp2log::utilities

    $log_directory               = '/a/log'

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

# nginx machines are configured to log to port 8421.
class role::logging::udp2log::nginx inherits role::logging::udp2log {
    $nginx_log_directory = "$log_directory/nginx"

    misc::udp2log::instance { 'nginx':
        port                => '8421',
        log_directory       => $nginx_log_directory,
        # don't monitor packet loss,
        # we aren't keeping packet loss log,
        # and nginx sequence numbers are messed up anyway.
        monitor_packet_loss => false
    }
}

class role::logging::webstatscollector {
    # datasets account is needed so that snapshot1
    # can rsync webstats dumps to dataset2 (dumps.wikimedia.org).
    include role::dataset::systemusers

    # webstatscollector package creates this directory.
    # webstats-collector process writes dump files here.
    $webstats_dumps_directory = '/a/webstats/dumps'
    # collector creates temporary Berkeley DB files that have
    # very high write IO.  Upstart will chdir into
    # this temp directory before starting collector.
    $webstats_temp_directory   = '/run/webstats'

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
        ensure => 'latest',
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
        hasstatus  => false,
        hasrestart => true,
        require    => [
            File['/etc/init/webstats-collector.conf'],
            File["${webstats_temp_directory}/dumps"],
        ],
    }

    # install a nrpe check for the webstatscollector collector process
    nrpe::monitor_service { 'webstats-collector':
        description   => "webstats-collector process running",
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs --argument-array /usr/local/bin/collector -c 1:2',
        contact_group => 'analytics',
        retries       => 10,
        require       => Service['webstats-collector']
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
}

# oxygen is a generic webrequests udp2log host
# mostly running:
# - Wikipedia zero filters
# - Webstatscollector 'filter'
class role::logging::udp2log::oxygen inherits role::logging::udp2log {
    # include this to infer mobile varnish frontend hosts in
    # udp2log filter template.
    include role::cache::configuration

    # udp2log::instance will ensure this is created
    $webrequest_log_directory    = "$log_directory/webrequest"

    # install custom filters here
    $webrequest_filter_directory = "$webrequest_log_directory/bin"
    file { $webrequest_filter_directory:
        ensure => directory,
        mode   => 0755,
        owner  => 'udp2log',
        group  => 'udp2log',
    }

    file { "$webrequest_filter_directory/vu.awk":
        ensure => 'file',
        source => 'puppet:///files/udp2log/vu.awk',
        mode   => 0755,
        owner  => 'udp2log',
        group  => 'udp2log',
    }
    file { "$webrequest_filter_directory/minnesota.awk":
        ensure => 'file',
        source => 'puppet:///files/udp2log/minnesota.awk',
        mode   => 0755,
        owner  => 'udp2log',
        group  => 'udp2log',
    }

    # oxygen run webstatscollector's filter process,
    # sending filtered logs to gadolinium's collector process.
    package { 'webstatscollector':
        ensure => 'latest',
    }

    misc::udp2log::instance { 'oxygen':
        multicast       => true,
        packet_loss_log => '/var/log/udp2log/packet-loss.log',
        log_directory   => $webrequest_log_directory,
        template_variables => { 'webrequest_filter_directory' => $webrequest_filter_directory },
        require            => Package['webstatscollector'],
    }
}

# lucene udp2log instance for capturing search logs
class role::logging::udp2log::lucene inherits role::logging::udp2log {
    # udp2log::instance will ensure this is created
    $lucene_log_directory    = "$log_directory/lucene"

    misc::udp2log::instance { 'lucene':
        port                 => '51234',
        log_directory        => $lucene_log_directory,
        monitor_packet_loss  => false,
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

    file { "${fundraising_log_directory}":
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


    # install a nrpe check for the webstatscollector filter process
    nrpe::monitor_service { 'webstats-filter':
        description   => "webstats-filter process running",
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs --argument-array /usr/local/bin/filter -c 1:3',
        contact_group => 'analytics',
        retries       => 10,
        require       => Misc::Udp2log::Instance['erbium'],
    }
}

# misc udp2log instance, mainly for a post-udp2log era...one day :)
class role::logging::udp2log::misc {
    include misc::udp2log,
        misc::udp2log::utilities

    misc::udp2log::instance { 'misc':
        multicast          => true,
        packet_loss_log    => '/var/log/udp2log/packet-loss.log',
        monitor_log_age    => false,
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
        owner => 'file_mover',
        group => 'file_mover',
        mode => '0755',
    }

    file { '/var/lib/file_mover/.ssh':
        ensure => directory,
        owner => 'file_mover',
        group => 'file_mover',
        mode => '0700',
    }

    ssh_authorized_key {
        "file_mover":
            ensure => present,
            user   => 'file_mover',
            type   => 'ssh-rsa',
            key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA7c29cQHB7hbBwvp1aAqnzkfjJpkpiLo3gwpv73DAZ2FVhDR4PBCoksA4GvUwoG8s7tVn2Xahj4p/jRF67XLudceY92xUTjisSHWYrqCqHrrlcbBFjhqAul09Zwi4rojckTyreABBywq76eVj5yWIenJ6p/gV+vmRRNY3iJjWkddmWbwhfWag53M/gCv05iceKK8E7DjMWGznWFa1Q8IUvfI3kq1XC4EY6REL53U3SkRaCW/HFU0raalJEwNZPoGUaT7RZQsaKI6ec8i2EqTmDwqiN4oq/LDmnCxrO9vMknBSOJG2gCBoA/DngU276zYLg2wsElTPumN8/jVjTnjgtw==',
            require => File['/var/lib/file_mover/.ssh'],
    }
}
