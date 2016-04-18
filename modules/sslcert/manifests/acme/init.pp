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

    # offline ACME key/csr/cert setup, to run before web service start
    file { '/usr/local/sbin/acme-setup':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/sslcert/acme-setup',
    }
}
