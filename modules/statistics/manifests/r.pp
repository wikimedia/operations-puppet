# = Class: statistics::r
#
# Sets up R from upstream for statistics users
class statistics::r {
    apt::repository { 'cran-rstudio':
        uri        => 'http://cran.rstudio.com/bin/linux/debian',
        dist       => 'jessie-cran3',
        source     => false,
        keyfile    => 'puppet:///modules/statistics/r-debs.gpg',
    }

    $proxy_ensure = $proxy ? {
        undef   => 'absent',
        default => 'present'
    }

    apt::conf { 'cran-org-proxy':
        ensure   => $proxy_ensure,
        priority => '80',
        key      => 'Acquire::http::Proxy::cran.rstudio.com',
        value    => $proxy,
    }

    ensure_packages([
        'r-base',
        'r-base-dev',      # Needed for R packages that have to compile C++ code; see T147682
        'r-cran-rmysql',
        'r-recommended'    # CRAN-recommended packages (e.g. MASS, Matrix, boot)
    ])

}
