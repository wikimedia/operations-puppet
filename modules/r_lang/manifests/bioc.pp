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
                    File['/etc/R/biocLite.R']
                ],
                timeout => $timeout,
                command => "/usr/bin/R -e \"source('/etc/R/biocLite.R'); biocLite('${title}', lib = '${library}', suppressUpdates = TRUE, ask = FALSE)\"",
                creates => $pkg_path,
            }
        }
    }
}
