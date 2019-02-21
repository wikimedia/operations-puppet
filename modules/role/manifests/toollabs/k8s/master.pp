# filtertags: labs-project-tools
class role::toollabs::k8s::master(
    $use_puppet_certs = false,
) {
    include ::toollabs::base
    include ::toollabs::infrastructure
    include ::profile::base::firewall

    $master_host = hiera('k8s::master_host', $::fqdn)
    $etcd_url = prefix(suffix(hiera('k8s::etcd_hosts'), ':2379'), 'https://')

    if $use_puppet_certs {
        $ssl_cert_path = '/etc/kubernetes/ssl/cert.pem'
        $ssl_key_path = '/etc/kubernetes/ssl/server.key'

    } else {
        $ssl_certificate_name = 'star.tools.wmflabs.org'
        sslcert::certificate { $ssl_certificate_name:
            group        => 'kube',
        }

        $ssl_cert_path = "/etc/ssl/localcerts/${ssl_certificate_name}.chained.crt"
        $ssl_key_path = "/etc/ssl/private/${ssl_certificate_name}.key"
    }

    # Set our host allowed paths
    $host_automounts = [
        '/etc/ldap.conf',
        '/etc/ldap.yaml',
        '/etc/novaobserver.yaml',
        '/var/run/nslcd/socket',
    ]
    $host_path_prefixes_allowed = [
        '/data/project/',
        '/data/scratch/',
        '/etc/wmcs-project',
        '/mnt/nfs',
        '/public/dumps/',
    ]
    $host_automounts_string = join($host_automounts, ',')
    $host_path_prefixes_allowed_string = join($host_path_prefixes_allowed, ',')


    $docker_registry = hiera('docker::registry')

    class { '::profile::kubernetes::master':
        etcd_urls                => $etcd_url,
        service_cluster_ip_range => '192.168.0.0/17',
        apiserver_count          => 1,
        accessible_to            => 'all',
        expose_puppet_certs      => $use_puppet_certs,
        ssl_cert_path            => $ssl_cert_path,
        ssl_key_path             => $ssl_key_path,
        authz_mode               => 'abac',
        admission_controllers    => {
            'NamespaceLifecycle' => '',
            'ResourceQuota'      => '',
            'LimitRanger'        => '',
            'UidEnforcer'        => '',
            'RegistryEnforcer'   => "--enforced-docker-registry=${docker_registry}",
            'HostAutomounter'    => "--host-automounts=${host_automounts_string}",
            'HostPathEnforcer'   => "--host-paths-allowed=${host_automounts_string} --host-path-prefixes-allowed=${host_path_prefixes_allowed_string}",
        },
    }

    class { '::toollabs::maintain_kubeusers':
        k8s_master => $master_host,
    }
}
