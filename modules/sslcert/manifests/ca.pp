# == Define: sslcert::ca
#
# Installs a X.509 certificate authority.
#
# This is deeply integrated with Debian's mechanism for installing
# certificates. The ca-certificates package is used, which eventually would
# install the certificate under /etc/ssl/certs as well as a symlink with its
# hash, in openssl's c_rehash format.
#
# === Parameters
#
# [*ensure*]
#   If 'present', the CA will be installed; if 'absent', it will be removed.
#   The default is 'present'.
#
# [*content*]
#   If defined, will be used as the content of the X.509 CA file.
#   Undefined by default. Mutually exclusive with 'source'.
#
# [*source*]
#   Path to file containing the X.509 CA file. Undefined by default.
#   Mutually exclusive with 'content'.
#
# === Examples
#
#  sslcert::ca { 'RapidSSL_CA':
#      ensure => present,
#      source => 'puppet:///modules/base/ca/RapidSSL_CA.crt',
#  }
#

define sslcert::ca(
  $ensure=present,
  $source=undef,
  $content=undef,
) {
    include sslcert

    file { "/usr/local/share/ca-certificates/${title}.crt":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['ca-certificates'],
        notify  => Exec['update-ca-certificates'],
        source  => $source,
        content => $content,
    }

    if $ensure == 'absent' {
        # clean up manually -- update-ca-certificates leaves stale symlinks
        file { "/etc/ssl/certs/${title}.pem":
            ensure => $ensure,
            before => File["/usr/local/share/ca-certificates/${title}.crt"],
        }
    }
}
