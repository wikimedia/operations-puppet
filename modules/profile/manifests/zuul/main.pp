# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - main nodes
class profile::zuul::main(
    Stdlib::Fqdn $mysql_host = lookup('profile::zuul::main::mysql_host'),
    String $gerrit_user = lookup('profile::zuul::main::gerrit_user'),
    Array[Stdlib::Fqdn] $main_nodes = lookup('zuul_main_nodes'),
){
    $zookeeper_server_ip = dnsquery::lookup($main_nodes[0])[0]

    include ::passwords::mysql::zuul
    $mysql_pass = $::passwords::mysql::zuul::password

    include ::passwords::zuul::gerrit
    $gerrit_pass = $::passwords::zuul::gerrit::password

    ensure_packages(['apparmor-utils'])

    rsyslog::conf { 'zuul':
        content  => file('zuul/rsyslog.conf'),
        priority => 20,
    }

    $tls_paths = profile::pki::get_cert('zuul')
    $zookeeper_tls_cert = $tls_paths['cert']
    $zookeeper_tls_key = $tls_paths['key']
    $zookeeper_tls_ca = $tls_paths['chain']

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

    file { '/var/lib/zuul/.ssh':
        ensure  => 'directory',
        owner   => 'zuul',
        group   => 'zuul',
        require => File['/var/lib/zuul'],
    }

    # let zuul see and validate gerrit server ssh host keys
    # otherwise zuul will accept any key provided (T395938#10929023)
    # link into existing ssh_known_hosts populated by puppet
    file { '/var/lib/zuul/.ssh/known_hosts':
        ensure => 'link',
        target => '/etc/ssh/ssh_known_hosts',
    }

    profile::auto_restarts::service { 'envoyproxy': }

    file { '/var/www/zuul':
        ensure => 'directory',
        owner  => 'zuul',
        group  => 'zuul',
    }
}
