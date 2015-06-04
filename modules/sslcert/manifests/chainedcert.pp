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

    $chainfile = "/etc/ssl/localcerts/${title}.chained.crt"

    if $ensure == 'present' {
        # The basic problem here is we want the exec to run if the file doesn't exist,
        #   and also if subcribed inputs change, but puppet provides no succint way
        #   to specify that.  So instead, we'll use two copies of the exec...
        $cmd = "/usr/local/sbin/x509-bundle --skip-root -c ${title}.crt -o ${chainfile}"
        exec { "x509-bundle ${title} creates":
            command     => $cmd,
            cwd         => '/etc/ssl/localcerts',
            creates     => $chainfile,
            require     => [
                File["/etc/ssl/localcerts/${title}.crt"],
                File['/usr/local/sbin/x509-bundle'],
            ],
        }
        exec { "x509-bundle ${title} subscribes":
            command     => $cmd,
            cwd         => '/etc/ssl/localcerts',
            refreshonly => true,
            subscribe   => [
                File["/etc/ssl/localcerts/${title}.crt"],
                File['/usr/local/sbin/x509-bundle'],
            ],
        }

        # set owner/group/permissions on the chained file
        file { $chainfile:
            ensure  => $ensure,
            mode    => '0444',
            owner   => 'root',
            group   => $group,
            require => [
                Exec["x509-bundle ${title} creates"],
                Exec["x509-bundle ${title} subscribes"],
            ],
        }
    } else {
        file { $chainfile:
            ensure => $ensure,
        }
    }
}
