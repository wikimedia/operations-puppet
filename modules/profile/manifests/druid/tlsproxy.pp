# == Class profile::druid::tlsproxy
# Configure a nginx reverse proxy in front of Druid in order to
# implement a basic authn scheme.
#
class profile::druid::tlsproxy(
    $cert_name = hiera('profile::druid::tlsproxy::cert_name'),
    $accounts  = hiera('profile::druid::tlsproxy::accounts'),
    $salt      = hiera('profile::druid::tlsproxy::salt'),
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

    file { '/etc/nginx/auth/druid.htpasswd':
        content => template('profile/druid/htpasswd.erb'),
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0444',
    }

    nginx::site { 'etcd_tls_proxy':
        ensure  => present,
        content => template('profile/druid/tls_proxy.conf.erb'),
    }

    ::ferm::service { 'tlsproxy-broker':
        proto  => 'tcp',
        port   => '8182',
        srange => '$DOMAIN_NETWORKS',
    }
}
