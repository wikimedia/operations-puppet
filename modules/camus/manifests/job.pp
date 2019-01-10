# == Define camus::job
#
# Renders a camus.properties template and installs a
# cron job to launch a Camus MapReduce job in Hadoop.
#
# == Parameters
# [*kafka_brokers*]
#   Array or comma separated list of Kafka Broker addresses, e.g.
#   ['kafka1012.eqiad.wmnet:9092', 'kafka1013.eqiad.wmnet:9092']
#     OR
#   kafka1012.eqiad.wmnet:9092,kafka1013.eqiad.wmnet:9092,...
#
# [*script*]
#   Path to camus wrapper script.  This is currently deployed with the refinery
#   source. You must include role::analytics_cluster::refinery if you don't
#   override this to a custom path.
#   See: https://github.com/wikimedia/analytics-refinery/blob/master/bin/camus
#
# [*user*]
#   The camus cron will be run by this user.
#
# [*camus_jar*]
#   Path to camus.jar.  Default undef,
#   (/srv/deployment/analytics/refinery/artifacts/camus-wmf.jar)
#
# [*check*]
#   If true, CamusPartitionChecker will be run after the Camus run finishes.
#   Default: undef, (false)
#
# [*check_jar*]
#   Path to jar with CamusPartitionChecker.  This is ignored if
#   $check is false.  Default: undef,
#   (/srv/deployment/analytics/refinery/artifacts/refinery-camus.jar)
#
# [*check_dry_run*]
#   If true, no _IMPORTED flags will be written to HDFS during the CamusPartitionChecker run.
#
# [*check_email_enabled*]
#   If true, any errors encountered by CamusPartitionChecker will be sent as an email report
#   to analytics-alerts@wikimedia.org
#
# [*check_topic_whitelist*]
#   If given, only topics matching this regex will be checked by the CamusPartitionChecker.
#
# [*libjars*]
#    Any additional jar files to pass to Hadoop when starting the MapReduce job.
#
# [*template*]
#   Puppet path to camus.properties ERb template.  Default: camus/${title}.erb
#
# [*template_variables*]
#   Hash of anything you might need accesible in your custom camus.properties
#   ERb template.  You can access these in your template as
#   @template_variables['my_property']
#
# [*hour*]
# [*minute*]
# [*month*]
# [*monthday*]
# [*weekday*]
#
# [*interval*]
#   Systemd interval to use. Format: DayOfWeek Year-Month-Day Hour:Minute:Second
#
# [*environment*]
#  Hash containing 'Environment=' related values to insert in the
#  Systemd unit.
#
# [*monitoring_enabled*]
#  Periodically check the last execution of the unit and alarm if it ended
#  up in a failed state.
#  Default: true
#
# [*ensure*]
#
define camus::job (
    $kafka_brokers,
    $script                 = '/srv/deployment/analytics/refinery/bin/camus',
    $user                   = 'hdfs',
    $camus_jar              = undef,
    $check                  = undef,
    $check_jar              = undef,
    $check_dry_run          = undef,
    $check_email_enabled    = undef,
    $check_topic_whitelist  = undef,
    $libjars                = undef,
    $template               = "camus/${title}.erb",
    $template_variables     = {},
    $hour                   = undef,
    $minute                 = undef,
    $month                  = undef,
    $monthday               = undef,
    $weekday                = undef,
    $interval               = undef,
    $environment            = undef,
    $monitoring_enabled     = true,
    $ensure                 = 'present',
)
{
    require ::camus

    $properties_file = "${camus::config_directory}/${title}.properties"
    $log_file        = "${camus::log_directory}/${title}.log"

    file { $properties_file:
        content => template($template),
    }

    $camus_jar_opt = $camus_jar ? {
        undef   => '',
        default => "--jar ${camus_jar}",
    }

    $libjars_opt = $libjars ? {
        undef   => '',
        default => "--libjars ${libjars}",
    }

    $check_jar_opt = $check_jar ? {
        undef   => '',
        default => "--check-jar ${check_jar} ",
    }
    $check_dry_run_opt = $check_dry_run ? {
        true    => '--check-dry-run ',
        default => '',
    }
    $check_email_enabled_opt = $check_email_enabled ? {
        true    => '--check-emails-to analytics-alerts@wikimedia.org ',
        default => '',
    }
    $check_topic_whitelist_opt = $check_topic_whitelist ? {
        undef   => '',
        default => "--check-java-opts '-Dkafka.whitelist.topics=\"${check_topic_whitelist}\"' ",
    }

    $check_opts = $check ? {
        undef   => '',
        default => "--check ${check_jar_opt}${check_dry_run_opt}${check_email_enabled_opt}${check_topic_whitelist_opt}",
    }

    $command = "${script} --run --job-name camus-${title} ${camus_jar_opt} ${libjars_opt} ${check_opts} ${properties_file} >> ${log_file} 2>&1"

    if $interval {
        $cron_ensure = absent
    } else {
        $cron_ensure = $ensure
    }

    cron { "camus-${title}":
        ensure   => $cron_ensure,
        command  => $command,
        user     => $user,
        hour     => $hour,
        minute   => $minute,
        month    => $month,
        monthday => $monthday,
        weekday  => $weekday,
        require  => File[$properties_file],
    }

    if $interval {
        $unit_command = "${script} --run --job-name camus-${title} ${camus_jar_opt} ${libjars_opt} ${check_opts} ${properties_file}"

        systemd::timer::job { "camus-${title}":
            description               => "Hadoop Map-Reduce Camus job for ${title}",
            command                   => $unit_command,
            interval                  => {
                'start'    => 'OnCalendar',
                'interval' => $interval
            },
            user                      => $user,
            environment               => $environment,
            monitoring_enabled        => $monitoring_enabled,
            monitoring_contact_groups => 'analytics',
            logging_enabled           => true,
            logfile_basedir           => $camus::log_directory,
            logfile_name              => "${title}.log",
            logfile_owner             => $user,
            logfile_group             => $user,
            logfile_perms             => 'all',
            syslog_force_stop         => true,
            syslog_identifier         => "camus-${title}",
        }
    }
}
