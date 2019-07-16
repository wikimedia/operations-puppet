# == Class profile::services_proxy
#
# This class sets up a simple nginx proxy to remote services.
#
# === Parameters
#
# [*ensure*] Whether the proxy should be present or not. We don't use it in deployment-prep.
#
# [*services*] A hash of service definitions.
#
class profile::services_proxy(
    Wmflib::Ensure $ensure = hiera('profile::services_proxy::ensure', 'present'),
    Optional[Hash[String, Struct[{
                        'hostname' => Stdlib::Host,
                        'localport' => Stdlib::Port::Unprivileged,
                        'port' => Stdlib::Port,
                        'scheme' => Enum['http', 'https'],
                        'timeout' => Integer,
                        'connect_timeout' => Optional[Integer],
                        'keepalive' => Optional[Integer], }]
    ]] $services = hiera('profile::services_proxy::services', undef),
      ) {
    if $ensure == 'present' {

        if $services == undef {
            fail('You must declare services if the proxy is to be present')
        }
        require profile::tlsproxy::instance
    }
    # Some parameters that we don't need to parametrize for now
    # The keepalive parameter sets the maximum number of idle keepalive connections
    $keepalive = 100
    # How long to wait for a connection to upstreams
    $connect_timeout = 1

    nginx::site { 'upstream_proxies':
        ensure  => $ensure,
        content => template('profile/services_proxy/upstream_proxies.conf.erb')
    }
}
