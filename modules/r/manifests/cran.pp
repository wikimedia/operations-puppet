# = Define: r::cran
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
define r::cran (
    $timeout = 300,
    $ensure  = 'present',
    $mirror  = 'https://cloud.r-project.org',
    $library = '/usr/local/lib/R/site-library'
) {
    $pkg_path = "${library}/${title}"
    case $ensure {
        'absent': {
            exec { "remove-${title}":
                command => "/usr/bin/R -e \"remove.packages('${title}', lib = '${library}')\"",
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
                command => "/usr/bin/R -e \"install.packages('${title}', repos = c(CRAN = '${mirror}'), lib = '${library}')\"",
                creates => $pkg_path,
            }
        }
    }
}
