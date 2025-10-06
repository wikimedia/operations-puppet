# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - executors
class profile::zuul::executor(
    Stdlib::Port $web_port = lookup('profile::zuul::executor::web_port'),
    Array[Stdlib::Fqdn] $main_nodes = lookup('zuul_main_nodes'),
    String $image_version = lookup('profile::zuul::executor::image_version'),
){

    $zookeeper_server_ip = dnsquery::lookup($main_nodes[0])[0]

    wmflib::dir::mkdir_p('/etc/zuul/ssh')

    file { '/etc/zuul/ssh/id_rsa':
        ensure  => present,
        owner   => 'root',
        group   => 'zuul',
        mode    => '0440',
        content => secret('zuul/id_rsa'),
        require => User['zuul'],
    }

    file { '/var/lib/zuul':
        ensure  => 'directory',
        owner   => 'zuul',
        group   => 'zuul',
        require => User['zuul'],
    }

    $host_ip = $facts['networking']['ip']
    $tls_paths = profile::pki::get_cert('zuul')
    $zookeeper_tls_cert = $tls_paths['cert']
    $zookeeper_tls_key = $tls_paths['key']
    $zookeeper_tls_ca = $tls_paths['chain']

    include ::passwords::zuul::auth_operator
    $auth_operator_secret = $::passwords::zuul::auth_operator::secret

    file { '/etc/zuul/zuul.conf':
        ensure  => file,
        owner   => 'zuul',
        group   => 'zuul',
        mode    => '0440',
        content => template('profile/zuul/zuul.conf.erb'),
        require => File['/etc/zuul'],
    }

    firewall::service { 'zuul-web-from-main-nodes':
        proto  => 'tcp',
        port   => $web_port,
        srange => $main_nodes,
    }

    systemd::service { 'zuul-executor':
        ensure    => 'present',
        content   => systemd_template('zuul-executor'),
        require   => File['/etc/zuul/zuul.conf'],
        subscribe => File['/etc/zuul/zuul.conf'],
    }
}
