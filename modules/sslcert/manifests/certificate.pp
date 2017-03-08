# == Define: sslcert::certificate
#
# Installs a X.509 certificate -and, optionally, its private key- to the
# system's predefined local certificate directory.
#
# Certificates are installed to the custom-made directory /etc/ssl/localcerts
# rather than /etc/ssl/certs, as the latter is used often as the CA path in
# many default configurations and examples on the web.
#
# The input pathnames for the cert and the private key are fixed at our
# standard locations and based on the resource's title.  For example, if the
# resource title is "foo", the cert source will be "modules/sslcert/files/certs/foo.crt",
# and the private key should be located at "modules/secret/secrets/ssl/foo.key"
# in the private repository.
#
# === Parameters
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
# [*skip_private*]
#   If true, no private key is installed by standard means/paths.  The default
#   is false.
#
# === Examples
#
#  sslcert::certificate { 'www.example.org':
#      ensure => present,
#      source => 'puppet:///modules/mysite/www.example.org.crt',
#  }
#

define sslcert::certificate(
  $ensure=present,
  $group='ssl-cert',
  $chain=true,
  $skip_private=false,
) {
    require sslcert
    require sslcert::dhparam

    # lint:ignore:puppet_url_without_modules
    # FIXME
    if $ensure != 'absent' {
        file { "/etc/ssl/localcerts/${title}.crt":
            ensure => $ensure,
            owner  => 'root',
            group  => $group,
            mode   => '0444',
            source => "puppet:///modules/sslcert/certs/${title}.crt",
        }
    } else {
        file { "/etc/ssl/localcerts/${title}.crt":
            ensure => $ensure,
        }
    }
    # lint:endignore

    if !$skip_private {
        file { "/etc/ssl/private/${title}.key":
            ensure    => $ensure,
            owner     => 'root',
            group     => $group,
            mode      => '0440',
            show_diff => false,
            backup    => false,
            content   => secret("ssl/${title}.key"),
        }
    }

    if $chain {
        sslcert::chainedcert { $title:
            ensure => $ensure,
            group  => $group,
        }
    }
}
