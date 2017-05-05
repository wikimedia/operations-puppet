# = Define: shiny_server::cran_pkg
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
define shiny_server::cran_pkg (
    $timeout = 300,
    $ensure = 'present',
    $mirror = 'https://cloud.r-project.org'
) {
    $pkg_path = "/usr/local/lib/R/site-library/${title}"
    case $ensure {
        'absent': {
            exec { "remove-${title}":
                command => "/usr/bin/R -e \"remove.packages('${title}', lib = '/usr/local/lib/R/site-library')\"",
                notify  => Service['shiny-server'],
            }
        }
        default: {
            exec { "package-${title}":
                require => [
                    Package['r-base'],
                    Package['r-base-dev']
                ],
                timeout => $timeout,
                command => "/usr/bin/R -e \"install.packages('${title}', repos = c(CRAN = '${mirror}'), lib = '/usr/local/lib/R/site-library')\"",
                creates => $pkg_path,
            }
        }
    }
}
