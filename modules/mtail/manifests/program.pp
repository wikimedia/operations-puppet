# SPDX-License-Identifier: Apache-2.0
# == Define: mtail::program
#
# Install an mtail "program" to extract metrics from log files.
#
# === Parameters
#
# [*ensure*]
#   The usual metaparameter.
#
# [*content*]
#   The content of the file provided as a string. Either this or
#   'source' must be specified.
#
# [*source*]
#   The content of the file provided as a puppet:/// file reference.
#   Either this or 'content' must be specified.
#
# [*destination*]
#   The directory where the mtail script will be installed provided as a
#   string. Defaults to '/etc/mtail'.
#
define mtail::program(
    Wmflib::Ensure   $ensure      = present,
    Optional[String] $content     = undef,
    Optional[String] $source      = undef,
    Stdlib::Unixpath $destination = '/etc/mtail',
) {
    include mtail

    $basename = regsubst($title, '\W', '-', 'G')
    $filename = "${destination}/${basename}.mtail"

    if !defined(File[$destination]) {
        file { $destination:
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    file { $filename:
        ensure  => $ensure,
        content => $content,
        source  => $source,
        notify  => (defined('$notify') and $notify) ? {
            true  => $notify,
            false => Service['mtail']
        },
        require => File[$destination],
    }
}
