# == Define: sslcert::certificate
#
# Installs a X.509 certificate -and, optionally, its private key- to the
# system's predefined local certificate directory.
#
# Certificates are installed to the custom-made directory /etc/ssl/localcerts
# rather than /etc/ssl/certs, as the latter is used often as the CA path in
# many default configurations and examples on the web.
#
# NOTE: while both 'source' and 'content' are provided for the certificate,
# only the equivalent of 'content' is provided for the private key. This is
# done purposefully, as serving sensitive key material using the puppet
# fileserver is dangerous and should be avoided. Use puppet's file() function
# to serve files on the puppetmaster's filesystem.
#
# === Parameters
#
# [*ensure*]
#   If 'present', the certificate will be installed; if 'absent', it will be
#   removed. The default is 'present'.
#
# [*chain*]
#   If true, create also a chained version of the certificate, by calling into
#   sslcert::chainedcert. The default is true.
#
# [*source*]
#   Path to file containing the X.509 certificate file. Undefined by default.
#
# [*private*]
#   The content of the private key to the certificate. Undefined by default.
#
# === Examples
#
#  sslcert::certificate { 'pinkunicorn.wikimedia.org':
#    ensure => present,
#    source => 'puppet:///files/ssl/pinkunicorn.wikimedia.org.crt',
#  }
#

define sslcert::certificate(
  $ensure=present,
  $source,
  $group='ssl-cert',
  $chain=true,
  $private=undef,
) {
    require sslcert

    file { "/etc/ssl/localcerts/${title}.crt":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => $source,
    }

    if $private {
        # Ideally, we'd pass "content", not "source", and use the file()
        # function, as well as a deny all fileserver rule to not allow anyone
        # to reach key material out of their scope via the fileserver. However,
        # file() is not very sane before Puppet 3.7.0, requiring the full
        # absolute path to files. We should revisit once we get to 3.7+.
        file { "/etc/ssl/private/${name}.key":
            ensure  => $ensure,
            owner   => 'root',
            group   => $group,
            mode    => '0440',
            source  => $private,
        }
    }

    if $chain {
        sslcert::chainedcert { $name:
            ensure => $ensure,
            group  => $group,
        }
    }
}
