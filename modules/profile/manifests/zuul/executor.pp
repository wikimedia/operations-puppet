# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - executors
class profile::zuul::executor(
    Stdlib::Port $web_port = lookup('profile::zuul::executor::web_port'),
    Array[Stdlib::Fqdn] $main_nodes = lookup('zuul_main_nodes'),
    String $image_version = lookup('profile::zuul::executor::image_version'),
    Wmflib::Ensure $service_ensure = lookup('profile::zuul::executor::service_ensure'),
    Stdlib::Unixpath $tls_config_dir = lookup('profile::zuul::executor::tls_config_dir'),
){

    wmflib::dir::mkdir_p('/etc/zuul/ssh')

    file { '/etc/zuul/ssh/id_rsa':
        ensure  => present,
        owner   => 'root',
        group   => 'zuul',
        mode    => '0440',
        content => secret('zuul/id_rsa'),
        require => User['zuul'],
    }

    $host_ip = $facts['networking']['ip']

    firewall::service { 'zuul-web-from-main-nodes':
        proto  => 'tcp',
        port   => $web_port,
        srange => $main_nodes,
    }

    systemd::service { 'zuul-executor':
        ensure    => $service_ensure,
        content   => systemd_template('zuul-executor'),
        require   => File['/etc/zuul/zuul.conf'],
        subscribe => File['/etc/zuul/zuul.conf'],
    }

    # build full chain of trust with Root CA, Intermediate CA and cert
    $zookeeper_tls_fullchain = "${tls_config_dir}/zuul_full_chain.pem"

    concat { $zookeeper_tls_fullchain:
        owner => 'zuul',
        group => 'zuul',
        mode  => '0444',
    }

    # add Zuul client cert
    concat::fragment { 'zuul_client_cert':
        target => $zookeeper_tls_fullchain,
        source => "${tls_config_dir}/zuul__zuul.pem",
        order  => '00',
    }

    # add Intermediate CA
    concat::fragment { 'zuul_intermediate':
        target => $zookeeper_tls_fullchain,
        source => "${tls_config_dir}/zuul__zuul.chain.pem",
        order  => '01',
    }

    # add Root CA
    concat::fragment { 'wmf_root':
        target => $zookeeper_tls_fullchain,
        source => '/etc/ssl/certs/Wikimedia_Internal_Root_CA.pem',
        order  => '02',
    }
}
