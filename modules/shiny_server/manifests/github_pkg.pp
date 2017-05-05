# = Define: shiny_server::github_pkg
#
# Facilitates installation of R packages from GitHub.
#
# == Required Parameters
#
# [*repo*]
#     needs to be of the form 'username/reponame'
#
# === Optional Parameters
#
# [*ensure*]
#     default 'present' but also accepts 'absent'
#     hoping to support 'latest' eventually
#
define shiny_server::github_pkg (
    $repo,
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
                command => "/usr/bin/R -e \"devtools::install_github('${repo}', lib = '/usr/local/lib/R/site-library')\"",
                creates => $pkg_path,
            }
        }
    }
}
