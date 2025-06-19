# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - executors
class profile::zuul::executor {

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

}
