# == Define profile::analytics::refinery::job::java_job
#
# Renders a wrapper script to launch a java job and sets up a systemd timer to run it.
#
# == Properties
#
# [*jar*]
#   Path to the main .jar file
#
# [*main_class*]
#    Main class name.
#
# [*job_name*]
#   Name of this job; will be used for script and systemd timer job
#   Default: $title
#
# [*extra_classpath*]
#   Extra classpath entries.
#
# [*java_opts*]
#   Other CLI opts to pass to java, e.g. -D system properties definitions.
#
# [*proxy_host*]
#   If set, -Dhttp.proxyHost and -Dhttps.proxyHost will be added to java opts.
#   If you set this, you must also set proxy_port.
#
# [*proxy_port*]
#   Value for -Dhttp.proxyPort and -Dhttps.proxyPort.  Will only be used if
#   proxy_host is set.
#
# [*job_opts*]
#   CLI opts to append to the command; these will be passed to your main
#   function as args.
#
# [*interval*]
#   Systemd time interval.
#   Default: '*-*-* *:00:00' (hourly)
#
define profile::analytics::refinery::job::java_job(
    String $jar,
    String $main_class,
    String $job_name                            = $title,
    Optional[Array[String]] $extra_classpath    = undef,
    Optional[Array[String]] $java_opts          = undef,
    Optional[String] $proxy_host                = undef,
    Optional[Integer] $proxy_port               = undef,
    Optional[Array[String]] $job_opts           = undef,
    String $user                                = 'analytics',
    String $interval                            = '*-*-* *:00:00',
    Optional[Hash[String, String]] $environment = undef,
    String $ensure                              = 'present',
    Boolean $send_mail                          = true,
) {
    if $proxy_host and !$proxy_port {
        error('If using $proxy_host, you must also provide $proxy_port')
    }

    $classpath = $extra_classpath ? {
        undef   => [$jar],
        default => [$jar] + $extra_classpath,
    }

    $script = "/usr/local/bin/${job_name}"
    file { $script:
        ensure  => $ensure,
        content => template('profile/analytics/refinery/job/java_job.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

    kerberos::systemd_timer { $title:
        ensure                  => $ensure,
        description             => "Java job for ${title}",
        command                 => $script,
        interval                => $interval,
        user                    => $user,
        environment             => $environment,
        send_mail               => $send_mail,
        logfile_basedir         => '/var/log/refinery',
        logfile_name            => "${job_name}.log",
        logfile_owner           => $user,
        logfile_group           => $user,
        logfile_perms           => 'all',
        syslog_force_stop       => true,
        # Only need to match equality here, not startswith.
        syslog_match_startswith => false,
        syslog_identifier       => $title,
        require                 => File[$script],
    }
}
