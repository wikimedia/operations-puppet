# setup a TLS cert from letsencrypt.org
class sslcert::letsencrypt::simple {

    # https://github.com/diafygi/acme-tiny
    file { '/usr/local/bin/acme_tiny.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/sslcert/letsencrypt/acme_tiny.py'
    }

}
