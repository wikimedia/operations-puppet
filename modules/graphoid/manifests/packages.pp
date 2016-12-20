# == Class: graphoid::packages
#
# Installs the packages needed by graphoid
#
# NOTE: this is a temporary work-around for the CI to be able to install
# development packages. In the future, we want to have more integration so as to
# run tests as close to production as possible.
#
class graphoid::packages {

    require ::mediawiki::packages::fonts

    service::packages { 'graphoid':
        pkgs     => ['libcairo2', 'libgif4', 'libjpeg62-turbo', 'libpango1.0-0'],
        dev_pkgs => ['libcairo2-dev', 'libgif-dev', 'libpango1.0-dev',
        'libjpeg62-turbo-dev'],
    }

}
