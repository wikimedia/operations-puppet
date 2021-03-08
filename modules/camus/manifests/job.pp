# == Define camus::job
#
# Renders a camus.properties template and installs a
# systemd timer to launch a Camus MapReduce job in Hadoop.
#
# == Parameters
# [*kafka_brokers*]
#   Comma separated list of Kafka Broker addresses, e.g.
#   kafka1012.eqiad.wmnet:9092,kafka1013.eqiad.wmnet:9092,...
#
# [*camus_properties*]
#   Extra properties to render into the camus.properties file.
#
# [*hadoop_cluster_name*]
#   Used to set default values for some camus HDFS path properties.
#   Default: analytics-hadoop
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
# [*camus_name*]
#   Name of the camus job.  This will be used for default values for
#   camus history path and kafka client name.
#   Default: $title-00
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
# [*check_email_target*]
#   If not undef, any errors encountered by CamusPartitionChecker will be sent as an email report
#   to the email address provided as input.
#
# [*check_java_opts*]
#   Any job overrides you might want to provide to CamusPartionChecker.  You can use this
#   to override any of the Camus properties used by the Camus import job that you might
#   want different for CamusPartitionChecker, e.g. kafka.whitelist.topics or
#   eventstreamconfig.settings_filters.  Example:
#     check_java_opts => '-Deventstreamconfig.settings_filters=destination_event_stream:eventgate-analytics,canary_events_enabled:true'
#
# [*libjars*]
#    Any additional jar files to pass to Hadoop when starting the MapReduce job.
#
# [*http_proxy_host*]
#    If set, jobs will be configured to use an HTTP proxy.
#    Useful if you are using remote eventstreamconfig.
#    Default: undef
#
# [*http_proxy_port*]
#   Default: 8080
#
# [*template*]
#   Puppet path to camus.properties.erb template.  Default: camus/camus.properties.erb
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
    $camus_properties           = {},
    $hadoop_cluster_name        = 'analytics-hadoop',
    $script                     = '/srv/deployment/analytics/refinery/bin/camus',
    $user                       = 'analytics',
    $camus_name                 = "${title}-00",
    $camus_jar                  = undef,
    $check                      = undef,
    $check_jar                  = undef,
    $check_dry_run              = undef,
    $check_email_target         = undef,
    $check_java_opts            = undef,
    $libjars                    = undef,
    $http_proxy_host            = undef,
    $http_proxy_port            = 8080,
    $template                   = 'camus/camus.properties.erb',
    $interval                   = undef,
    $environment                = undef,
    $monitoring_enabled         = true,
    $ensure                     = 'present',
)
{
    require ::camus

    $default_properties = {
        'mapreduce.job.queuename'             => 'default',
        # final top-level data output directory, sub-directory will be dynamically created for each topic pulled
        'etl.destination.path'                => "hdfs://${hadoop_cluster_name}/wmf/data/raw/${title}",
        # Allow overwrites of previously imported files in etl.destination.path
        'etl.destination.overwrite'           => true,
        # HDFS location where you want to keep execution files, i.e. offsets, error logs, and count files
        'etl.execution.base.path'             => "hdfs://${hadoop_cluster_name}/wmf/camus/${camus_name}",
        # where completed Camus job output directories are kept, usually a sub-dir in the base.path
        'etl.execution.history.path'          => "hdfs://${hadoop_cluster_name}/wmf/camus/${camus_name}/history",
        # ISO-8601 timestamp like 2013-09-20T15:40:17Z
        'camus.message.timestamp.format'      => 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'',
        # use the dt field
        'camus.message.timestamp.field'       => 'dt',
        # Store output into hourly buckets
        'etl.output.file.time.partition.mins' => '60',
        # records are delimited by newline
        'etl.output.record.delimiter'         => '\\n',
        # Concrete implementation of the Decoder class to use
        'camus.message.decoder.class'         => 'com.linkedin.camus.etl.kafka.coders.JsonStringMessageDecoder',
        # SequenceFileRecordWriterProvider writes the records as Hadoop Sequence files
        # so that they can be split even if they are compressed.  We Snappy compress these
        # by setting mapreduce.output.fileoutputformat.compress.codec to SnappyCodec
        # in /etc/hadoop/conf/mapred-site.xml.
        'etl.record.writer.provider.class'    => 'com.linkedin.camus.etl.kafka.common.SequenceFileRecordWriterProvider',
        # Disable speculative map tasks.
        # There is no need to consume the same data from Kafka multiple times.
        'mapreduce.map.speculative'           => false,
        # Set this to at least the number of topic/partitions you will be importing.
        # Max hadoop tasks to use, each task can pull multiple topic partitions.
        'mapred.map.tasks'                    => '10',
        # Connection parameters.
        'kafka.brokers'                       => $kafka_brokers,
        # max historical time that will be pulled from each partition based on event timestamp
        #  Note:  max.pull.hrs doesn't quite seem to be respected here.
        #  This will take some more sleuthing to figure out why, but in our case
        #  here its ok, as we hope to never be this far behind in Kafka messages to
        #  consume.
        'kafka.max.pull.hrs'                  => '168',
        # events with a timestamp older than this will be discarded.
        'kafka.max.historical.days'           => '7',
        # Max minutes for each mapper to pull messages (-1 means no limit)
        # Let each mapper run for no more than this.
        # Camus creates hourly directories, and we don't want a single
        # long running mapper keep other Camus jobs from being launched.
        # You should set this to something just short of the interval at which you run this job.
        'kafka.max.pull.minutes.per.task'     => '55',
        # If whitelist has values, only whitelisted topic are pulled.  nothing on the blacklist is pulled
        #'kafka.blacklist.topics'              => '',
        # These are the kafka topics camus brings to HDFS.
        # If this is unset, eventstreamconfig.* may be used to discover topics.
        #'kafka.whitelist.topics'              => '',
        # Name of the client as seen by kafka
        'kafka.client.name'                   => "camus-${camus_name}",
        # Fetch Request Parameters
        #kafka.fetch.buffer.size=
        #kafka.fetch.request.correlationid=
        #kafka.fetch.request.max.wait=
        #kafka.fetch.request.min.bytes=
        'kafka.client.buffer.size'            => '20971520',
        'kafka.client.so.timeout'             => '60000',
        # If camus offsets and kafka offsets mismatch
        # then camus should start from the earliest offset.
        # NOTE: This only works if camus actually has offsets stored for a topic partition.
        # If it does not, it will always move to earliest, unless the topic is explicitly
        # listed in kafka.move.to.last.offset.list.
        'kafka.move.to.earliest.offset'       => true,
        # If a topic is in this list, its offsets will be forceably moved to the latest offset.
        # You probably shouldn't set this in a job config, but use it for camus job migration
        # tasks manually.
        #kafka.move.to.last.offset.list=
        # If set (and kafka.whitelist.topics is not set), topics will be looked up from this
        # EventStreamConfig MW API.
        #'eventstreamconfig.uri'               => 'https://meta.wikimedia.org/w/api.php'
        # If set, only topics for these streams will be ingested.
        #'eventstreamconfig.stream_names'      => undef
        # If set, only topics for streams that have configs that match these settings will be ingested.
        #'eventstreamconfig.settings_filters'  => undef
        # Controls the submitting of counts to Kafka
        # Default value set to true
        'post.tracking.counts.to.kafka'       => false,
        # Stops the mapper from getting inundated with Decoder exceptions for the same topic
        # Default value is set to 10
        'max.decoder.exceptions.to.print'     => '5',
        'log4j.configuration'                 => false,
        'etl.run.tracking.post'               => false,
        #kafka.monitor.tier=
        'kafka.monitor.time.granularity'      => '10',
        'etl.hourly'                          => 'hourly',
        'etl.daily'                           => 'daily',
        'etl.ignore.schema.errors'            => false,
        # WMF relies on the relevant Hadoop properties for this,
        # not Camus' custom properties.
        #   i.e.  mapreduce.output.compression* properties
        # # configure output compression for deflate or snappy. Defaults to deflate.
        # etl.output.codec=deflate
        # etl.deflate.level=6
        # #etl.output.codec=snappy
        'etl.default.timezone'                => 'UTC',
        'etl.keep.count.files'                => false,
        # 'etl.counts.path'                   => '',
        'etl.execution.history.max.of.quota'  => '.8',
    }

    # Each key=value here will be the content of the camus properties file.
    $template_properties = merge($default_properties, $camus_properties)

    # Make sure this camus job will at least attempt to limit the topics it is importing.
    if (
        !$template_properties['kafka.whitelist.topics'] and
        !(
            $template_properties['eventstreamconfig.uri'] and
            ($template_properties['eventstreamconfig.stream_names'] or $template_properties['eventstreamconfig.settings_filters'])
        )
    ) {
        fail("camus::job ${title} does not have camus_properties that will get a safe list of Kafka topics. Must set either kafka.whitelist.topics or eventstreamconfig.uri and either eventstreamconfig.stream_names or eventstreamconfig.settings_filters.")
    }

    $properties_file = "${camus::config_directory}/${title}.properties"
    $properties_content = $ensure ? {
        'present' => template($template),
        default   => '',
    }

    file { $properties_file:
        ensure  => $ensure,
        content => $properties_content,
    }

    $camus_jar_opt = $camus_jar ? {
        undef   => '',
        default => "--jar ${camus_jar}",
    }

    $libjars_opt = $libjars ? {
        undef   => '',
        default => "--libjars ${libjars}",
    }

    if $http_proxy_host {
        # CamusPartitionChecker runs as a local Java process, we'll need to manually
        # place these opts on its java command.
        $http_proxy_java_opts = " -Dhttp.proxyHost=${http_proxy_host} -Dhttp.proxyPort=${http_proxy_port} -Dhttps.proxyHost=${http_proxy_host} -Dhttps.proxyPort=${http_proxy_port}"
        $http_proxy_environment = {
            # Camus runs as a Hadoop job, and needs these set in HADOOP_OPTS
            # to properly use proxy in the task container.
            'HADOOP_OPTS' => "-Dhttp.proxyHost=${http_proxy_host} -Dhttp.proxyPort=${http_proxy_port} -Dhttps.proxyHost=${http_proxy_host} -Dhttps.proxyPort=${http_proxy_port}"
        }
    } else {
        $http_proxy_java_opts = ''
        $http_proxy_environment = {}
    }

    $check_jar_opt = $check_jar ? {
        undef   => '',
        false   => '',
        default => "--check-jar ${check_jar} ",
    }
    $check_dry_run_opt = $check_dry_run ? {
        true    => '--check-dry-run ',
        false   => '',
        default => '',
    }
    $check_email_enabled_opt = $check_email_target ? {
        undef   => '',
        false   => '',
        default => "--check-emails-to ${check_email_target} ",
    }

    if $check_java_opts or $http_proxy_java_opts {
        $check_java_opt = $check_java_opts ? {
            undef   => "--check-java-opts '${http_proxy_java_opts}'",
            default => "--check-java-opts '${check_java_opts}${http_proxy_java_opts}' ",
        }
    } else {
        $check_java_opt = ''
    }

    $check_opts = $check ? {
        undef   => '',
        false   => '',
        default => "--check ${check_jar_opt}${check_dry_run_opt}${check_email_enabled_opt}${check_java_opt}",
    }

    $unit_command = "${script} --run --job-name camus-${title} ${camus_jar_opt} ${libjars_opt} ${check_opts} ${properties_file}"

    kerberos::systemd_timer { "camus-${title}":
        ensure                    => $ensure,
        description               => "Hadoop Map-Reduce Camus job for ${title}",
        command                   => $unit_command,
        interval                  => $interval,
        user                      => $user,
        environment               => merge($http_proxy_environment, $environment),
        monitoring_enabled        => $monitoring_enabled,
        monitoring_contact_groups => 'analytics',
        logfile_basedir           => $camus::log_directory,
        logfile_name              => "${title}.log",
        logfile_owner             => $user,
        logfile_group             => $user,
        logfile_perms             => 'all',
        syslog_force_stop         => true,
        syslog_identifier         => "camus-${title}",
    }
}
