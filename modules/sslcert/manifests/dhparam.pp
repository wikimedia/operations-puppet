# Should be required by anything that installs a server certificate.  This
# ensures we have our dhparam.pem available at a default path for all such
# servers to use with DHE ciphersuites.  ssl_ciphersuite will conditionally
# reference this path within nginx/apache config when needed.
class sslcert::dhparam {
    file { '/etc/ssl/dhparam.pem':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/sslcert/dhparam.pem',
    }
}
