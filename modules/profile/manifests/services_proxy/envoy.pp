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
# Each listener should have the following structure:
# name - the name of the listener
# port - the local port to listen on
# timeout - the time after which we timeout on a call
# service - The label for the service we're connecting to in service::catalog in hiera
# retry - The retry policy, if any. See the envoy docs for RetryPolicy for details.
# http_host - optional http Host: header to add to the request
# site - optionally the site to connect to for the service. Only used when we don't want
#        to use discovery DNS
# dnsdisc - What discovery record to pick if more than one are available, or if it's not
#           equal to the service name.
# keepalive - keepalive timeout. If not specified, the default envoy value will be used.
#             For nodejs applications assume the right value is 5 seconds (see T247484)
class profile::services_proxy::envoy(
    Wmflib::Ensure $ensure = lookup('profile::envoy::ensure', {'default_value' => 'present'}),
    Array[Struct[{
        'name'      => String,
        'port'      => Stdlib::Port::Unprivileged,
        'timeout'   => String,
        'service'   => String,
        'retry'     => Optional[Hash],
        'http_host' => Optional[Stdlib::Fqdn],
        'site'      => Optional[String],
        'dnsdisc'   => Optional[String],
        'keepalive' => Optional[String],
    }]] $listeners = lookup('profile::services_proxy::envoy::listeners', {'default_value' => []}),
) {
    if $ensure == 'present' {
        if $listeners == undef {
            fail('You must declare services if the proxy is to be present')
        }
        require ::profile::envoy
    }
    $all_services = wmflib::service::fetch()

    $listeners.each |$listener| {
        $cluster_label = $listener['service']
        $svc = $all_services[$cluster_label]
        if $svc == undef {
            fail("Could not find service ${cluster_label} in service::catalog")
        }
        # Case 1: not using discovery
        if 'site' in $listener {
            $svc_name = "${cluster_label}_${listener['site']}"
            envoyproxy::cluster { "${svc_name}_cluster":
                content => template('profile/services_proxy/envoy_service_local_cluster.yaml.erb')
            }
        }
        # Case 2: using discovery
        elsif 'discovery' in $svc {
            # The discovery record defaults to the service name
            $svc_name = $listener['dnsdisc'] ? {
                undef => $listener['service'],
                default => $listener['dnsdisc']
            }
            $discoveries = $svc['discovery'].filter |$d| { $d['dnsdisc'] == $svc_name }
            # TODO: check we've chosen exactly one record, else fail
            if $discoveries != [] and !defined(Envoyproxy::Cluster["${svc_name}_cluster"]) {
                $discovery = $discoveries[0]
                envoyproxy::cluster { "${svc_name}_cluster":
                    content => template('profile/services_proxy/envoy_service_cluster.yaml.erb')

                }
            }
        }
        else {
            fail("Cluster ${cluster_label} doesn't have a discovery record, and not site picked.")
        }

        # Now define the listener
        if $listener['retry'] == undef {
            $retry_policy = {'num_retries' => 0}
        } else {
            $retry_policy = $listener['retry']
        }
        envoyproxy::listener { $listener['name']:
            content => template('profile/services_proxy/envoy_service_listener.yaml.erb')
        }
    }
}
