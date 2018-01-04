# = Class: role::elasticsearch::relforge
#
# This class sets up Elasticsearch for relevance forge.
#
class role::elasticsearch::relforge {
    include ::standard
    include ::base::firewall
    include ::profile::elasticsearch
    include ::profile::prometheus::elasticsearch_exporter
    include ::profile::prometheus::elasticsearch_jmx_exporter
    include ::elasticsearch::nagios::check
    include ::profile::mjolnir::kafka_daemon

    system::role { 'elasticsearch::relforge':
        ensure      => 'present',
        description => 'elasticsearch relforge',
    }


    # the relforge cluster is serving labs, it should never be connected from
    # production, except from terbium to import production indices.
    $maintenance_hosts = join($network::constants::special_hosts['production']['maintenance_hosts'], ' ')

    ::ferm::service { 'elastic-https-terbium':
      ensure => present,
      proto  => 'tcp',
      port   => '9243',
      srange => "(${maintenance_hosts})",
    }

}
