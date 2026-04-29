# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - launcher for zuul
# replaced zuul-nodepool with zuul 14.x (T424879)
class profile::zuul::launcher(
    String $launcher_certificate_authority_data = lookup('profile::zuul::launcher::certificate_authority_data'),
    Stdlib::HTTPSUrl $launcher_server_url = lookup('profile::zuul::launcher::server_url'),
    Variant[Stdlib::IP::Address, Stdlib::Fqdn] $launcher_tls_server_name = lookup('profile::zuul::launcher::tls_server_name'),
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
        'owner'  => 'launcher',
        'outdir' => $tls_config_dir,
    })
    $zookeeper_tls_cert = $tls_paths['cert']
    $zookeeper_tls_key = $tls_paths['key']
    $zookeeper_tls_ca = $zookeeper_tls_fullchain

    systemd::sysuser { 'launcher':
        usertype    => 'user',
        description => 'launcher runtime user',
    }

    file { '/etc/zuul-launcher':
        ensure  => 'directory',
        owner   => 'launcher',
        group   => 'launcher',
        require => Systemd::Sysuser['launcher'],
    }

    file { $launcher_kube_config:
        ensure  => file,
        owner   => 'launcher',
        group   => 'launcher',
        mode    => '0550',
        content => template('profile/zuul/launcher-kubeconfig.erb'),
        require => File['/etc/zuul-launcher'],
    }

    file { '/etc/zuul-launcher/launcher.yaml':
        ensure  => file,
        owner   => 'launcher',
        group   => 'launcher',
        content => template('profile/zuul/launcher.yaml.erb'),
        require => File['/etc/zuul-launcher'],
    }

    systemd::service { 'zuul-launcher':
        ensure    => $service_ensure,
        content   => systemd_template('zuul-launcher'),
        require   => File[$launcher_kube_config],
        subscribe => File[$launcher_kube_config],
    }
}
