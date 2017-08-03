# = Class: r
#
# Class containing stuff for installing R and its packages from different sources:
# - r::cran for installing from Comprehensive R Archive Network (CRAN)
# - r::git for installing from any Git repository (e.g. Gerrit)
# - r::github for installing from a GitHub-hosted repository
#
# Also provides a utility script for updating library of installed R packages.
#
# Heads-up that by default r::git and r::github are technically not available
# because those require the R package 'devtools' which is not installed by
# default and cannot be installed because its dependencies are not installed
# unless the `$devtools$` parameter is set to `true`.
#
class r (
    $devtools = false
) {

    $essentials = [
        'r-base', 'r-base-dev', 'r-recommended',
        # To get higher performance for linear algebra operations
        'libopenblas-dev'
    ]
    require_package($essentials)

    file { '/usr/local/lib/R/site-library':
        ensure => 'directory',
        owner  => 'root',
        group  => 'staff',
        mode   => '0770',
    }

    # R script for updating any particular installed R package:
    file { '/etc/R/update-library.R':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/r/update-library.R',
    }

    if $devtools {
        $devtools_essentials = [
            'git-core',             # for git2r
            'libxml2',              # for xml2
            'libxml2-dev',          # for xml2
            'libssl-dev',           # for openssl
            'libcurl4-openssl-dev', # for curl
            'libssh2-1-dev'         # for git2r
        ]
        require_package($devtools_essentials)

        r::cran { 'openssl':
            require => Package['libssl-dev'],
        }

        $r_packages = [
            'xml2',
            'curl',
            'devtools',
        ]
        r::cran { $r_packages:
            require => [
                Package['git-core'],
                Package['libxml2'],
                Package['libxml2-dev'],
                R::Cran['openssl'],
                Package['libcurl4-openssl-dev']
            ],
        }
    }

}
