# == Class: changeprop::packages
#
# Installs the packages needed by graphoid
#
# NOTE: this is a temporary work-around for the CI to be able to install
# development packages. In the future, we want to have more integration so as to
# run tests as close to production as possible.
#
class changeprop::packages {

  service::packages { 'changeprop':
    pkgs     => ['librdkafka++', 'librdkafka'],
    dev_pkgs => ['librdkafka-dev'],
  }

}
