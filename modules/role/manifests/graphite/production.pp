class role::graphite::production {
    include ::standard
    include ::profile::base::firewall
    include ::profile::backup::host
    include ::profile::statsd # all graphite hosts also include statsd
    include ::profile::graphite::production
}
