# == Define: sslcert::chainedcert
#
# Creates a X.509 certificate chain based on an existing certificate on the
# system.
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
# [*group*]
#   The group name the resulting certificate file will be owned by. Defaults to
#   the well-known 'ssl-cert'.
#
# === Examples
#
#  sslcert::chainedcert { 'www.example.org':
#      ensure => present,
#  }
#

define sslcert::chainedcert(
  $ensure=present,
  $group='ssl-cert',
) {
    require sslcert

    validate_ensure($ensure)

    $chainedfile = "/etc/ssl/localcerts/${title}.chained.crt"
    $chainfile = "/etc/ssl/localcerts/${title}.chain.crt"

    if $ensure == 'present' {
        $inpath = "/etc/ssl/localcerts/${title}.crt"
        $script = '/usr/local/sbin/x509-bundle'
        exec { "x509-bundle ${title}-chained":
            path    => 'bin:/usr/bin',
            cwd     => '/etc/ssl/localcerts',
            command => "${script} --skip-root -c ${inpath} -o ${chainedfile}",
            unless  => "[ ${chainedfile} -nt ${inpath} -a ${chainedfile} -nt ${script} ]",
            require => [ File[$inpath], File[$script] ],
        }
        exec { "x509-bundle ${title}-chain":
            path    => 'bin:/usr/bin',
            cwd     => '/etc/ssl/localcerts',
            command => "${script} --skip-root --skip-first -c ${inpath} -o ${chainfile}",
            unless  => "[ ${chainfile} -nt ${inpath} -a ${chainfile} -nt ${script} ]",
            require => [ File[$inpath], File[$script] ],
        }

        # set owner/group/permissions on the chained/chain files
        file { $chainedfile:
            ensure  => $ensure,
            mode    => '0444',
            owner   => 'root',
            group   => $group,
            require => Exec["x509-bundle ${title}-chained"],
        }
        file { $chainfile:
            ensure  => $ensure,
            mode    => '0444',
            owner   => 'root',
            group   => $group,
            require => Exec["x509-bundle ${title}-chain"],
        }
    } else {
        file { [$chainedfile, $chainfile]:
            ensure => $ensure,
        }
    }
}
