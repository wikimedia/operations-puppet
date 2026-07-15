# Compound role for the Kafka "main" cluster
class role::kafka::main {

    include profile::firewall
    include profile::kafka::broker

    if $::realm == 'production' {
        # TODO: Move it to the alerts repo.
        include profile::kafka::mirror::alerts
    }

    include profile::base::production
}
