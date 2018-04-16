# Compound role for the Kafka "main" cluster
class role::kafka::main {
    include ::role::kafka::main::broker

    include ::role::eventbus::eventbus

    # Mirror eqiad.* topics from main-eqiad into main-codfw,
    # or mirror codfw.* topics from main-codfw into main-eqiad.
    include ::profile::kafka::mirror

    include ::standard
}
