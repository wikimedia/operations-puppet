# Class: tilerator
#
# This class installs and configures tilerator
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future tilerator needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
class tilerator() {
    service::node { 'tilerator':
        port   => 4100,
        config => template('tilerator/config.yaml.erb'),
    }
}
