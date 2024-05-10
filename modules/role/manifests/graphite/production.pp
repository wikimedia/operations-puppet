class role::graphite::production {
    include profile::base::production
    include profile::firewall
    include profile::backup::host
    include profile::statsd # all graphite hosts also include statsd
    include profile::graphite::production
    include profile::tlsproxy::envoy # TLS termination
    include profile::netconsole::client
}
