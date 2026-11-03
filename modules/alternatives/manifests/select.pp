# SPDX-License-Identifier: Apache-2.0
# == Define: alternatives::select
#
# Debian's alternatives system uses symlinks to refer generic commands
# to a particular implementation. This Puppet resource lets you specify
# a value for a particular alternative.
#
# === Parameters
#
# [*title*]
#   A generic name, like 'php', which refers via the alternatives system
#   to one of a number of files of similar function.
#
# [*path*]
#   The path to the alternative that should be selected.
#   It must already be installed.
#
# [*only_if_installed*]
#   If true, the alternative will only be selected if the specified path is an existing file.
#   Defaults to false.
#
# === Examples
#
#  alternatives::select { 'php':
#    path => '/usr/bin/hhvm',
#  }
#
define alternatives::select(
    $path,
    $only_if_installed = false,
) {
    $onlyif  = $only_if_installed ? {
        true  => "/usr/bin/test -e ${path}",
        false => undef,
    }
    exec { "update_alternative_${title}":
        command => "/usr/bin/update-alternatives --force --set ${title} ${path}",
        unless  => "/usr/bin/update-alternatives --query ${title} | /bin/grep 'Value: ${path}'",
        onlyif  => $onlyif,
    }
}
