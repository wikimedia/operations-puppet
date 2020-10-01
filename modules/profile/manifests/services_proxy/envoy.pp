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
# http_host - optional http Host: header to add to the request
# upstream - upstream host to contact. If unspecified, <service>.discovery.wmnet will be assumed.
# retry - The retry policy, if any. See the envoy docs for RetryPolicy for details.
# keepalive - keepalive timeout. If not specified, the default envoy value will be used.
#             For nodejs applications assume the right value is 5 seconds (see T247484)
# xfp - Set an explicit value for X-Forwarded-Proto, instead of letting envoy inject it (see T249535)
# [*enabled_listeners*] Optional list of listeners we want to install locally.
class profile::services_proxy::envoy(
    Wmflib::Ensure $ensure = lookup('profile::envoy::ensure', {'default_value' => 'present'}),
    Array[Profile::Service_listener] $all_listeners = lookup('profile::services_proxy::envoy::listeners', {'default_value' => []}),
    Optional[Array[String]] $enabled_listeners = lookup('profile::services_proxy::envoy::enabled_listeners', {'default_value' => undef})
) {
    if $enabled_listeners == undef {
        $listeners = $all_listeners
    } else {
        $listeners = $all_listeners.filter |$listener| {$listener['name'] in $enabled_listeners}
    }

    if $ensure == 'present' {
        if $listeners == [] {
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
        # Service name is:
        # - foo if upstream is foo.discovery.wmnet
        # - $listener['service']_eqiad if upstream is foo.eqiad.wikimedia.org
        #   or foo.svc.eqiad.wmnet
        # - $listener['service'] otherwise
        if $listener['upstream'] {
            $address = $listener['upstream']
            if $address =~ /^([^.]+)\.discovery\.wmnet$/ {
                $svc_name = $1
            }
            elsif $address =~ /^[^.]+\.svc\.([^.]+)\.wmnet$/ {
                $svc_name = "${listener['service']}_${1}"
            }
            elsif $address =~ /^[^.]+\.([^.]+)\.wikimedia\.org$/ {
                $svc_name = "${listener['service']}_${1}"
            }
            else {
                $svc_name = $listener['service']
            }
        } else {
            $svc_name = $listener['service']
            $address = "${svc_name}.discovery.wmnet"
        }
        if !defined(Envoyproxy::Cluster["${svc_name}_cluster"]) {
            envoyproxy::cluster { "${svc_name}_cluster":
                content => template('profile/services_proxy/envoy_service_cluster.yaml.erb')
            }
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
