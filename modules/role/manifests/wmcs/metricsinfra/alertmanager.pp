class role::wmcs::metricsinfra::alertmanager {
    system::role { $name:
        description => 'CloudVPS monitoring infrastructure alert sender'
    }

    include ::profile::wmcs::metricsinfra::alertmanager
    include ::profile::wmcs::metricsinfra::alertmanager::ack
    include ::profile::wmcs::metricsinfra::alertmanager::irc
    include ::profile::wmcs::metricsinfra::alertmanager::karma
    include ::profile::wmcs::metricsinfra::alertmanager::project_proxy
}
