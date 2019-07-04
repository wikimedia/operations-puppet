# == Class: profile::graphite::alerts
#
# Install icinga alerts on graphite metrics.
# NOTE to be included only from one host, icinga will generate different alerts
# for all hosts that include this class.
#
class profile::graphite::alerts($graphite_url = hiera('graphite_url')) {

    include ::graphite::monitoring::graphite

    Monitoring::Graphite_threshold {
        graphite_url => $graphite_url
    }

    # Eventlogging
    #   Warn/Alert if the db inserts of EventLogging data have dropped dramatically
    #   Since the MySQL consumer is at the bottom of the pipeline
    #   this metric is a good proxy to make sure events are flowing through the
    #   kafka pipeline
    monitoring::graphite_threshold { 'eventlogging_overall_inserted_rate':
        description     => 'EventLogging overall insertion rate from MySQL consumer',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/eventlogging?panelId=12&fullscreen&orgId=1'],
        metric          => 'movingAverage(eventlogging.overall.inserted.rate, "10min")',
        warning         => 50,
        critical        => 10,
        percentage      => 20, # At least 3 of the (25 - 10) = 15 readings
        from            => '25min',
        until           => '10min',
        contact_group   => 'analytics',
        under           => true,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/EventLogging/Administration#Mysql_insertion_rate_dropping_to_zero_due_to_db_failures',
    }

    # Monitor memcached error rate from MediaWiki. This is commonly a sign of
    # a failing nutcracker instance that can be tracked down via
    # https://logstash.wikimedia.org/#/dashboard/elasticsearch/memcached
    monitoring::graphite_threshold { 'mediawiki-memcached-threshold':
        description     => 'MediaWiki memcached error rate',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/mediawiki-graphite-alerts?orgId=1&panelId=1&fullscreen'],
        metric          => 'transformNull(logstash.rate.mediawiki.memcached.ERROR.sum, 0)',
        # Nominal error rate in production is <150/min
        warning         => 1000,
        critical        => 5000,
        from            => '5min',
        percentage      => 40,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Memcached',
    }

    # Monitor MediaWiki fatals and exceptions.
    monitoring::graphite_threshold { 'mediawiki_error_rate':
        description     => 'MediaWiki exceptions and fatals per minute',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/mediawiki-graphite-alerts?orgId=1&panelId=2&fullscreen'],
        metric          => 'transformNull(sumSeries(logstash.rate.mediawiki.fatal.ERROR.sum, logstash.rate.mediawiki.exception.ERROR.sum), 0)',
        warning         => 25,
        critical        => 50,
        from            => '10min',
        percentage      => 70,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Application_servers',
    }

    # Monitor MediaWiki session failures
    # See https://grafana.wikimedia.org/dashboard/db/edit-count
    monitoring::graphite_threshold { 'mediawiki_session_loss':
        description     => 'MediaWiki edit session loss',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/edit-count?panelId=13&fullscreen&orgId=1'],
        metric          => 'transformNull(scale(consolidateBy(MediaWiki.edit.failures.session_loss.rate, "max"), 60), 0)',
        warning         => 10,
        critical        => 50,
        from            => '15min',
        percentage      => 30,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Application_servers',
    }

    monitoring::graphite_threshold { 'mediawiki_bad_token':
        description     => 'MediaWiki edit failure due to bad token',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/edit-count?panelId=13&fullscreen&orgId=1'],
        metric          => 'transformNull(scale(consolidateBy(MediaWiki.edit.failures.bad_token.rate, "max"), 60), 0)',
        warning         => 10,
        critical        => 50,
        from            => '15min',
        percentage      => 30,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Application_servers',
    }

    # Monitor MediaWiki CentralAuth bad tokens
    monitoring::graphite_threshold { 'mediawiki_centralauth_errors':
        description     => 'MediaWiki centralauth errors',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/mediawiki-graphite-alerts?orgId=1&panelId=3&fullscreen'],
        metric          => 'transformNull(sumSeries(MediaWiki.centralauth.centrallogin_errors.*.rate), 0)',
        warning         => 0.5,
        critical        => 1,
        from            => '15min',
        percentage      => 30,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Application_servers',
    }

    # Monitor EventBus 4xx and 5xx HTTP response rate.
    monitoring::graphite_threshold { 'eventbus_http_error_rate':
        description     => 'EventBus HTTP Error Rate (4xx + 5xx)',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/eventbus?panelId=1&fullscreen&orgId=1'],
        metric          => 'transformNull(sumSeries(eventbus.counters.eventlogging.service.EventHandler.POST.[45]*.rate))',
        # If > 50% of datapoints over last 10 minutes is over thresholds, then alert.
        warning         => 1,
        critical        => 10,
        from            => '10min',
        percentage      => 50,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventBus',
    }

    # Percent difference in the number of thumbs between eqiad and codfw
    monitoring::graphite_threshold { 'swift_thumbs_eqiad_codfw_diff':
        description     => 'Number of thumbnails in eqiad greater than codfw',
        dashboard_links => ['https://grafana.wikimedia.org/d/OPgmB1Eiz/swift?var-DC=eqiad&var-prometheus=eqiad%20prometheus%2Fops'],
        metric          => 'divideSeries(keepLastValue(swift.eqiad-prod.containers.mw-media.thumb.objects, 20), keepLastValue(swift.codfw-prod.containers.mw-media.thumb.objects, 20))',
        warning         => 1.02,
        critical        => 1.05,
        from            => '90min',
        percentage      => 80,
        check_interval  => 30,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventBus',
    }
    monitoring::graphite_threshold { 'swift_thumbs_codfw_eqiad_diff':
        description     => 'Number of thumbnails in codfw greater than eqiad',
        dashboard_links => ['https://grafana.wikimedia.org/d/OPgmB1Eiz/swift?var-DC=codfw&var-prometheus=codfw%20prometheus%2Fops'],
        metric          => 'divideSeries(keepLastValue(swift.codfw-prod.containers.mw-media.thumb.objects, 20), keepLastValue(swift.eqiad-prod.containers.mw-media.thumb.objects, 20))',
        warning         => 1.02,
        critical        => 1.05,
        from            => '90min',
        percentage      => 80,
        check_interval  => 30,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventBus',
    }
}
