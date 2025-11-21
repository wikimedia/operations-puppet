# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - executors
class profile::zuul::executor(
    Stdlib::Port $web_port = lookup('profile::zuul::executor::web_port'),
    Array[Stdlib::Fqdn] $main_nodes = lookup('zuul_main_nodes'),
    String $image_version = lookup('profile::zuul::executor::image_version'),
    Wmflib::Ensure $service_ensure = lookup('profile::zuul::executor::service_ensure'),
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
}
