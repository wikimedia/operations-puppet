# Packages required by changeprop and cpjobqueue
class profile::changeprop::packages() {

    service::packages { 'changeprop':
        pkgs     => ['librdkafka++1', 'librdkafka1'],
        dev_pkgs => ['librdkafka-dev'],
    }
}
