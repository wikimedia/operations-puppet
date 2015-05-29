# == Class role::cache::statsd
# Installs a local statsd instance for aggregating and serializing
# stats before sending them off to a remote statsd instance.
class role::cache::statsd {
    if $::hostname == 'cp1048' {
        ::varnish::logging::statsd { 'default':
            statsd_server => 'statsd.eqiad.wmnet',
            metric_prefix => "varnish.${::site}.backends",
        }
    }
}
