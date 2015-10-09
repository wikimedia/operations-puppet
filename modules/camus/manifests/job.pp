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
#   source. You must include role::analytics::refinery if you don't override
#   this to a custom path.
#   See: https://github.com/wikimedia/analytics-refinery/blob/master/bin/camus
#
# [*user*]
#   The camus cron will be run by this user.
#
# [*libjars*]
#    Any additional jar files to pass to Hadoop when starting the MapReduce job.
#
# [*template*]
#   Puppet path to camus.properties ERb template.  Default: camus/{$title}.erb
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
    require camus

    $properties_file = "${camus::config_directory}/${title}.properties"
    $log_file        = "${camus::log_directory}/${title}.log"

    file { $properties_file:
        content => template($template),
    }

    $libjars_opt = $libjars ? {
        undef   => '',
        default => "--libjars ${libjars}",
    }

    $command = "${script} --job-name camus-${title} ${libjars_opt} ${properties_file} >> ${log_file} 2>&1"

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
