# Compound role for the Kafka "main" cluster
class role::kafka::main {

    if $::realm == 'production' {
        include ::role::kafka::main::broker
    }
    # Test in labs, update deployment-prep there.
    else {
        include profile::kafka::mirror
    }

    include ::role::eventbus::eventbus

    # Mirror eqiad.* topics from main-eqiad into main-codfw,
    # or mirror codfw.* topics from main-codfw into main-eqiad.
    include ::profile::kafka::mirror

    include ::standard
}
