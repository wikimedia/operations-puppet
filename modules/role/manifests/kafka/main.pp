# Compound role for the Kafka "main" cluster
class role::kafka::main {
    if $::site == 'eqiad' {
       include ::role::kafka::main::broker
    }
    else {
        include ::profile::kafka::broker
    }

    include ::role::eventbus::eventbus

    if $::realm == 'production' {
        # Mirror eqiad.* topics from main-eqiad into main-codfw,
        # or mirror codfw.* topics from main-codfw into main-eqiad.
        include ::profile::kafka::mirror
    }

    include ::standard
}
