# == Class role::analytics_cluster::refinery::job::json_refine
# Install cron jobs for Spark JsonRefine jobs.  These jobs
# refine JSON data imported into Hadoop from Kafka using Camus into
# Parquet backed Hive tables.
#
class role::analytics_cluster::refinery::job::json_refine {
    require ::role::analytics_cluster::refinery

    # Refine EventLogging Analytics (capsule based) data.
    role::analytics_cluster::refinery::job::json_refine_job { 'eventlogging_analytics':
        input_base_path => '/wmf/data/raw/eventlogging',
        input_regex     => 'eventlogging_(.+)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)',
        input_capture   => 'table,year,month,day,hour',
        output_base_path => '/wmf/data/event',
        output_database => 'event',
        table_blacklist => '^Edit|ChangesListHighlights$',
        minute          => 20,
    }

    # Refine EventBus data.
    role::analytics_cluster::refinery::job::json_refine_job { 'eventlogging_eventbus':
        input_base_path  => '/wmf/data/raw/eventbus',
        # 'datacenter' is extracted from the input path into a Hive table partition
        input_regex      => '.*(eqiad|codfw)_(.+)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)',
        input_capture    => 'datacenter,table,year,month,day,hour',
        output_base_path => '/wmf/data/event',
        output_database  => 'event',
        minute           => 10,
    }
}
