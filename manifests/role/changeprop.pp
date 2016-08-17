
# Role class for changeprop
class role::changeprop {

    $kafka_config = kafka_config('main')

    system::role { 'role::changeprop':
        description => 'propagates events from the EventBus',
    }

    class { '::changeprop':
        broker_list => $kafka_config['brokers']['string'],
    }

}

