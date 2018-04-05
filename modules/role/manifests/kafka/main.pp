# Compound role for the Kafka "main" cluster
class role::kafka::main {
    include ::role::kafka::main::broker

    include ::role::eventbus::eventbus

    # Mirror eqiad.* topics from main-eqiad into main-codfw,
    # or mirror codfw.* topics from main-codfw into main-eqiad.

    # Temporarily only use the new mirror maker profile when mirroring from codfw -> eqiad
    # to make sure this works before we enable everywhere.
    # T190940
    if $::site == 'eqiad' {
        include ::profile::kafka::mirror
    }
    else {
        include ::role::kafka::main::mirror
    }

    include ::standard
}
