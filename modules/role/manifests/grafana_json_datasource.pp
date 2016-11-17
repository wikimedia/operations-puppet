# manifests/role/grafana_json_datasource.pp
# grafana_json_datasource: Simple JSON datasource for Grafana

class role::grafana_json_datasource {

    system::role { 'role::grafana_json_datasource': description => 'Grafana JSON datasource' }

    sslcert::certificate { 'grafana-json-datasource.wikimedia.org': }
    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)

    monitoring::service { 'https-grafana_json_datasource':
        description   => 'HTTPS-grafana_json_datasource',
        check_command => 'check_ssl_http!grafana-json-datasource.wikimedia.org',
    }

    class { '::grafana_json_datasource':
        site_name    => 'grafana-json-datasource.wikimedia.org',
        docroot      => '/srv/grafana_json_datasource',
    }

}
