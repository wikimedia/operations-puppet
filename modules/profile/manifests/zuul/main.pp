# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - main server
class profile::zuul::main(
    Stdlib::Fqdn $mysql_host = lookup('profile::zuul::main::mysql_host'),
    String $gerrit_user = lookup('profile::zuul::main::gerrit_user'),
){

    include ::passwords::mysql::zuul
    $mysql_pass = $::passwords::mysql::zuul::password

    include ::passwords::zuul::gerrit
    $gerrit_pass = $::passwords::zuul::gerrit::password

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

    file { '/var/lib/zuul':
        ensure  => 'directory',
        owner   => 'zuul',
        group   => 'zuul',
        require => User['zuul'],
    }
}
