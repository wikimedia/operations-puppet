# @summary This class sets up a simple nginx proxy to remote services.
# @param ensure Whether the proxy should be present or not. We don't use it in deployment-prep.
# @param all_listeners A hash of listener definitions.
#   Each listener should have the following structure:
#   name - the name of the listener
#   port - the local port to listen on
#   timeout - the time after which we timeout on a call
#   service - The label for the service we're connecting to in service::catalog in hiera
#   http_host - optional http Host: header to add to the request
#   upstream - upstream host to contact. If unspecified, <service>.discovery.wmnet will be assumed.
#   retry - The retry policy, if any. See the envoy docs for RetryPolicy for details.
#   keepalive - keepalive timeout. If not specified, the default envoy value will be used.
#             For nodejs applications assume the right value is 5 seconds (see T247484)
#   xfp - Set an explicit value for X-Forwarded-Proto, instead of letting envoy inject it (see T249535)
# @param enabled_listeners Optional list of listeners we want to install locally.
# @param listen_ipv6 listen on ipv6
# @param local_otel_reporting_pct float, the percentage (e.g. 37.5) of traffic to be sampled for tracing
class profile::services_proxy::envoy(
    Wmflib::Ensure                   $ensure                    = lookup('profile::envoy::ensure', {'default_value' => 'present'}),
    Array[Profile::Service_listener] $all_listeners             = lookup('profile::services_proxy::envoy::listeners', {'default_value' => []}),
    Optional[Array[String]]          $enabled_listeners         = lookup('profile::services_proxy::envoy::enabled_listeners', {'default_value' => undef}),
    Boolean                          $listen_ipv6               = lookup('profile::services_proxy::envoy::listen_ipv6'),
    Float                            $local_otel_reporting_pct  = lookup('profile::services_proxy::envoy::local_otel_reporting_pct'),
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
        require profile::envoy

    }
    $all_services = wmflib::service::fetch()
    $listeners.each |$listener| {
        $cluster_label = $listener['service']
        $svc = $all_services[$cluster_label]
        if $svc == undef {
            fail("Could not find service ${cluster_label} in service::catalog")
        }
        if $listener['upstream'] {
            $address = $listener['upstream']
        } else {
            $address = "${listener['service']}.discovery.wmnet"
        }
        $svc_name = profile::services_proxy::envoy::svc_name($listener)
        if !defined(Envoyproxy::Cluster["${svc_name}_cluster"]) {
            envoyproxy::cluster { "${svc_name}_cluster":
                content => template('profile/services_proxy/envoy_service_cluster.yaml.erb'),
            }
        }

        if $local_otel_reporting_pct > 0 {
            $upstream_name = 'otel-collector'
            # OpenTelemetry reporting enabled, define cluster if nonexisting
            if !defined(Envoyproxy::Cluster["cluster_${upstream_name}"]) {
                # Set an upstream cluster that is required by the tracing stanza
                $connect_timeout = 1.0
                $upstream = {
                    'upstream' => {'port' => 4317, 'addr' => '127.0.0.1'},
                }
                envoyproxy::cluster { "cluster_${upstream_name}":
                  priority => 1,
                  content  => template('envoyproxy/tracing_cluster.yaml.erb'),
                }
            }
        }

        # Now define the listener
        if $listener['retry'] == undef {
            $retry_policy = {'num_retries' => 0}
        } else {
            $retry_policy = $listener['retry']
        }

        envoyproxy::listener { $listener['name']:
            content => template('profile/services_proxy/envoy_service_listener.yaml.erb'),
        }
    }
    # Now let's check for additional clusters to define for split traffic
    $listeners.each |$listener| {
        unless $listener['split'] {
            next()
        }
        $split = $listener['split']
        $cluster_label = $split['service']
        $svc = $all_services[$cluster_label]
        if $svc == undef {
            fail("Could not find service ${cluster_label} in service::catalog")
        }
        $svc_name_base = profile::services_proxy::envoy::svc_name($listener)
        $svc_name = "${svc_name_base}-split"
        if $split['upstream'] {
            $address = $split['upstream']
        } else {
            $address = "${split['service']}.discovery.wmnet"
        }
        if !defined(Envoyproxy::Cluster["${svc_name}_cluster"]) {
            envoyproxy::cluster { "${svc_name}_cluster":
                content => template('profile/services_proxy/envoy_service_cluster.yaml.erb'),
            }
        }
    }
}

# Service name is:
# - foo if upstream is foo.discovery.wmnet
# - $listener['service']_eqiad if upstream is foo.eqiad.wikimedia.org
#   or foo.svc.eqiad.wmnet
# - $listener['service'] otherwise
function profile::services_proxy::envoy::svc_name( Profile::Service_listener $listener ) >> String {
    if $listener['upstream'] {
        $address = $listener['upstream']
        if $address =~ /^([^.]+)\.discovery\.wmnet$/ {
            return $1
        }
        elsif $address =~ /^[^.]+\.svc\.([^.]+)\.wmnet$/ {
            return "${listener['service']}_${1}"
        }
        elsif $address =~ /^[^.]+\.([^.]+)\.wikimedia\.org$/ {
            return "${listener['service']}_${1}"
        }
        else {
            return $listener['service']
        }
    } else {
        return $listener['service']
    }
}
