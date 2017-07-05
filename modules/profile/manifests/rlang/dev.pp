# == Class profile::rlang::dev
#
# A profile that configures the environment for installing R packages from
# sources like Git/GitHub and enables checking package sources with unit tests
# and lint checking.
#
class profile::rlang::dev {

    # `include ::r` would not install devtools, which would mean that we could
    # not install R packages from Git/GitHub
    class { 'r':
        devtools => true,
    }

    # For unit testing and lint checking:
    $test_packages = [
        'testthat',
        'lintr',
    ]
    r::cran { $test_packages: }

}
