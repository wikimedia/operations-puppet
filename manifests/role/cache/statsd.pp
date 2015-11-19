# == Class role::cache::statsd
# Installs a daemon that accumulates stats from the varnish SHM log
# and forwards them to StatsD.
class role::cache::statsd {
    ::varnish::logging::statsd { 'default':
        statsd_server => 'statsd.eqiad.wmnet',
        key_prefix    => "varnish.${::site}.backends",
    }

}

# == Class role::cache::statsd::frontend
# Installs daemons that accumulates frontend-role-specific stats
# from the varnish SHM log and forwards them to StatsD.
class role::cache::statsd::frontend {
    # Client connection stats from the 'X-Connection-Properties'
    # header set by the SSL terminators.
    ::varnish::logging::xcps { 'xcps':
        statsd_server => 'statsd.eqiad.wmnet',
    }

    # ResourceLoader browser cache hit rate and request volume stats.
    ::varnish::logging::rls { 'rls':
        statsd_server => 'statsd.eqiad.wmnet',
    }
}
