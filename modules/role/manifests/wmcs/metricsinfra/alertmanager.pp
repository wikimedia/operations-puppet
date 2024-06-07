class role::wmcs::metricsinfra::alertmanager {
    include profile::wmcs::metricsinfra::alertmanager
    include profile::wmcs::metricsinfra::alertmanager::ack
    include profile::wmcs::metricsinfra::alertmanager::irc
    include profile::wmcs::metricsinfra::alertmanager::karma
    include profile::wmcs::metricsinfra::alertmanager::api_rw_proxy
    include profile::wmcs::metricsinfra::prometheus_configurator
}
