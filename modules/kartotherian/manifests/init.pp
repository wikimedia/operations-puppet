# Class: kartotherian
#
# This class installs and configures kartotherian
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future kartotherian needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
class kartotherian() {
    service::node { 'kartotherian':
        port   => 4000,
        config => template('kartotherian/config.yaml.erb'),
    }
}
