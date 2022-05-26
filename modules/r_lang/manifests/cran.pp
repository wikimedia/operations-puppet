# SPDX-License-Identifier: Apache-2.0
# = Define: r_lang::cran
#
# Facilitates installation of R packages from Comprehensive R Archive Network.
#
# == Parameters
#
# [*timeout*]
#     default 300 (seconds) but may need to be larger for R packages with a
#     lot of dependencies that take time to build (e.g. tidyverse)
#
# [*ensure*]
#     default 'present' but also accepts 'absent'
#     hoping to support 'latest' eventually
#
# [*mirror*]
#     The CRAN mirror to use, by default uses automatic redirection to servers
#     worldwide (https://cloud.r-project.org) but can be overridden. Refer to
#     https://cran.r-project.org/mirrors.html for the full list of mirrors.
#
# [*library*]
#     default '/usr/local/lib/R/site-library', used
#     for specifying the path of the library for
#     installing the R package
#
define r_lang::cran (
    $timeout = 300,
    $ensure  = 'present',
    $mirror  = 'https://cloud.r-project.org',
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
                require => [
                    Package['r-base'],
                    Package['r-base-dev']
                ],
                timeout => $timeout,
                command => "/usr/bin/R -e \"install.packages('${title}', repos = c(CRAN = '${mirror}'), lib = '${library}')\"",
                creates => $pkg_path,
            }
        }
    }
}
