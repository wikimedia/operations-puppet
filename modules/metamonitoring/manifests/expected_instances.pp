# SPDX-License-Identifier: Apache-2.0
class metamonitoring::expected_instances (
    Array[String] $datacenters = lookup('datacenters'), # lint:ignore:wmf_styleguide
) {
    $dc_pattern = join($datacenters, '|')
    $re = Regexp("^.*\\.(${dc_pattern}).*$")
    $prometheus_instances = wmflib::puppetdb_query('resources [title, certname] { (title ~ "^prometheus@") and (type = "Service")}')
    $icinga_instances = (wmflib::puppetdb_query('resources [certname] { (title = "icinga") and (type = "Systemd::Service")}')).reduce({}) |$memo, $instance| {
        $host = regsubst($instance['certname'], '\..*$', '')
        $site_index = Integer(regsubst($host, '^[^0-9]*([0-9]).*$', '\1')) - 1
        $site = $datacenters[$site_index]
        $memo + {
            "icinga_${host}_${site}" => {
                  'source' => 'icinga',
                  'site'   => $site,
                  'host'   => $host,
                  'fqdn'   => $instance['certname'],
            }
        }
    }

    $monitored_instances = $prometheus_instances.reduce({}) |$memo, $instance| {
        if $instance['certname'] =~ $re {
            $site = $1
            $e = {
                'source'     => 'prometheus',
                'prometheus' => $instance['title'].downcase.split('@')[-1],
                'site'       => $site,
            }
            $memo + { "prometheus_${instance['title'].downcase.split('@')[-1]}_${site}" => $e }
        } else {
            # continue
            $memo
        }
    } + { 'thanos' => {
            'source' => 'thanos'
        }
    } + $icinga_instances
}
