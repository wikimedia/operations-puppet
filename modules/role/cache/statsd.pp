# == Class role::cache::statsd
# Installs a local statsd instance for aggregating and serializing
# stats before sending them off to a remote statsd instance.
class role::cache::statsd {
    class { '::txstatsd::decommission': }
    include role::statsite
}
