# == Define: sslcert::chainedcert
#
# Creates a X.509 certificate chain based on an existing certificate on the
# system. Implicitly depends on sslcert::certificate.
#
# If generating a default chain cert, the chained certificate is written to
# /etc/ssl/localcerts as ${certname}.chained.crt. The chain is constructed
# automatically, up to a self-signed CA as found in the /etc/ssl/certs system
# directory. If multiple paths to a CA exist -as is the case with cross-signed
# authorities- the shortest path is picked. The top-most certificate (root CA)
# is NOT included, to minimize the size's chain for performance reasons, with
# no loss of usability.
#
# If generating an OCSP chain cert, the OCSP cert file is written to
# /etc/ssl/localcerts as ${certname}.ocsp.crt.  While the chained file
# contains the input cert and all signers except the root, the OCSP cert does
# *not* contain the input cert, but does include the root.
#
# === Parameters
#
# [*certname*]
#   Name of the related sslcert::cerfificate resource,
#   e.g. "pinkunicorn.wikimedia.org".
#
# [*ensure*]
#   If 'present', the certificate chain will be installed; if 'absent', it
#   will be removed. The default is 'present'.
#
# [*ocsp*]
#   Boolean, default false.  If true, will generate an OCSP cert file rather
#   than a regular chained cert.
#
# === Examples
#
#  sslcert::chainedcert { 'pinkunicorn.wikimedia.org':
#    ensure => present,
#  }
#

define sslcert::chainedcert(
  $certname,
  $ensure=present,
  $group='ssl-cert',
  $ocsp=false,
) {
    require sslcert

    validate_ensure($ensure)

    if $ocsp {
        $ctype = 'ocsp'
        $arg  = '--skip-self'
    }
    else {
        $ctype = 'chained'
        $arg  = '--skip-root'
    }

    if $ensure == 'present' {
        exec { "x509-bundle ${certname}-${ctype}":
            creates => "/etc/ssl/localcerts/${certname}.${ctype}.crt",
            command => "/usr/local/sbin/x509-bundle ${arg} -c ${certname}.crt -o ${certname}.${ctype}.crt",
            cwd     => '/etc/ssl/localcerts',
            require => Sslcert::Certificate[$certname],
        }

        # set owner/group/permissions on the file
        file { "/etc/ssl/localcerts/${certname}.${ctype}.crt":
            ensure  => $ensure,
            mode    => '0444',
            owner   => 'root',
            group   => $group,
            require => Exec["x509-bundle ${certname}-${ctype}"],
        }
    } else {
        file { "/etc/ssl/localcerts/${certname}.${ctype}.crt":
            ensure => $ensure,
        }
    }
}
