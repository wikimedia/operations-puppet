# === Class puppet::ca
#
# Makes the puppet CA available system-wide

class base::puppet::ca (
    $ssldir='/var/lib/puppet/ssl',
    $ensure='present'
    ) {

    sslcert::ca { 'puppet':
        ensure => $ensure,
        source => "${ssldir}/certs/ca.pem"
    }
}
