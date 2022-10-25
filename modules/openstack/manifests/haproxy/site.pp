# == Define: openstack::haproxy::site
#
# Configures a HAProxy layer7 backend and frontend configuration for the
# requested service endpoint.
#
# === Parameters
#
# [*ensure*]
#   Wmflib Ensure (string)
#   'present' or 'absent'; whether the site configuration is
#   installed or removed in conf.d/
#
# [*port_backend*]
#   Port (int)
#   The backend port HAProxy will use to connect to the backend servers.
#
# [*frontends*]
#   Array of OpenStack::HAProxy::Frontend
#   Array of ports and possible acme-chief certificates to listen on.
#
# [*primary_host*]
#   Stdlib::Fqdn
#   When specified, the primary host will be the only active service;
#   others will be marked as backups. If this item is set but not
#   a member of the $servers below, all servers will be marked as backups
#   and nothing much will work.
#
# [*servers*]
#   Array of Stdlib::Fqdn
#   A list of backend servers providing the service.
#
# [*healthcheck_method*]
#   HTTP Method (String)
#   The HTTP request method to use for the healthcheck
#
# [*healthcheck_options*]
#   Array of Strings
#   A list of healthcheck (http-check) options
#
# [*type*]
#   Enum['http', 'tcp'] $type = 'http',
#   Specifies if the proxied service is http.
#
# [*firewall*]
#   Enum['public', 'internal', 'ignore']
#   Determines the ferm rule for the frontend port.
#    'public': expose port to the entire internet
#    'internal': expose port to internal WMF host only
#    'ignore': do not set a ferm rule, leave that to the calling code
#
# === Examples
#
#  openstack::haproxy::site { 'nova_metadata':
#      port_frontend => '8775',
#      port_backend  => '18775',
#      servers       => ['backend-host01', 'backend-host02'],
#      type          => 'http',
#      firewall      => 'internal'
#  }
#
define openstack::haproxy::site(
    Array[Stdlib::Fqdn] $servers,
    Stdlib::Port $port_backend,
    Array[OpenStack::HAProxy::Frontend] $frontends,
    Optional[Stdlib::Fqdn] $primary_host = undef,
    Stdlib::Compat::String $healthcheck_path = '',
    String $healthcheck_method = '',
    Array[String] $healthcheck_options = [],
    Wmflib::Ensure $ensure = present,
    Enum['http', 'tcp'] $type = 'http',
    Enum['public', 'internal', 'ignore'] $firewall = 'ignore',
) {
    # If the host's FQDN is in $servers configure FERM to allow peer
    # connections on the backend service port.
    if $::fqdn in $servers {
        # Allow traffic to peers on backend ports
        $peers = join(delete($servers, $::fqdn), ' ')
        ferm::service { "${title}_haproxy_backend":
            proto  => 'tcp',
            port   => $port_backend,
            srange => "(@resolve((${peers})) @resolve((${peers}), AAAA))",
        }
    }

    if $type == 'http' {
        file { "/etc/haproxy/conf.d/${title}.cfg":
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('openstack/haproxy/conf.d/http-service.cfg.erb'),
            # restart to pick up new config files in conf.d
            notify  => Service['haproxy'],
        }
    } elsif $type == 'tcp' {
        file { "/etc/haproxy/conf.d/${title}.cfg":
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('openstack/haproxy/conf.d/tcp-service.cfg.erb'),
            # restart to pick up new config files in conf.d
            notify  => Service['haproxy'],
        }
    } else {
        fail("Unknown service type ${type}")
    }

    $frontends.each | Integer $index, OpenStack::HAProxy::Frontend $frontend | {
        if $firewall == 'public' {
            ferm::service { "${title}_public_${index}":
                ensure => $ensure,
                proto  => 'tcp',
                port   => $frontend['port'],
            }
        } elsif $firewall == 'internal' {
            $srange = join(concat($::network::constants::production_networks,
                                  $::network::constants::labs_networks), ' ')

            ferm::service { "${title}_public_${index}":
                ensure => $ensure,
                proto  => 'tcp',
                port   => $frontend['port'],
                srange => "(${srange})",
            }
        }
    }
}
