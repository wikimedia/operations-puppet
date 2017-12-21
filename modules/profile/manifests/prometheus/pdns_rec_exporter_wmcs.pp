class profile::prometheus::pdns_rec_exporter_wmcs (
) {
    require_package('prometheus-pdns-rec-exporter')

    service { 'prometheus-pdns-rec-exporter':
        ensure  => running,
    }

    ferm::service { 'prometheus-pdns-rec-exporter':
        proto  => 'tcp',
        port   => '9199',
        srange => '@resolve(labmon1001.eqiad.wmnet)', # Should be properly defined via Hiera for WMCS
    }
}
