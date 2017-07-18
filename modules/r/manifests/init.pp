# = Class: r
#
# Class containing stuff for installing R and its packages from different sources:
# - r::cran for installing from Comprehensive R Archive Network (CRAN)
# - r::git for installing from any Git repository (e.g. Gerrit)
# - r::github for installing from a GitHub-hosted repository
#
# Also provides a utility script for updating library of installed R packages.
#
class r {

    $cran_mirror = 'https://cran.cnr.berkeley.edu'

    $essentials = [
        'r-base', 'r-base-dev', 'r-recommended',
        # To get higher performance for linear algebra operations
        'libopenblas-dev',
        # For devtools:
        'libssl-dev', 'libcurl4-openssl-dev', 'libicu-dev', 'libssh2-1-dev'
    ]
    require_package($essentials)

    file { '/usr/local/lib/R/site-library':
        ensure => 'directory',
        owner  => 'root',
        group  => 'staff',
        mode   => '0770',
    }

    r::cran { 'openssl':
        require => Package['libssl-dev'],
        mirror  => $cran_mirror
    }

    $r_packages = [
        'xml2',
        'testthat',
        'devtools'
    ]
    r::cran { $r_packages:
        require => [
            Package['libxml2'],
            Package['libxml2-dev'],
            R::Cran['openssl'],
            Package['libcurl4-openssl-dev']
        ],
        mirror  => $cran_mirror,
    }

    # R script for updating any particular installed R package:
    file { '/etc/R/update-library.R':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/r/update-library.R'
    }

}
