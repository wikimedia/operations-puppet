# SPDX-License-Identifier: Apache-2.0
# == Define: sslcert::ocsp::conf
#
# Installs a cronjob that periodically fetches an OCSP response for a
# certificate (or a bundle of certificates) and stores it to a well-known path,
# under /var/cache/ocsp/$title.ocsp.
#
# === Parameters
#
# [*ensure*]
#   If 'present', the cronjob will be installed. The default is 'present'.
#
# [*certs*]
#   An array of certificates to fetch a *single* OCSP response for.
#   The default is a single-element array with $title.
#
# [*proxy*]
#   If defined, an HTTP proxy to use to fetch the certificate.
#
# === Examples
#
#  sslcert::ocsp::conf { 'www.example.org':
#      proxy => 'proxy.example.org:8080',
#  }
#

define sslcert::ocsp::conf(
  Wmflib::Ensure   $ensure = present,
  Array[String]    $certs  = [$title],
  Optional[String] $proxy  = undef,
) {
    if !defined(Class['sslcert::ocsp::init']) {
        fail('sslcert::ocsp::conf should only be used once the sslcert::ocsp::init class is declared.')
    }

    $output = "/var/cache/ocsp/${title}.ocsp"
    $config = "/etc/update-ocsp.d/${title}.conf"

    file { $config:
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('sslcert/update-ocsp.erb'),
        require => Sslcert::Certificate[$certs],
    }

    if $ensure == 'present' {
        # initial creation on the first puppet run
        exec { "${title}-create-ocsp":
            command => "/usr/local/sbin/update-ocsp --config ${config}",
            creates => $output,
            require => File[$config],
        }
    } else {
        file { $output:
            ensure => absent,
        }
    }
}
