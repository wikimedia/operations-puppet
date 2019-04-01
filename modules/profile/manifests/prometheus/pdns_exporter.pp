class profile::prometheus::pdns_exporter (
) {
    require_package('prometheus-pdns-exporter')

    service { 'prometheus-pdns-exporter':
        ensure  => running,
    }

    ferm::service { 'prometheus-pdns-exporter':
        proto  => 'tcp',
        port   => '9192',
        srange => '@resolve((labmon1001.eqiad.wmnet labmon1002.eqiad.wmnet))', # Should be properly defined via Hiera for WMCS
    }

    base::service_auto_restart { 'prometheus-pdns-exporter': }
}
