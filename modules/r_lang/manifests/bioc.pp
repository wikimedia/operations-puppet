# = Define: r_lang::bioc
#
# Facilitates installation of R packages from bioconductor.org
#
# === Parameters
#
# [*timeout*]
#     default 300 (seconds) but may need to be larger for R packages with a
#     lot of dependencies that take time to build (e.g. tidyverse)
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
define r_lang::bioc (
    $timeout = 300,
    $ensure = 'present',
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
                    File['/etc/R/biocLite.R']
                ],
                timeout => $timeout,
                command => "/usr/bin/R -e \"source('/etc/R/biocLite.R'); biocLite('${title}', lib = '${library}', suppressUpdates = TRUE, ask = FALSE)\"",
                creates => $pkg_path,
            }
        }
    }
}
