# = Define: shiny_server::git_pkg
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
define shiny_server::git_pkg (
    $url,
    $ensure = 'present'
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
                require => Shiny_server::Cran_pkg['devtools'],
                command => "/usr/bin/R -e \"devtools::install_git('${url}', lib = '/usr/local/lib/R/site-library')\"",
                creates => $pkg_path,
            }
        }
    }
}
