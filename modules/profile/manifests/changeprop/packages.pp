# Packages required by changeprop and cpjobqueue
class profile::changeprop::packages() {
    # Include this so we can reference $::service::configuration::use_dev_pkgs
    class { '::service::configuration': }

    $librdkafka_version = $::lsbdistcodename ? {
        'jessie'  => '0.9.4-1~jessie1',
        'stretch' => '0.9.3-1',
    }

    # We are only installing librdkafka packages here, so make all
    # in scope package resources ensure the version.
    # See: https://phabricator.wikimedia.org/T185016
    Package {
        ensure => $librdkafka_version
    }
    # Need to use package resource directly, so we can ensure version.
    if !defined(Package['librdkafka1']) {
        package { 'librdkafka1': }
    }
    if !defined(Package['librdkafka++1']) {
        package { 'librdkafka++1': }
    }
    if $::service::configuration::use_dev_pkgs and !defined(Package['librdkafka-dev']) {
        package { 'librdkafka-dev': }
    }

    # TODO: restore use of service::packages when we no longer need to
    # ensure a specific librdkafka version.
    # service::packages { 'changeprop':
    #     pkgs     => ['librdkafka++1', 'librdkafka1'],
    #     dev_pkgs => ['librdkafka-dev'],
    # }
}
