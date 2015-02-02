# == Define: sslcert::chainedcert
#
# Creates a X.509 certificate chain based on an existing certificate on the
# system. Implicitly depends on sslcert::certificate.
#
# The chained certificate is written to /etc/ssl/localcerts as
# ${title}.chained.crt. The chain is constructed automatically, up to a
# self-signed CA as found in the /etc/ssl/certs system directory. If multiple
# paths to a CA exist -as is the case with cross-signed authorities- the
# shortest path is picked. The top-most certificate (root CA) is NOT included,
# to minimize the size's chain for performance reasons, with no loss of
# usability.
#
# === Parameters
#
# [*ensure*]
#   If 'present', the certificate chain will be installed; if 'absent', it
#   will be removed. The default is 'present'.
#
# === Examples
#
#  sslcert::chainedcert { 'pinkunicorn.wikimedia.org':
#    ensure => present,
#  }
#

define sslcert::chainedcert(
  $ca,
  $ensure=present,
  $group='ssl-cert',
) {
    require sslcert

    validate_ensure($ensure)

    if $ensure == 'present' {
        exec { "${title}_create_chained_cert":
            creates => "/etc/ssl/localcerts/${title}.chained.crt",
            command => "/bin/cat /etc/ssl/localcerts/${title}.crt ${ca} > /etc/ssl/localcerts/${title}.chained.crt",
            cwd     => '/etc/ssl/certs',
            require => Sslcert::Certificate[$title],
        }

        # set owner/group/permissions on the chained file
        file { "/etc/ssl/localcerts/${title}.chained.crt":
            ensure  => $ensure,
            mode    => '0444',
            owner   => 'root',
            group   => $group,
            require => Exec["${title}_create_chained_cert"],
        }
    } else {
        file { "/etc/ssl/localcerts/${title}.chained.crt":
            ensure => $ensure,
        }
    }
}
