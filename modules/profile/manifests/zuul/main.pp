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

    class { 'httpd':
        modules => ['headers',
                    'rewrite',
                    'proxy',
                    'proxy_http'
        ],
    }

    profile::auto_restarts::service { 'apache2': }

    # allow caching layer to connect to backend of https://zuul.wikimedia.org
    firewall::service { 'zuul-https':
        proto    => 'tcp',
        port     => 443,
        src_sets => ['CACHES'],
    }

}
