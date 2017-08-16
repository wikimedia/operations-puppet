# Role class for changeprop
#
# filtertags: labs-project-deployment-prep
class role::changeprop {

    include ::passwords::redis
    $kafka_config = kafka_config('main')

    system::role { 'changeprop':
        description => 'propagates events from the EventBus',
    }

    class { '::changeprop':
        broker_list         => $kafka_config['brokers']['string'],
        redis_pass          => $::passwords::redis::main_password,
        # FIXME: this needs to be refactored when the role
        # is moved to profiles.
        kafka_msg_max_bytes => hiera('kafka_message_max_bytes', 1048576),
    }

}
