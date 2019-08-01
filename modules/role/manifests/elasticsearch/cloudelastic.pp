# = Class: role::elasticsearch::cloudelastic
#
# This class sets up Elasticsearch specifically for CirrusSearch on cloudelastic nodes.
#
class role::elasticsearch::cloudelastic {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::elasticsearch::cirrus
    include ::profile::elasticsearch::monitor::base_checks

    # This clearly isn't the intended "right" way to use the latest factorings
    # of LVS realserver config, but I can't figure out how to make them work
    # for this case, either :P
    include ::lvs::configuration # lint:ignore:wmf_styleguide
    class { '::lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['cloudelastic'][$::site],
    }

    # To be enabled after elasticsearch is setup as kafka topic has not been created
    #include ::profile::mjolnir::kafka_bulk_daemon

    system::role { 'elasticsearch::cloudelastic':
        ensure      => 'present',
        description => 'elasticsearch cloud elastic cirrus',
    }
}
