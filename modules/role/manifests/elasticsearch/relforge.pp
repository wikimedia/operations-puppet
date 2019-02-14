# = Class: role::elasticsearch::relforge
#
# This class sets up Elasticsearch for relevance forge.
#
class role::elasticsearch::relforge {
    include ::standard
    include ::profile::base::firewall
    include ::profile::elasticsearch::cirrus
    include ::elasticsearch::nagios::check
    include ::profile::mjolnir::kafka_msearch_daemon

    system::role { 'elasticsearch::relforge':
        ensure      => 'present',
        description => 'elasticsearch relforge',
    }

    # the relforge cluster is serving labs, it should never be connected from
    # production, except from mwmaint hosts to import production indices.
    $maintenance_hosts = join($network::constants::special_hosts['production']['maintenance_hosts'], ' ')

    ::ferm::service {
        default:
            ensure => present,
            proto  => 'tcp',
            port   => '9243',
            srange => "(${maintenance_hosts})",
        ;
        'elastic-main-https-mwmaint-9243':
            port   => '9243',
        ;
        'elastic-small-alpha-https-mwmaint-9443':
            port   => '9443',
        ;
    }

}
