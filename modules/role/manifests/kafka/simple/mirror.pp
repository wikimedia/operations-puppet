# == Class role::kafka::simple::mirror
# This is useful for testing Kafka MirrorMaker in labs.
#
class role::kafka::simple::mirror {
    system::role { 'role::kafka::simple::mirror':
        description => "Kafka simple MirrorMaker instance"
    }

    # include profile::kafka::mirrors
    include profile::kafka::mirror
}
