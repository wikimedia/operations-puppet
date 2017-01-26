# == Define camus::job
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
define camus::job (
    $kafka_brokers,
    $script             = '/srv/deployment/analytics/refinery/bin/camus',
    $user               = 'hdfs',
    $camus_jar          = undef,
    $check              = undef,
    $check_jar          = undef,
    $libjars            = undef,
    $template           = "camus/${title}.erb",
    $template_variables = {},
    $hour               = undef,
    $minute             = undef,
    $month              = undef,
    $monthday           = undef,
    $weekday            = undef,
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

    $check_opt = $check ? {
        undef   => '',
        default => $check_jar ? {
            undef   => '--check',
            default => "--check --check-jar ${check_jar}",
        }
    }

    $command = "${script} --run --job-name camus-${title} ${camus_jar_opt} ${libjars_opt} ${check_opt} ${properties_file} >> ${log_file} 2>&1"

    cron { "camus-${title}":
        command  => $command,
        user     => $user,
        hour     => $hour,
        minute   => $minute,
        month    => $month,
        monthday => $monthday,
        weekday  => $weekday,
        require  => File[$properties_file],
    }
}
