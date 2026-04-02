# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - nodepool for zuul
class profile::zuul::nodepool(
    String $nodepool_certificate_authority_data = lookup('profile::zuul::nodepool::certificate_authority_data'),
    Stdlib::HTTPSUrl $nodepool_server_url = lookup('profile::zuul::nodepool::server_url'),
    Variant[Stdlib::IP::Address, Stdlib::Fqdn] $nodepool_tls_server_name = lookup('profile::zuul::nodepool::tls_server_name'),
    String $nodepool_user_token = lookup('profile::zuul::nodepool::user_token'),
    Stdlib::HTTPUrl $nodepool_proxy_url = lookup('profile::zuul::nodepool::proxy_url'),
    String $image_version = lookup('profile::zuul::nodepool::image_version'),
    Wmflib::Ensure $service_ensure = lookup('profile::zuul::nodepool::service_ensure'),
    Stdlib::Unixpath $tls_config_dir = lookup('profile::zuul::nodepool::tls_config_dir'),
    String $zookeeper_tls_fullchain = lookup('profile::zuul::nodepool::zookeeper_tls_fullchain'),
    Array[Stdlib::Fqdn] $main_nodes = lookup('zuul_main_nodes'),
){
    # IP used for host.docker.internal hosts entry
    $host_ip = $facts['networking']['ip']

    $nodepool_kube_config = '/etc/nodepool/config'

    # zookeeper values for nodepool config
    $zookeeper_server_ip = dnsquery::lookup($main_nodes[0])[0]
    $tls_paths = profile::pki::get_cert('zuul', 'nodepool', {
        'owner'  => 'nodepool',
        'outdir' => $tls_config_dir,
    })
    $zookeeper_tls_cert = $tls_paths['cert']
    $zookeeper_tls_key = $tls_paths['key']
    $zookeeper_tls_ca = $zookeeper_tls_fullchain

    systemd::sysuser { 'nodepool':
        usertype    => 'user',
        description => 'nodepool runtime user',
    }

    file { '/etc/nodepool':
        ensure  => 'directory',
        owner   => 'nodepool',
        group   => 'nodepool',
        require => Systemd::Sysuser['nodepool'],
    }

    file { $nodepool_kube_config:
        ensure  => file,
        owner   => 'nodepool',
        group   => 'nodepool',
        mode    => '0550',
        content => template('profile/zuul/nodepool.conf.erb'),
        require => File['/etc/nodepool'],
    }

    file { '/etc/nodepool/nodepool.yaml':
        ensure  => file,
        owner   => 'nodepool',
        group   => 'nodepool',
        content => template('profile/zuul/nodepool.yaml.erb'),
        require => File['/etc/nodepool'],
    }

    systemd::service { 'zuul-nodepool':
        ensure    => $service_ensure,
        content   => systemd_template('zuul-nodepool'),
        require   => File[$nodepool_kube_config],
        subscribe => File[$nodepool_kube_config],
    }
}
