# == Define: sslcert::certificate
#
# Installs a X.509 certificate -and, optionally, its private key- to the
# system's predefined local certificate directory.
#
# Certificates are installed to the custom-made directory /etc/ssl/localcerts
# rather than /etc/ssl/certs, as the latter is used often as the CA path in
# many default configurations and examples on the web.
#
# === Parameters
#
# [*source*]
#   Path to file containing the X.509 certificate file.
#
# [*ensure*]
#   If 'present', the certificate will be installed; if 'absent', it will be
#   removed. The default is 'present'.
#
# [*group*]
#   The group name the resulting certificate file will be owned by. Defaults to
#   the well-known 'ssl-cert'.
#
# [*chain*]
#   If true, create also a chained version of the certificate, by calling into
#   sslcert::chainedcert. The default is true.
#
# [*private*]
#   The content of the private key to the certificate. Optional.
#
# === Examples
#
#  sslcert::certificate { 'www.example.org':
#      ensure => present,
#      source => 'puppet:///modules/mysite/www.example.org.crt',
#  }
#

define sslcert::certificate(
  $source,
  $ensure=present,
  $group='ssl-cert',
  $chain=true,
  $private=undef,
) {
    require sslcert

    file { "/etc/ssl/localcerts/${title}.crt":
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => $source,
    }

    if $private {
        # Ideally, we'd pass "content", not "source", and use the file()
        # function, as well as a deny all fileserver rule to not allow anyone
        # to reach key material out of their scope via the fileserver. However,
        # file() is not very sane before Puppet 3.7.0, requiring the full
        # absolute path to files. We should revisit once we get to 3.7+.
        file { "/etc/ssl/private/${name}.key":
            ensure => $ensure,
            owner  => 'root',
            group  => $group,
            mode   => '0440',
            source => $private,
        }
    }

    if $chain {
        sslcert::chainedcert { $name:
            ensure => $ensure,
            group  => $group,
        }
    }
}
