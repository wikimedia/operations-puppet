
# Role class for changeprop
class role::changeprop {

    # NOTE: Doing a hiera lookup on purpose instead of the implicit one in order
    # to force the key. Also as a note to revisit this and
    # role::kafka::main::config in order to tidy them up and not have to compose
    # role classes which can turn out to be messy
    $zk_uri = hiera('zookeeper_url')

    system::role { 'role::changeprop':
        description => 'propagates events from the EventBus',
    }

    class { '::changeprop':
        zk_uri => $zk_uri,
    }

}

