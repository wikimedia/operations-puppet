# Compound role for the Kafka "main" cluster
class role::kafka::main {
    include ::role::kafka::main::broker
    # Mirror eqiad.* topics from main-eqiad into main-codfw,
    # or mirror codfw.* topics from main-codfw into main-eqiad.
    include ::role::kafka::main::mirror
    include ::role::eventbus::eventbus

    include ::standard
}
