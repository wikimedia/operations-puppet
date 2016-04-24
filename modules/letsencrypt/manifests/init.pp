# setup a TLS cert from letsencrypt.org
class letsencrypt {

    # https://github.com/diafygi/acme-tiny
    file { '/usr/local/sbin/acme_tiny.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/letsencrypt/acme_tiny.py'
    }

}
