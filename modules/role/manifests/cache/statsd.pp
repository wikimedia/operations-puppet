# == Class role::cache::statsd
# Installs a daemon that accumulates stats from the varnish SHM log
# and forwards them to StatsD.
class role::cache::statsd {
    ::varnish::logging::statsd { 'default':
        statsd_server => 'statsd.eqiad.wmnet',
        key_prefix    => "varnish.${::site}.backends",
    }

}

# == Class role::cache::statsd::xcps
# Installs a daemon that accumulates client connection stats
# from the varnish SHM log and forwards them to StatsD.
class role::cache::statsd::xcps {
    ::varnish::logging::xcps { 'xcps':
        statsd_server => 'statsd.eqiad.wmnet',
    }
}
