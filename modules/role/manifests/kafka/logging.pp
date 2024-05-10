class role::kafka::logging {
    include profile::firewall
    include profile::base::production
    include profile::kafka::broker
}
