
# Class: changeprop
#
# This class installs and configures changeprop
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future changeprop needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
class changeprop() {
    service::node { 'changeprop':
        port   => 7272,
        config => template('changeprop/config.yaml.erb'),
    }
}
