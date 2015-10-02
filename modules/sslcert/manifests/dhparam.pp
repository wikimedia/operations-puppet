# == Define: sslcert::dhparam
#
# Creates a dhparam file available at a default, well-known path. This is
# needed for servers to use with DHE ciphersuites.
#
# === Parameters
#
# === Examples
#
#  include sslcert::dhparam

class sslcert::dhparam {
    file { '/etc/ssl/dhparam.pem':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/sslcert/dhparam.pem',
    }
}
