# == Define udp2log::instance
#
# Sets up a udp2log daemon instance.
#
# == Parameters
# $port                - Default 8420.
# $log_directory       - Main location for log files.Default: /var/log/udp2log
# $logrotate           - If true, sets up a logrotate file for files in
#                        $log_directory. Default: true
# $multicast           - If true, the udp2log instance will be started with the
#                        --multicast 233.58.59.1. If you give a string,
#                        --mulitcast will be set to this string. Default: false
# $ensure              - Either 'stopped' or 'running'. Default: 'running'
# $monitor_processes   - bool. Default: true
# $monitor_log_age     - bool. Default: true
# $template_variables  - arbitrary variable(s) for use in udp2log config
#                        template file. Default: undef
# $recv_queue          - in KB.  If unset, --recv-queue may be set to
#                        /proc/sys/net/core/rmem_max.
# $logrotate_template  - Path to template file to use for logrotate.  Default:
#                        udp2log_logrotate.erb
#
define udp2log::instance(
    $port                = '8420',
    $log_directory       = '/var/log/udp2log',
    $logrotate           = true,
    $multicast           = false,
    $ensure              = 'running',
    $monitor_processes   = true,
    $monitor_log_age     = true,
    $template_variables  = undef,
    $recv_queue          = '524288',
    $logrotate_template  = 'udp2log/logrotate_udp2log.erb',
    $rotate              = 1000,
){
    # This define requires that the udp2log class has
    # been included.  The udp2log class is parameterized,
    # so we don't want to use the require statement here
    # to make sure it is included.  This just sets
    # up the dependency.
    Class['udp2log'] -> Udp2log::Instance[$title]

    # Default template (udp2log/logrotate_udp2log.erb) required killall command
    # which comes from the psmisc package
    require_package('psmisc')

    require_package('udplog')

    base::service_unit { "udp2log-${name}":
        ensure   => $ensure,
        sysvinit => true,
        systemd  => true,
        subscribe => File["/etc/udp2log/${name}"],
        require   => [File["/etc/udp2log/${name}"],
                      File["/etc/init.d/udp2log-${name}"]
    }

    # the udp2log instance's filter config file
    file { "/etc/udp2log/${name}":
        mode    => '0744',
        owner   => 'root',
        group   => 'root',
        content => template("udp2log/filters.${name}.erb"),
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

    ferm::service { "udp2log_instance_${port}":
        proto  => 'udp',
        port   => $port,
        srange => '$DOMAIN_NETWORKS',
    }

    # only set up instance monitoring if the monitoring scripts are installed
    if $::udp2log::monitor {
        # include monitoring for this udp2log instance.
        udp2log::instance::monitoring { $name:
            ensure            => $ensure,
            log_directory     => $log_directory,
            monitor_processes => $monitor_processes,
            monitor_log_age   => $monitor_log_age,
            require           => Service["udp2log-${name}"],
        }
    }
}
