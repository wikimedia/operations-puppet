# == Class: mathoid::packages
#
# Installs the packages needed by Mathoid
#
# NOTE: this is a temporary work-around for the CI to be able to install
# development packages. In the future, we want to have more integration so as to
# run tests as close to production as possible.
#
class mathoid::packages {

    service::packages { 'mathoid':
        pkgs     => ['librsvg2-2'],
        dev_pkgs => ['librsvg2-dev'],
    }

}
