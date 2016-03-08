
# == Class: changeprop
#
# This class installs and configures the change propagation service, a part of
# the EventBus system responsible for reacting to events received via Kafka and
# dispatching the appropriate requests.
#
class changeprop() {

    require ::role::kafka::main::config

    $zk_uri = $::role::kafka::main::config::zookeeper_url

    service::node { 'changeprop':
        port            => 7272,
        config          => template('changeprop/config.yaml.erb'),
        healthcheck_url => '',
        has_spec        => true,
    }

}
