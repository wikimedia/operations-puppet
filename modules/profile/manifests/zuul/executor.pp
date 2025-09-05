# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - executors
class profile::zuul::executor(
    Stdlib::Port $web_port = lookup('profile::zuul::executor::web_port'),
    Array[Stdlib::Fqdn] $main_nodes = lookup('zuul_main_nodes'),
){

    ensure_packages(['docker.io'])

    service { 'docker':
        ensure => running,
        enable => true,
    }

    wmflib::dir::mkdir_p('/etc/zuul/ssh')

    file { '/etc/zuul/ssh/id_rsa':
        ensure  => present,
        owner   => 'root',
        group   => 'zuul',
        mode    => '0440',
        content => secret('zuul/id_rsa'),
        require => User['zuul'],
    }

    firewall::service { 'zuul-web-from-main-nodes':
        proto  => 'tcp',
        port   => $web_port,
        srange => $main_nodes,
    }
}
