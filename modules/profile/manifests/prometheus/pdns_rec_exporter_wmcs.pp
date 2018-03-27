class profile::prometheus::pdns_rec_exporter_wmcs (
    $wmcs_monitoring_master = "%{hiera('wmcs::monitoring::master')}",
) {
    require_package('prometheus-pdns-rec-exporter')

    service { 'prometheus-pdns-rec-exporter':
        ensure  => running,
    }

    ferm::service { 'prometheus-pdns-rec-exporter':
        proto  => 'tcp',
        port   => '9199',
        srange => '@resolve("${wmcs_monitoring_master})',
    }
}
