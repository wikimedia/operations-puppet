# == Define: profile::openstack::base::haproxy::site
#
# Configures a HAProxy layer7 backend and frontend configuration for the
# requested service endpoint.
#
# === Parameters
#
# [*ensure*]
#   'present' or 'absent'; whether the site configuration is
#   installed or removed in conf.d/
#
# [*port_backend*]
#   The backend port HAProxy will use to connect to the backend servers.
#
# [*port_frontend*]
#   The frontend port HAproxy will bind to for this service.
#
# [*servers*]
#   A list of backend servers providing the service.
#
# === Examples
#
#  profile::openstack::base::haproxy::site { 'nova_metadata':
#      port_frontend => '8775',
#      port_backend  => '18775',
#      servers       => ['backend-host01', 'backend-host02'],
#  }
#
define profile::openstack::base::haproxy::site(
    Array[Stdlib::Fqdn] $servers,
    Stdlib::Port $port_backend,
    Stdlib::Port $port_frontend,
    Stdlib::String $healthcheck_path,
    $ensure = present,
) {
    include profile::openstack::base::haproxy

    # Allow traffic to peers on backend ports
    $peers = join(delete($servers, $::fqdn), ' ')
    ferm::service { "${title}_haproxy_backend":
        proto  => 'tcp',
        port   => $port_backend,
        srange => "@resolve(${peers})",
    }

    file { "/etc/haproxy/conf.d/${title}.cfg":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/openstack/base/haproxy/conf.d/http-service.cfg.erb'),
        # restart to pick up new config files in conf.d
        notify  => Exec['restart-haproxy'],
    }
}
