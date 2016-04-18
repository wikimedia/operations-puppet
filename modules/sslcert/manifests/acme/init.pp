# == Class: sslcert::acme::init
#
# Base class for the ACME scripts.
#
# === Parameters
#
# === Examples
#
#  require sslcert::acme::init
#
class sslcert::acme::init {
    require sslcert

    # generic script for fetching the OCSP file for a given cert
    file { '/usr/local/sbin/acme-setup':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/sslcert/acme-setup',
    }
}
