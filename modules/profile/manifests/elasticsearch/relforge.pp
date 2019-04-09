class profile::elasticsearch::relforge (
    $maintenance_hosts = hiera('maintenance_hosts'),
) {
    include ::profile::elasticsearch::cirrus
    include ::profile::elasticsearch::monitor::base_checks
    include ::profile::mjolnir::kafka_msearch_daemon

    # the relforge cluster is serving labs, it should never be connected from
    # production, except from mwmaint hosts to import production indices.
    $maintenance_hosts_str = join($maintenance_hosts, ' ')
    ::ferm::service {
        default:
            ensure => present,
            proto  => 'tcp',
            port   => '9243',
            srange => "(${maintenance_hosts_str})",
        ;
        'elastic-main-https-mwmaint-9243':
            port   => '9243',
        ;
        'elastic-small-alpha-https-mwmaint-9443':
            port   => '9443',
        ;
    }
}
