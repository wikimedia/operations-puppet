# Class: udp2log
#
# Includes packages and setup for misc::udp2log::instances.
# Make sure you include this class if you plan on using
# the misc::udp2log::instance define below.
#
# Parameters:
#    $monitor  - If true, monitoring scripts will be installed.  Default: true
#    $default_instance  - If false, remove init script for the default instance.  Default: true
class misc::udp2log(
    $monitor = true,
    $default_instance = true
) {

    include contacts::udp2log
    include misc::udp2log::udp_filter

    sysctl::parameters { 'big rmem':
        values => {
            'net.core.rmem_max'     => 536870912,
            'net.core.rmem_default' => 4194304,
        },
    }

    # include the monitoring scripts
    # required for monitoring udp2log instances
    if $monitor {
    # TODO: Should probably include icincga package here.
        include misc::udp2log::monitoring
        include misc::udp2log::firewall
    }

    system::role { 'udp2log::logger':
        description => 'udp2log data collection server',
    }

    # make sure the udp2log filter config directory exists
    file { '/etc/udp2log':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    # make sure the udplog package is installed
    package { 'udplog':
        ensure => present,
    }

    if !$default_instance {
        file { '/etc/init.d/udp2log':
            ensure  => absent,
            require => Package['udplog']
        }
        exec { '/usr/sbin/update-rc.d -f udp2log remove':
            subscribe   => File['/etc/init.d/udp2log'],
            refreshonly => true
        }
    }
}

# Class: misc::udp2log::rsyncd
#
# Sets up an rsync daemon to allow statistics
# and analytics servers to copy logs off of a
# udp2log host.
#
# Parameters:
#   $path        - path to udp2log logrotated archive directory
#   $allow_hosts - IP address of host from which to allow rsync
#
class misc::udp2log::rsyncd(
        $path        = '/var/log/udp2log/archive',
        $hosts_allow = ['stat1002.eqiad.wmnet']
) {


    class { 'rsync::server':
        # We don't want rsyncs to saturate udp2log host NICs.
        # Limit to 500M / sec.
        rsync_opts => ['--bwlimit 512000'],
    }

    rsync::server::module { 'udp2log':
        comment     => 'udp2log log files',
        path        => $path,
        read_only   => 'yes',
        hosts_allow => $hosts_allow;
    }

    ferm::service { 'udp2log_rsyncd':
        proto  => 'tcp',
        port   => '873',
        srange => '@resolve(stat1002.eqiad.wmnet)',
    }
}


# Define: misc::udp2log::instance
#
# Sets up a udp2log daemon instance.
#
# Parameters:
#$port                - Default 8420.
#$log_directory       - Main location for log files.Default: /var/log/udp2log
#$packet_loss_log     - Path to packet-loss.log file.  Used for monitoring. Default: $log_directory/packet-loss.log.
#$logrotate           - If true, sets up a logrotate file for files in $log_directory. Default: true
#$multicast           - If true, the udp2log instance will be started with the --multicast 233.58.59.1. If you give a string, --mulitcast will be set to this string. Default: false
#$ensure              - Either 'stopped' or 'running'. Default: 'running'
#$monitor_packet_loss - bool. Default: true
#$monitor_processes   - bool. Default: true
#$monitor_log_age     - bool. Default: true
#$template_variables  - arbitrary variable(s) for use in udp2log config template file. Default: undef
#$recv_queue          - in KB.  If unset, --recv-queue may be set to /proc/sys/net/core/rmem_max.
#$logrotate_template  - Path to template file to use for logrotate.  Default: udp2log_logrotate.erb
#
define misc::udp2log::instance(
    $port                = '8420',
    $log_directory       = '/var/log/udp2log',
    $logrotate           = true,
    $multicast           = false,
    $ensure              = 'running',
    $packet_loss_log     = undef,
    $monitor_packet_loss = true,
    $monitor_processes   = true,
    $monitor_log_age     = true,
    $template_variables  = undef,
    $recv_queue          = undef,
    $logrotate_template  = 'udp2log/logrotate_udp2log.erb',
){
    # This define requires that the udp2log class has
    # been included.  The udp2log class is parameterized,
    # so we don't want to use the require statement here
    # to make sure it is included.  This just sets
    # up the dependency.
    Class['misc::udp2log'] -> Misc::Udp2log::Instance[$title]

    # the udp2log instance's filter config file
    file { "/etc/udp2log/${name}":
        require => Package['udplog'],
        mode    => '0744',
        owner   => 'root',
        group   => 'root',
        content => template("udp2log/filters.${name}.erb"),
    }

    # init service script for this udp2log instance
    file { "/etc/init.d/udp2log-${name}":
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('udp2log/udp2log.init.erb'),
    }

    # primary directory where udp2log log files will be stored.
    file { [$log_directory, "${log_directory}/archive"]:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'udp2log',
        group  => 'udp2log',
    }

    $logrotation = $logrotate ? {
        false   => 'absent',
        default => 'present',
    }


    # if the logs in $log_directory should be rotated
    # then configure a logrotate.d script to do so.
    file { "/etc/logrotate.d/udp2log-${name}":
        ensure  => $logrotation,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template($logrotate_template),
    }

    # ensure that this udp2log instance is running
    service { "udp2log-${name}":
        ensure    => $ensure,  # ensure stopped or running
        enable    => true,     # make sure this starts on boot
        subscribe => File["/etc/udp2log/${name}"],
        hasstatus => false,
        require   => [Package['udplog'],
                    File["/etc/udp2log/${name}"],
                    File["/etc/init.d/udp2log-${name}"]
        ],
    }

    ferm::service { 'udp2log_instance':
        proto  => 'udp',
        port   => $port,
        srange => '$INTERNAL',
    }

    # only set up instance monitoring if the monitoring scripts are installed
    if $::misc::udp2log::monitor {
        # include monitoring for this udp2log instance.
        misc::udp2log::instance::monitoring { $name:
            ensure              => $ensure,
            log_directory       => $log_directory,
            packet_loss_log     => $packet_loss_log,
            monitor_packet_loss => $monitor_packet_loss,
            monitor_processes   => $monitor_processes,
            monitor_log_age     => $monitor_log_age,
            require             => Service["udp2log-${name}"],
        }
    }
}


# == Define misc::udp2log::instance::monitoring
# Monitoring configs for a udp2log instance.
# This is abstracted out of the udp2log::instance
# define so it is possible to monitor non-puppetized
# udp2log instances.
#
# == Parameters:
# See documentation for misc::udp2log::instance.
#
define misc::udp2log::instance::monitoring(
    $log_directory       = '/var/log/udp2log',
    $ensure              = 'running',
    $packet_loss_log     = undef,
    $monitor_packet_loss = true,
    $monitor_processes   = true,
    $monitor_log_age     = true,
) {
    require misc::udp2log::monitoring

    # Monitoring configs.
    # There are 3 ways udp2log instances are currently defined:
    # - Check age of udp2log files.
    # - Check that udp2log filter processes are running.
    # - Check the packet-loss log file for execessive packet loss.
    # These different monitors are enabled or disabled using
    # their corresponding $monitor_xxxxx arguments passed into
    # this class.

    # Monitor age of log udp2log files.
    if ($monitor_log_age == true and $ensure == 'running') {
        nrpe::monitor_service { "udp2log_log_age-${name}":
            ensure        => 'present',
            description   => "udp2log log age for ${name}",
            nrpe_command  => "/usr/lib/nagios/plugins/check_udp2log_log_age ${name}",
            contact_group => 'admins,analytics',
        }
    }
    # TODO else ensure absent,
    # can't do this right now due to missing dependencies

    # Monitor that each filter process defined in
    # /etc/udp2log/$name is running
    if ($ensure_monitor_processes == true and $ensure == 'running') {
        nrpe::monitor_service { "udp2log_procs-${name}":
            ensure        => 'present',
            description   => "udp2log processes for ${name}",
            nrpe_command  => "/usr/lib/nagios/plugins/check_udp2log_procs ${name}",
            contact_group => 'admins,analytics',
            retries       => 10,
        }
    }
    # TODO else ensure absent,
    # can't do this right now due to missing dependencies

    # Monitor packet loss using the $packet_loss_log.
    # This requires that filters.$name.erb has a
    # packet-loss filter defined and outputting
    # to $packet_loss_log_file.
    if ($monitor_packet_loss == true and $ensure == 'running') {
        $ensure_monitor_packet_loss = 'present'
    }
    else {
        $ensure_monitor_packet_loss = 'absent'
    }

    # The packet loss file by default is in
    # $log_directory/packet-loss.log.  If it was
    # passed in explicitly, then use the value given.
    $packet_loss_log_file = $packet_loss_log ? {
        undef   => "${log_directory}/packet-loss.log",
        default => $packet_loss_log,
    }

    if ($monitor_packet_loss == true) {
        # Set up a cron to tail the packet loss log for this
        # instance into ganglia.
        cron { "ganglia-logtailer-udp2log-${name}":
            ensure  => $ensure_monitor_packet_loss,
            command => "/usr/sbin/ganglia-logtailer --classname PacketLossLogtailer --log_file ${packet_loss_log_file} --mode cron >> /var/log/ganglia/ganglia-logtailer.log 2>&1 ",
            user    => 'root',
            minute  => '*/5',
        }

        # Set up nagios monitoring of packet loss
        # for this udp2log instance.
        monitoring::ganglia{ "udp2log-${name}-packetloss":
            ensure                => $ensure_monitor_packet_loss,
            description           => 'Packetloss_Average',
            metric                => 'packet_loss_average',
            warning               => '4',
            critical              => '8',
            contact_group         => 'admins,analytics',
            # ganglia-logtailer only runs every 5.
            # let's make nagios check every 2 minutes (to match ganglia_parser)
            # and retry 4 times (total 8 minutes) before
            # declaring a hard failure.
            normal_check_interval => 2,
            retry_check_interval  => 2,
            retries               => 4,
        }
    }
    # TODO else ensure absent,
    # can't do this right now due to missing dependencies
}

class misc::udp2log::utilities {
    file { '/usr/local/bin/demux.py':
        mode   => '0544',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///files/misc/demux.py',
    }

    file { '/usr/local/bin/sqstat':
        ensure => 'absent',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///files/udp2log/sqstat.pl',
    }
}

class misc::udp2log::udp_filter {
    package { 'udp-filter':
        ensure => installed,
    }
    package { 'udp-filters':
        ensure => absent,
    }
}

# includes scripts and iptables rules
# needed for udp2log monitoring.
class misc::udp2log::monitoring {
    include misc::udp2log::firewall

    package { 'ganglia-logtailer':
        ensure => latest,
    }

    file { 'check_udp2log_log_age':
        path   => '/usr/lib/nagios/plugins/check_udp2log_log_age',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///files/icinga/check_udp2log_log_age',
    }

    file { 'check_udp2log_procs':
        path   => '/usr/lib/nagios/plugins/check_udp2log_procs',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///files/icinga/check_udp2log_procs',
    }

    file { 'rolematcher.py':
        path   => '/usr/share/ganglia-logtailer/rolematcher.py',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///files/misc/rolematcher.py',
    }

    file { 'PacketLossLogtailer.py':
        path   => '/usr/share/ganglia-logtailer/PacketLossLogtailer.py',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///files/misc/PacketLossLogtailer.py',
    }

    # send udp2log socket stats to ganglia.
    # include general UDP statistic monitoring.
    ganglia::plugin::python{ ['udp_stats', 'udp2log_socket']: }
}

class misc::udp2log::firewall {
    include base::firewall

    ferm::rule { 'udp2log_accept_all_wikimedia':
        rule => 'saddr ($ALL_NETWORKS) proto udp ACCEPT;',
    }

    ferm::rule { 'udp2log_notrack':
        table => 'raw',
        chain => 'PREROUTING',
        rule  => 'saddr ($ALL_NETWORKS) proto udp NOTRACK;',
    }

    # let monitoring host connect via NRPE
    ferm::rule { 'udp2log_accept_icinga_nrpe':
        rule => 'proto tcp dport 5666 { saddr $INTERNAL ACCEPT; }',
        prio => 13,
    }

}
