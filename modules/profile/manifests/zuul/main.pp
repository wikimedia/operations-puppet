# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - main server
class profile::zuul::main {

    include ::passwords::mysql::zuul
    $mysql_pass = $::passwords::mysql::zuul::password

    ensure_packages(['docker.io', 'apparmor-utils'])

    service { 'docker':
        ensure => running,
        enable => true,
    }

    rsyslog::conf { 'zuul':
        content  => file('zuul/rsyslog.conf'),
        priority => 20,
    }

    file { '/etc/zuul':
        ensure  => 'directory',
        owner   => 'zuul',
        group   => 'zuul',
        require => User['zuul'],
    }

    file { '/etc/zuul/zuul.conf':
        ensure  => file,
        owner   => 'zuul',
        group   => 'zuul',
        content => template('profile/zuul/zuul.conf.erb'),
        require => File['/etc/zuul'],
    }

}
