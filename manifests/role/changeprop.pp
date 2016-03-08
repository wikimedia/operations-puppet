
# Role class for changeprop
class role::changeprop {

    require ::role::kafka::main::config

    system::role { 'role::changeprop':
        description => 'propagates events from the EventBus',
    }

    class { '::changeprop':
        zk_uri => $::role::kafka::main::config::zookeeper_url,
    }

}

