# == Define: sslcert::std_cert
#
# Installs a X.509 certificate and its private key to the system's predefined
# local certificate directory.
#
# Certificates are installed to the custom-made directory /etc/ssl/localcerts
# rather than /etc/ssl/certs, as the latter is used often as the CA path in
# many default configurations and examples on the web.
#
# The input pathnames for the cert and the private key are fixed at our
# standard locations and based on the resource's name.  For example, if the
# resource name is "foo", the cert source will be "files/ssl/foo.crt", and
# the private key should be located at "secrets/ssl/foo.key" in the private
# repository.
#
# === Parameters
#
# [*ensure*]
#   If 'present', the certificate will be installed; if 'absent', it will be
#   removed. The default is 'present'.
#
# [*group*]
#   The group name the resulting key and cert file will be owned by. Defaults
#   to the well-known 'ssl-cert'.
#
# [*chain*]
#   If true, create also a chained version of the certificate, by calling into
#   sslcert::chainedcert. The default is true.
#
# === Examples
#
#  sslcert::std_cert { 'www.example.org': }
#

define sslcert::std_cert(
  $ensure=present,
  $group='ssl-cert',
  $chain=true,
) {
    require sslcert
    require sslcert::dhparam

    file { "/etc/ssl/localcerts/${name}.crt":
        ensure => $ensure,
        owner  => 'root',
        group  => $group,
        mode   => '0444',
        source => "puppet:///files/ssl/${name}.crt",
    }

    file { "/etc/ssl/private/${name}.key":
        ensure    => $ensure,
        owner     => 'root',
        group     => $group,
        mode      => '0440',
        show_diff => false,
        backup    => false,
        content   => secret("ssl/${name}.key"),
    }

    if $chain {
        sslcert::chainedcert { $name:
            ensure => $ensure,
            group  => $group,
        }
    }
}
