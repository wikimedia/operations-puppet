# == Class profile::services_proxy::envoy
#
# This class sets up a simple nginx proxy to remote services.
#
# === Parameters
#
# [*ensure*] Whether the proxy should be present or not. We don't use it in deployment-prep.
#
# [*listeners*] A hash of listener definitions.
#
class profile::services_proxy::envoy(
    Wmflib::Ensure $ensure = lookup('profile::envoy::ensure', {'default_value' => 'present'}),
    Array[Struct[{
        'name'      => String,
        'port'      => Stdlib::Port::Unprivileged,
        'timeout'   => String,
        'http_host' => Optional[Stdlib::Fqdn],
        'cluster'   => String,
    }]] $listeners = lookup('profile::services_proxy::envoy::listeners', {'default_value' => []}),
    Array[String] $local_clusters = lookup('profile::services_proxy::envoy::local_clusters')
) {
    if $ensure == 'present' {
        if $listeners == undef {
            fail('You must declare services if the proxy is to be present')
        }
        require ::profile::envoy
    }

    $all_services = wmflib::service::fetch()
    # Create one cluster definition for every entry in our service catalog that has
    # a discovery record.
    $all_services.each |$n, $svc| {
        if 'discovery' in $svc {
            envoyproxy::cluster { "${n}_cluster":
                content => template('profile/services_proxy/envoy_service_cluster.yaml.erb')
            }
        }
    }
    # Create one cluster definition per datacenter for every entry in our service catalog that we've declared like local
    # clusters
    $local_clusters.each |$cluster_label| {
        $svc = $all_services[$cluster_label]
        $svc['sites'].each |$dc| {
            $svc_name = "${cluster_label}_${dc}"
            envoyproxy::cluster { "${svc_name}_cluster":
                content => template('profile/services_proxy/envoy_service_local_cluster.yaml.erb')
            }
        }
    }

    # Create one listener definition for every service defined in this class.
    $listeners.each |$listener| {
        envoyproxy::listener { $listener['name']:
            content => template('profile/services_proxy/envoy_service_listener.yaml.erb')
        }
    }
}
