# == Class: role::logstash::sentry
#
# Configure Logstah to send PHP errors to Sentry
#
class role::logstash::sentry {
    include ::role::logstash

    logstash::output::sentry { $topic:
        dsn => hiera('sentry::dsn'),
    }

#    logstash::conf { 'filter_sentry':
#        source   => 'puppet:///files/logstash/filter-sentry.conf',
#        priority => 70,
#    }
}
