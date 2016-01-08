# == Class: role::logstash::sentry
#
# Configure Logstash to send PHP errors to Sentry
#
class role::logstash::sentry {
    include ::role::logstash

    logstash::output::sentry { 'sometopic':
        dsn => hiera('sentry::dsn'),
    }

#    logstash::conf { 'filter_sentry':
#        source   => 'puppet:///files/logstash/filter-sentry.conf',
#        priority => 70,
#    }
}
