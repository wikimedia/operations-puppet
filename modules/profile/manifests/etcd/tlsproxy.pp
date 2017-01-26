class profile::etcd::tlsproxy(
    $cert_name = hiera('profile::etcd::tlsproxy::cert_name'),
    $accounts = hiera('profile::etcd::tlsproxy::accounts'),
    $acls = hiera('profile::etcd::tlsproxy::acls'),
    $salt = hiera('profile::etcd::tlsproxy::salt')
){
    require ::tlsproxy::instance

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
        ensure => present,
        mode   => '0440',

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
