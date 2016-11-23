# == Class: trendingedits::packages
#
# Installs the packages needed by the trending edits service
#
# NOTE: this is a temporary work-around for the CI to be able to install
# development packages. In the future, we want to have more integration so as to
# run tests as close to production as possible.
#
class trendingedits::packages {

  service::packages { 'trendingedits':
    pkgs     => ['librdkafka++1', 'librdkafka1'],
    dev_pkgs => ['librdkafka-dev'],
  }

}
