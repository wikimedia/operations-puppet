class prometheus::blackbox::modules::service_catalog (
  Hash[String, Wmflib::Service] $services_config,
) {

  $modules = $services_config.reduce({}) |$memo, $el| {
      $service_name = $el[0]
      $service_config = $el[1]

      # Find out which SNI to send. Similar logic to
      # prometheus::service_catalog_targets for DNS names; in this case
      # try discovery first since that is the standard going forward and
      # more likely for services to have it in SNI.
      if 'discovery' in $service_config {
        $disc_name = $service_config['discovery'][0]['dnsdisc']
        $tls_server_name = "${disc_name}.discovery.wmnet"
      } elsif 'aliases' in $service_config {
        $first_alias = $service_config['aliases'][0]
        $tls_server_name = "${first_alias}.svc.${::site}.wmnet"
      } else {
        $tls_server_name = "${service_name}.svc.${::site}.wmnet"
      }

      $tls_config = {
        'tls_config' => {
          'server_name' => $tls_server_name,
        },
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
