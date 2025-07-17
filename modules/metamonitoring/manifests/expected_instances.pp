# SPDX-License-Identifier: Apache-2.0
# @param config Configuration file to use, if the default is not suitable
class metamonitoring::expected_instances (
    Array[String] $datacenters = lookup('datacenters'), # lint:ignore:wmf_styleguide
) {
    $dc_pattern = join($datacenters, '|')
    $re = Regexp("^.*\\.(${dc_pattern}).*$")
    $prometheus_instances = wmflib::puppetdb_query('resources [title, certname] { (title ~ "^prometheus@") and (type = "Service")}')
    # prometheus_isntances: used as a variable in env file template
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
    }
}
