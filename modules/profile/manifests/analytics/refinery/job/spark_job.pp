# == Define profile::analytics::refinery::job::spark_job
#
# Renders a spark2-submit wrapper script and sets up a systemd timer to run it.
#
# == Properties
#
# [*jar*]
#   Path to Spark job .jar file
#
# [*class*]
#   Spark job main class name.
#
# [*job_name*]
#   Name of this spark job; will be used for script, cron job, and Spark --name.
#   Default: $title
#
# [*spark_opts*]
#   Extra Spark CLI opts to be passed to spark2-submit
#
# [*job_opts*]
#   CLI opts to append to the spark2-submit command; these will be passed to your main
#   function as args.
#
# [*log_file*]
#   Default: /var/log/refinery/$job_name.log
#
# [*interval*]
#   Systemd time interval.
#   Default: '*-*-* *:00:00' (hourly)
#
define profile::analytics::refinery::job::spark_job(
    $jar,
    $class,
    $job_name            = $title,
    $spark_opts          = undef,
    $job_opts            = undef,
    $log_file            = "/var/log/refinery/${job_name}.log",
    $user                = 'analytics',
    $interval            = '*-*-* *:00:00',
    $environment         = undef,
    $ensure              = 'present',
    $send_mail           = true,
    $use_keytab          = false,
)
{
    require ::profile::analytics::refinery
    $refinery_path = $profile::analytics::refinery::path

    if $use_keytab {
        $spark_keytab_extra_opts = "--principal ${user}/${facts['fqdn']}@WIKIMEDIA --keytab /etc/security/keytabs/${user}/${user}.keytab"
    } else {
        $spark_keytab_extra_opts = undef
    }

    $script = "/usr/local/bin/${job_name}"

    file { $script:
        ensure  => $ensure,
        content => template('profile/analytics/refinery/job/spark_job.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

    kerberos::systemd_timer { $title:
        ensure                  => $ensure,
        description             => "Spark job for ${title}",
        command                 => $script,
        interval                => $interval,
        user                    => $user,
        environment             => $environment,
        send_mail               => $send_mail,
        logfile_basedir         => '/var/log/refinery',
        logfile_name            => "${title}.log",
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
