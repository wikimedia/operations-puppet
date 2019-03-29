class profile::toolforge::k8s::client(
    $master_host = hiera('k8s::master_host'),
    $etcd_hosts = hiera('flannel::etcd_hosts', [$master_host]),
){
    require_package('kubernetes-client')

    package { 'toollabs-webservice':
        ensure => latest,
    }

    # Legacy locations for the entry point script from toollabs-webservice
    # that are probably still hardcoded in some Tools.
    file { [
        '/usr/local/bin/webservice2',
        '/usr/local/bin/webservice',
    ]:
        ensure => link,
        target => '/usr/bin/webservice',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # Kubernetes Configuration - See T209627
    if os_version('ubuntu trusty') or os_version('debian jessie') {
        $etcd_url = join(prefix(suffix($etcd_hosts, ':2379'), 'https://'), ',')

        ferm::service { 'flannel-vxlan':
            proto => udp,
            port  => 8472,
        }

        class { '::k8s::flannel':
            etcd_endpoints => $etcd_url,
        }

        class { '::k8s::infrastructure_config':
            master_host => $master_host,
        }

        class { '::k8s::proxy':
            master_host => $master_host,
        }
    }

    # Due to vast version spread between client and server during the k8s
    # upgrade, it is necessary to install an old version of kubectl to support
    # some existing use-cases.  As the upgrade progresses, this will be
    # included in our repo in a packaged version.  The kubernetes-client
    # package is still useful for documentation, prehaps -- T215586
    file { 'kubectl-1.4':
        ensure         => file,
        path           => '/usr/local/bin/kubectl',
        owner          => 'root',
        group          => 'root',
        mode           => '0555',
        source         => 'https://storage.googleapis.com/kubernetes-release/release/v1.4.12/bin/linux/amd64/kubectl',
        checksum_value => 'e0376698047be47f37f126fcc4724487dcc8edd2ffb993ae5885779786efb597',
        checksum       => 'sha256',
    }
}
