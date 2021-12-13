class prometheus::blackbox::modules::service_catalog (
  Hash[String, Wmflib::Service] $services_config,
) {

  $modules = $services_config.reduce({}) |$memo, $el| {
      $service_name = $el[0]
      $service_config = $el[1]
      if 'discovery' in $service_config {
        $discovery_name = $service_config['discovery'][0]['dnsdisc']

        $tls_config = {
          'tls_config' => {
              'server_name' => "${discovery_name}.discovery.wmnet",
          },
        }
      } else {
        $tls_config = {}
      }

      # XXX add other overrides from service config (e.g. headers)
      if debian::codename::ge('bullseye') {
        $extra_http_opts = {
          'ip_protocol_fallback'  => false,
        }
      } else {
        $extra_http_opts = {}
      }

      $memo.merge({
        "http_${service_name}_ip4" => {
              'prober'                => 'http',
              'http'                  => {
                  'preferred_ip_protocol' => 'ip4',
                  'fail_if_ssl'           => !$service_config['encryption'],
                  'fail_if_not_ssl'       => $service_config['encryption'],
              } + $extra_http_opts + $tls_config
        },
        "http_${service_name}_ip6" => {
              'prober'                => 'http',
              'http'                  => {
                  'preferred_ip_protocol' => 'ip6',
                  'fail_if_ssl'           => !$service_config['encryption'],
                  'fail_if_not_ssl'       => $service_config['encryption'],
              } + $extra_http_opts + $tls_config
        },
      })
  }

  file { '/etc/prometheus/blackbox.yml.d/service_catalog.yml':
      content => ordered_yaml({'modules' => $modules}),
      mode    => '0444',
      owner   => 'root',
      group   => 'root',
      notify  => Exec['assemble blackbox.yml'],
  }

}
