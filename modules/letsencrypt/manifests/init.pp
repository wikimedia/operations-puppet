# setup a TLS cert from letsencrypt.org
class letsencrypt {
    require ::sslcert

    group { 'acme':
        ensure => present,
    }

    user { 'acme':
        ensure     => present,
        gid        => 'acme',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    # https://github.com/diafygi/acme-tiny
    file { '/usr/local/sbin/acme_tiny.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/letsencrypt/acme_tiny.py'
    }

    file { '/usr/local/sbin/acme-setup':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/letsencrypt/acme-setup',
    }

    file { '/etc/acme':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/acme/challenge-nginx.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/letsencrypt/challenge-nginx.conf',
    }

    # LE Intermediate: current since ~2016-03-26
    sslcert::ca { 'Lets_Encrypt_Authority_X3':
        source  => 'puppet:///modules/letsencrypt/lets-encrypt-x3-cross-signed.pem'
    }

    # LE Intermediate: disaster recovery fallback since ~2016-03-26
    sslcert::ca { 'Lets_Encrypt_Authority_X4':
        source  => 'puppet:///modules/letsencrypt/lets-encrypt-x4-cross-signed.pem'
    }
}
