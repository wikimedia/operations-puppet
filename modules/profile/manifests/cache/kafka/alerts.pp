# == Class: profile::cache::kafka::alerts
#
# Monitoring Varnishkafka prometheus aggregate metrics.
#
class profile::cache::kafka::alerts {

    # Generate an alert if too many delivery report errors per second
    #
    # Currently monitored:
    # varnishkafka-webrequest in text/upload
    # varnishkafka-eventlogging in text
    # varnishkafka-statsv in text

    profile::cache::kafka::varnishkafka_delivery_alert { 'varnishkafka-alert-webrequest-text':
        cache_segment => 'text',
        instance      => 'webrequest',
    }

    profile::cache::kafka::varnishkafka_delivery_alert { 'varnishkafka-alert-eventlogging-text':
        cache_segment => 'text',
        instance      => 'eventlogging',
    }

    profile::cache::kafka::varnishkafka_delivery_alert { 'varnishkafka-alert-statsv-text':
        cache_segment => 'text',
        instance      => 'statsv',
    }

    # Varnishkafka - Cache upload
    profile::cache::kafka::varnishkafka_delivery_alert { 'varnishkafka-alert-webrequest-upload':
        cache_segment => 'upload',
        instance      => 'webrequest',
    }
}
