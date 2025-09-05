# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - main server
class profile::zuul::main(
    Stdlib::Fqdn $mysql_host = lookup('profile::zuul::main::mysql_host'),
    String $gerrit_user = lookup('profile::zuul::main::gerrit_user'),
    String $nodepool_certificate_authority_data = lookup('profile::zuul::main::nodepool::certificate_authority_data'),
    Stdlib::HTTPSUrl $nodepool_server_url = lookup('profile::zuul::main::nodepool::server_url'),
    Variant[Stdlib::IP::Address, Stdlib::Fqdn] $nodepool_tls_server_name = lookup('profile::zuul::main::nodepool::tls_server_name'),
    String $nodepool_user_token = lookup('profile::zuul::main::nodepool::user_token'),
    Stdlib::HTTPUrl $nodepool_proxy_url = lookup('profile::zuul::main::nodepool::proxy_url'),
    Stdlib::Fqdn $zookeeper_server = lookup('profile::zuul::main::zookeeper_server'),
){
    $zookeeper_server_ip = dnsquery::lookup($zookeeper_server)[0]

    include ::passwords::mysql::zuul
    $mysql_pass = $::passwords::mysql::zuul::password

    include ::passwords::zuul::gerrit
    $gerrit_pass = $::passwords::zuul::gerrit::password

    ensure_packages(['apparmor-utils'])

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

    file { '/var/www/zuul':
        ensure => 'directory',
        owner  => 'zuul',
        group  => 'zuul',
    }

    class { 'httpd':
        modules => ['headers',
                    'rewrite',
                    'proxy',
                    'proxy_http',
                    'proxy_wstunnel'
        ],
        require => File['/var/www/zuul'],
    }

    httpd::site { 'zuul.wikimedia.org':
        source => 'puppet:///modules/zuul/zuul.wikimedia.org.conf'
    }

    profile::auto_restarts::service { 'apache2': }

    # allow caching layer to connect to backend of https://zuul.wikimedia.org
    firewall::service { 'zuul-https':
        proto    => 'tcp',
        port     => 443,
        src_sets => ['CACHES', 'DEPLOYMENT_HOSTS'],
    }

    # allow deployment hosts to speak plain http to backend for testing
    firewall::service { 'zuul-http':
        proto    => 'tcp',
        port     => 80,
        src_sets => ['DEPLOYMENT_HOSTS'],
    }

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

    file { '/etc/nodepool/config':
        ensure  => file,
        owner   => 'nodepool',
        group   => 'nodepool',
        mode    => '0550',
        content => template('profile/zuul/nodepool.conf.erb'),
        require => File['/etc/nodepool'],
    }

    $tls_paths = profile::pki::get_cert('zuul')
    $zookeeper_tls_cert = $tls_paths['cert']
    $zookeeper_tls_key = $tls_paths['key']
    $zookeeper_tls_ca = $tls_paths['chain']

    file { '/etc/nodepool/nodepool.yaml':
        ensure  => file,
        owner   => 'nodepool',
        group   => 'nodepool',
        content => template('profile/zuul/nodepool.yaml.erb'),
        require => File['/etc/nodepool'],
    }
}
