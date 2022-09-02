# SPDX-License-Identifier: Apache-2.0
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
# resource title is "foo", the cert source will be "files/ssl/foo.crt", and the
# private key should be located at "modules/secret/secrets/ssl/foo.key" in the
# private repository. Additionally, the certificate will be searched in the same
# location as the private key (with .crt instead of .key).
#
# Unless the "use_cergen" parameter is set to true, in which case the private key
# is expected at "modules/secret/secrets/certificates/foo/foo.key.private.pem.
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
# [*use_cergen*]
#   If true, private keys are expected in the location used by cergen:
#   modules/secret/secrets/certificates/foo/foo.key.private.pem.
#   The default is false.
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
  $use_cergen=false,
) {
    require sslcert
    require sslcert::dhparam

    if $use_cergen {
        $private_key_source="certificates/${title}/${title}.key.private.pem"
    } else {
        $private_key_source="ssl/${title}.key"
    }


    # Look for a matching certificate on the puppet master first, and
    # fallback to puppet.git if that fails.
    $secrets_base = '/etc/puppet/private/modules/secret/secrets'
    if !$use_cergen and find_file("${secrets_base}/ssl/${title}.crt") {
        $cert_content = secret("ssl/${title}.crt")
        $cert_source = undef
    } elsif $use_cergen and find_file("${secrets_base}/certificates/${title}/${title}.crt.pem") {
        $cert_content = secret("certificates/${title}/${title}.crt.pem")
        $cert_source = undef
    } else {
        $cert_content = undef
        $cert_source = "puppet:///modules/profile/ssl/${title}.crt"
    }

    if $ensure != 'absent' {
        file { "/etc/ssl/localcerts/${title}.crt":
            ensure       => $ensure,
            owner        => 'root',
            group        => $group,
            mode         => '0444',
            content      => $cert_content,
            source       => $cert_source,
            # make sure we're not accidentally shipping combined
            # certs (private + public)
            validate_cmd => '/bin/sh -c "! grep --quiet \"PRIVATE KEY\" \"%\""',
        }
    } else {
        file { "/etc/ssl/localcerts/${title}.crt":
            ensure => $ensure,
        }
    }

    if !$skip_private {
        file { "/etc/ssl/private/${title}.key":
            ensure    => $ensure,
            owner     => 'root',
            group     => $group,
            mode      => '0440',
            show_diff => false,
            backup    => false,
            content   => secret($private_key_source),
        }
    }

    if $chain {
        sslcert::chainedcert { $title:
            ensure       => $ensure,
            group        => $group,
            skip_private => $skip_private,
        }
    }
}
