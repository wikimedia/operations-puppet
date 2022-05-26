# SPDX-License-Identifier: Apache-2.0
# = Define: r_lang::git
#
# Facilitates installation of R packages from a remote Git repository.
#
# == Required Parameters
#
# [*url*]
#     the URL of the git repository to install from
#
# === Optional Parameters
#
# [*ensure*]
#     default 'present' but also accepts 'absent'
#     hoping to support 'latest' eventually
#
# [*library*]
#     default '/usr/local/lib/R/site-library', used
#     for specifying the path of the library for
#     installing the R package
#
define r_lang::git (
    $url,
    $ensure = 'present',
    $library = '/usr/local/lib/R/site-library'
) {
    $pkg_path = "${library}/${title}"
    case $ensure {
        'absent': {
            # Since r_lang can be used on machines that don't have shiny_server,
            # we only want a package removal to restart the Shiny Server service
            # if the service actually exists:
            $remove_notify = defined(Service['shiny-server']) ? {
                true    => Service['shiny-server'],
                default => Undef,
            }
            exec { "remove-${title}":
                command => "/usr/bin/R -e \"remove.packages('${title}', lib = '${library}')\"",
                notify  => $remove_notify,
                onlyif  => "test -d ${pkg_path}",
            }
        }
        default: {
            exec { "package-${title}":
                require => R_lang::Cran['devtools'],
                command => "/usr/bin/R -e \"devtools::install_git('${url}', lib = '${library}')\"",
                creates => $pkg_path,
            }
        }
    }
}
