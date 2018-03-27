class profile::prometheus::pdns_exporter (
    $monitoring_master = "%{hiera('wmcs::monitoring::master')}",
) {
    require_package('prometheus-pdns-exporter')

    service { 'prometheus-pdns-exporter':
        ensure  => running,
    }

    ferm::service { 'prometheus-pdns-exporter':
        proto  => 'tcp',
        port   => '9192',
        srange => '@resolve(${monitoring_master})',
    }
}
