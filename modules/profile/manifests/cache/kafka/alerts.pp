# == Class: profile::analytics::alerts
#
# Monitoring Analytics graphite aggregated alarms.
#
class profile::cache::kafka::alerts {

    # Generate an alert if too many delivery report errors per second
    # (logster only reports once a minute, but we can use perSecond() in graphite
    # over a period of time of X minutes).
    # Currently monitored:
    # varnishkafka-webrequest in text/upload
    # varnishkafka-eventlogging in text
    # varnishkafka-statsd in text
    #
    # These alarms will be probably removed after https://phabricator.wikimedia.org/T196066
    # in favor of Prometheus based ones.

    monitoring::graphite_threshold { 'varnishkafka-webrequest-text-kafka_drerr':
        ensure          => 'present',
        description     => 'cache_text: Varnishkafka Webrequest Delivery Errors per second',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/varnishkafka?panelId=20&fullscreen&orgId=1&var-instance=webrequest&var-host=All'],
        metric          => 'sumSeries(perSecond(varnishkafka.*.webrequest.text.varnishkafka.kafka_drerr))',
        warning         => 1,
        critical        => 5,
        from            => '10min',
        retry_interval  => 1,
        retries         => 3,
        contact_group   => 'admins,analytics',
    }

    monitoring::graphite_threshold { 'varnishkafka-eventlogging-text-kafka_drerr':
        ensure          => 'present',
        description     => 'Varnishkafka Eventlogging Delivery Errors per second',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/varnishkafka?panelId=20&fullscreen&orgId=1&var-instance=eventlogging&var-host=All'],
        metric          => 'sumSeries(perSecond(varnishkafka.*.eventlogging.text.varnishkafka.kafka_drerr))',
        warning         => 1,
        critical        => 5,
        from            => '10min',
        retry_interval  => 1,
        retries         => 3,
        contact_group   => 'admins,analytics',
    }

    monitoring::graphite_threshold { 'varnishkafka-statsv-text-kafka_drerr':
        ensure          => 'present',
        description     => 'Varnishkafka Statsv Delivery Errors per second',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/varnishkafka?panelId=20&fullscreen&orgId=1&var-instance=statsv&var-host=All'],
        metric          => 'sumSeries(perSecond(varnishkafka.*.statsv.text.varnishkafka.kafka_drerr))',
        warning         => 1,
        critical        => 5,
        from            => '10min',
        retry_interval  => 1,
        retries         => 3,
        contact_group   => 'admins,analytics',
    }

    monitoring::graphite_threshold { 'varnishkafka-webrequest-upload-kafka_drerr':
        ensure          => 'present',
        description     => 'cache_upload: Varnishkafka Webrequest Delivery Errors per second',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/varnishkafka?panelId=20&fullscreen&orgId=1&var-instance=webrequest&var-host=All'],
        metric          => 'sumSeries(perSecond(varnishkafka.*.webrequest.upload.varnishkafka.kafka_drerr))',
        warning         => 1,
        critical        => 5,
        from            => '10min',
        retry_interval  => 1,
        retries         => 3,
        contact_group   => 'admins,analytics',
    }
}
