# = Class: r_lang
#
# Class containing stuff for installing R and its packages from different sources:
# - r_lang::cran for installing from Comprehensive R Archive Network (CRAN)
# - r_lang::git for installing from any Git repository (e.g. Gerrit)
# - r_lang::github for installing from a GitHub-hosted repository
# - r_lang::bioc for installing from Bioconductor
#
# Also provides a utility script for updating library of installed R packages.
#
# Heads-up that by default r_lang::git and r_lang::github are technically not available
# because those require the R package 'devtools' which is not installed by
# default and cannot be installed because its dependencies are not installed
# unless the `$devtools$` parameter is set to `true`.
#
class r_lang (
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
        source => 'puppet:///modules/r_lang/update-library.R',
    }
    # R script for installing packages from Bioconductor:
    file { '/etc/R/biocLite.R':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/r_lang/biocLite.R',
    }

    if $devtools {
        $devtools_essentials = [
            'git-core',             # for git2r
            'libxml2-dev',          # for xml2
            'libssl-dev',           # for openssl
            'libcurl4-openssl-dev', # for curl
            'libssh2-1-dev'         # for git2r
        ]
        require_package($devtools_essentials)

        r_lang::cran { 'openssl':
            require => Package['libssl-dev'],
        }

        $r_packages = [
            'xml2',
            'curl',
            'devtools',
        ]
        r_lang::cran { $r_packages:
            require => [
                R_lang::Cran['openssl']
            ],
        }
    }

}
