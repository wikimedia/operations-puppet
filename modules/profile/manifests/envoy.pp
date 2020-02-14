# == Class profile::envoy
#
# Sets up a basic installation of the envoy proxy. You will need to define listeners and clusters separately
#
class profile::envoy(
    Wmflib::Ensure $ensure = lookup('profile::envoy::ensure'),
    Array[String] $prometheus_nodes = lookup('prometheus_nodes'),
    String $cluster = lookup('cluster'),
) {
    if os_version('debian jessie') {
        group { 'envoy':
            ensure => present,
        }
        user { 'envoy':
            ensure     => present,
            gid        => 'envoy',
            shell      => '/bin/false',
            home       => '/nonexistent',
            system     => true,
            managehome => false,
        }

        $pkg_name = 'getenvoy-envoy'
        apt::repository { 'getenvoy-jessie':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => 'jessie-wikimedia',
            components => 'thirdparty/envoyproxy',
            before     => Package[$pkg_name]
        }
        # We need to install a full systemd unit as the package doesn't have one.
        $use_override = false
    } else {
        $pkg_name = 'envoyproxy'
        $use_override = true
    }
    $admin_port = 9631
    class { '::envoyproxy':
        ensure          => $ensure,
        admin_port      => $admin_port,
        pkg_name        => $pkg_name,
        use_override    => $use_override,
        service_cluster => $cluster,
    }
    # metrics collection from prometheus can just fetch data pulling via GET from
    # /stats/prometheus on the admin port
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-envoy-admin':
        ensure => $ensure,
        proto  => 'tcp',
        port   => $admin_port,
        srange => $ferm_srange,
    }
}
