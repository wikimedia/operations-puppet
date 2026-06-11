# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - launcher for zuul
# replaced zuul-nodepool with zuul 14.x (T424879)
class profile::zuul::launcher(
    String $launcher_certificate_authority_data = lookup('profile::zuul::launcher::certificate_authority_data'),
    Stdlib::HTTPSUrl $launcher_server_url = lookup('profile::zuul::launcher::server_url'),
    String $launcher_user_token = lookup('profile::zuul::launcher::user_token'),
    String $image_version = lookup('profile::zuul::launcher::image_version'),
    Wmflib::Ensure $service_ensure = lookup('profile::zuul::launcher::service_ensure'),
    Stdlib::Unixpath $tls_config_dir = lookup('profile::zuul::launcher::tls_config_dir'),
    String $zookeeper_tls_fullchain = lookup('profile::zuul::launcher::zookeeper_tls_fullchain'),
    Array[Stdlib::Fqdn] $main_nodes = lookup('zuul_main_nodes'),
    Optional[Stdlib::HTTPUrl] $http_proxy = lookup('profile::zuul::launcher::http_proxy'),
    Array[Stdlib::Host] $no_proxy = lookup('profile::zuul::launcher::no_proxy'),
){
    # IP used for host.docker.internal hosts entry
    $host_ip = $facts['networking']['ip']

    $launcher_kube_config = '/etc/zuul-launcher/kubeconfig'

    # zookeeper values for launcher config
    $zookeeper_server_ip = dnsquery::lookup($main_nodes[0])[0]
    $tls_paths = profile::pki::get_cert('zuul', 'launcher', {
        'owner'  => 'zuul',
        'outdir' => $tls_config_dir,
    })
    $zookeeper_tls_cert = $tls_paths['cert']
    $zookeeper_tls_key = $tls_paths['key']
    $zookeeper_tls_ca = $zookeeper_tls_fullchain

    file { '/etc/zuul-launcher':
        ensure  => 'directory',
        owner   => 'zuul',
        group   => 'zuul',
        require => User['zuul'],
    }

    file { $launcher_kube_config:
        ensure  => file,
        owner   => 'zuul',
        group   => 'zuul',
        mode    => '0550',
        content => template('profile/zuul/launcher-kubeconfig.erb'),
        require => File['/etc/zuul-launcher'],
    }

    file { '/etc/zuul-launcher/launcher.yaml':
        ensure  => file,
        owner   => 'zuul',
        group   => 'zuul',
        content => template('profile/zuul/launcher.yaml.erb'),
        require => File['/etc/zuul-launcher'],
    }

    systemd::service { 'zuul-launcher':
        ensure    => $service_ensure,
        content   => systemd_template('zuul-launcher'),
        require   => [
            File['/etc/zuul/zuul.conf'],
            File['/etc/zuul-launcher'],
        ],
        subscribe => File['/etc/zuul/zuul.conf'],
    }
}
