# Generate blackbox modules configuration from service::catalog entries.
# The main use case is to have customised modules for HTTP(s) services.
class prometheus::blackbox::modules::service_catalog (
  Hash[String, Wmflib::Service] $services_config,
) {
  $modules = $services_config.reduce({}) |$memo, $el| {
    $service_name = $el[0]
    $service_config = $el[1]

    # Find out which SNI to send. Similar logic to
    # prometheus::service_catalog_targets for DNS names; in this case
    # try discovery since that is the standard going forward and
    # more likely for services to have it in SNI.

    # Offer users the option to override Host and SNI via probe 'host' field.
    if 'probes' in $service_config and 'host' in $service_config['probes'][0] {
      $tls_server_name = $service_config['probes'][0]['host']
    } elsif 'discovery' in $service_config {
      $disc_name = $service_config['discovery'][0]['dnsdisc']
      $tls_server_name = "${disc_name}.discovery.wmnet"
    } elsif 'aliases' in $service_config {
      $first_alias = $service_config['aliases'][0]
      $tls_server_name = "${first_alias}.svc.${::site}.wmnet"
    } else {
      $tls_server_name = "${service_name}.svc.${::site}.wmnet"
    }

    $probe_options = 'probes' in $service_config ? {
      true  => wmflib::service::probe::http_module_options($service_name, $service_config),
      false => {},
    }

    $http_options = {
      'fail_if_ssl'     => !$service_config['encryption'],
      'fail_if_not_ssl' => $service_config['encryption'],
      'tls_config'      => { 'server_name' => $tls_server_name },
    } + $probe_options

    $memo + {
      "http_${service_name}_ip4" => {
        'prober' => 'http',
        'http'   => {
          'preferred_ip_protocol' => 'ip4',
        } + $http_options,
      },
      "http_${service_name}_ip6" => {
        'prober' => 'http',
        'http'   => {
          'preferred_ip_protocol' => 'ip6',
        } + $http_options,
      },
    }
  }

  file { '/etc/prometheus/blackbox.yml.d/service_catalog.yml':
    content => ordered_yaml({'modules' => $modules}),
    mode    => '0444',
    owner   => 'root',
    group   => 'root',
    notify  => Exec['assemble blackbox.yml'],
  }
}
