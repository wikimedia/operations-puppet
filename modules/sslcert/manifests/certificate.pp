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
# [*content*]
#   If defined, will be used as the content of the X.509 certificate file.
#   Undefined by default. Mutually exclusive with 'source'.
#
# [*source*]
#   Path to file containing the X.509 certificate file. Undefined by default.
#   Mutually exclusive with 'content'.
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
  $group='ssl-cert',
  $source=undef,
  $content=undef,
  $private=undef,
) {
    require sslcert

    if $source == undef and $content == undef  {
        fail('you must provide either "source" or "content"')
    }

    if $source != undef and $content != undef  {
        fail('"source" and "content" are mutually exclusive')
    }

    file { "/etc/ssl/localcerts/${title}.crt":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => $source,
        content => $content,
    }

    if $private {
        # only support "content"; serving sensitive material over the puppet
        # fileserver isn't a very good security practice
        file { "/etc/ssl/private/${name}.key":
            ensure  => $ensure,
            owner   => 'root',
            group   => $group,
            mode    => '0440',
            # content => $private, # content variant is broken, fixing the easy way for now...
            source => $private,
        }
    }
}
