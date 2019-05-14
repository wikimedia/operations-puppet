class profile::etcd::tlsproxy(
    $cert_name = hiera('profile::etcd::tlsproxy::cert_name'),
    $acls = hiera('profile::etcd::tlsproxy::acls'),
    $salt = hiera('profile::etcd::tlsproxy::salt'),
    $read_only = hiera('profile::etcd::tlsproxy::read_only'),
    Stdlib::Port $listen_port = hiera('profile::etcd::tlsproxy::listen_port'),
    Stdlib::Port $upstream_port = hiera('profile::etcd::tlsproxy::upstream_port'),
    Boolean $tls_upstream = hiera('profile::etcd::tlsproxy::tls_upstream')
) {
    require ::profile::tlsproxy::instance
    require ::passwords::etcd

    $accounts = $::passwords::etcd::accounts

    # TODO: also support TLS cert auth to the backend
    $upstream_scheme = $tls_upstream ? {
        true    => 'https',
        default => 'http'
    }

    $upstream_host = $tls_upstream ? {
        true    => $::fqdn,
        default => '127.0.0.1'
    }
    sslcert::certificate { $cert_name:
        skip_private => false,
        before       => Service['nginx'],
    }

    file { '/etc/nginx/auth/':
        ensure  => directory,
        mode    => '0550',
        owner   => 'www-data',
        require => Package['nginx-full'],
        before  => Service['nginx']
    }

    file { '/etc/nginx/etcd-errors':
        ensure  => directory,
        mode    => '0550',
        owner   => 'www-data',
        require => Package['nginx-full'],
        before  => Service['nginx']
    }

    # Simulate the etcd auth error
    file { '/etc/nginx/etcd-errors/401.json':
        ensure  => present,
        mode    => '0444',
        content => '{"errorCode":110,"message":"The request requires user authentication","cause":"Insufficient credentials","index":0}',
    }

    file { '/etc/nginx/etcd-errors/readonly.json':
        ensure  => present,
        mode    => '0444',
        content => '{"errorCode":107,"message":"This cluster is in read-only mode","cause":"Cluster configured to be read-only","index":0}',
    }

    # I know, this is pretty horrible. Puppet is too, with its
    # allergy for any form of data-structure mangling.
    $htpasswd_files = keys($acls)
    ::profile::etcd::htpasswd_file { $htpasswd_files:
        acls  => $acls,
        users => $accounts,
        salt  => $salt,
    }

    nginx::site { 'etcd_tls_proxy':
        ensure  => present,
        content => template('profile/etcd/tls_proxy.conf.erb'),
    }
}
