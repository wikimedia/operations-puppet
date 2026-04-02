# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - base class / common setup for zuul nodes
class profile::zuul::base(
    String $gerrit_user             = lookup('profile::zuul::base::gerrit_user'),
    Array[Stdlib::Fqdn] $main_nodes = lookup('zuul_main_nodes'),
    Stdlib::Fqdn $mysql_host        = lookup('profile::zuul::base::mysql_host'),
    Stdlib::Unixpath $tls_config_dir = lookup('profile::zuul::base::tls_config_dir'),
    String $tls_password = lookup('profile::zuul::main::tls_password'),
    String $zookeeper_tls_fullchain = lookup('profile::zuul::base::zookeeper_tls_fullchain'),
){

    $zookeeper_server_ip = dnsquery::lookup($main_nodes[0])[0]

    include ::passwords::mysql::zuul
    $mysql_pass = $::passwords::mysql::zuul::password

    include ::passwords::zuul::gerrit
    $gerrit_pass = $::passwords::zuul::gerrit::password

    $tls_paths = profile::pki::get_cert('zuul', 'zuul', {
        'owner'           => 'zuul',
        'outdir'          => $tls_config_dir,
    })

    $zuul_tls_cert = $tls_paths['cert']
    $zuul_tls_key = $tls_paths['key']
    $zuul_tls_ca = $tls_paths['chain']

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

    include ::passwords::zuul::auth_operator
    $auth_operator_secret = $::passwords::zuul::auth_operator::secret

    ensure_packages(['apparmor-utils'])

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
        mode    => '0440',
        content => template('profile/zuul/zuul.conf.erb'),
        require => File['/etc/zuul'],
    }

    rsyslog::conf { 'zuul':
        content  => file('zuul/rsyslog.conf'),
        priority => 20,
    }

    firewall::service { 'zuul-docker-to-zookeeper':
        proto  => 'tcp',
        port   => 2281,
        srange => ['172.17.0.0/16'],
    }

}
