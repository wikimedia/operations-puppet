# Compound role for the Kafka "main" cluster
class role::kafka::main {

    include profile::firewall
    include profile::kafka::broker

    if $::realm == 'production' {
        # Mirror eqiad.* topics from main-eqiad into main-codfw,
        # or mirror codfw.* topics from main-codfw into main-eqiad.
        include profile::kafka::mirror
        include profile::kafka::mirror::alerts
    }

    include profile::base::production
}
