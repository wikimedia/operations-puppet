# Class: mobileapps
#
# This class installs and configures mobileapps
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future mobileapps needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
#
class mobileapps() {
    service::node { 'mobileapps':
        port              => 8888,
        has_spec          => true,
        healthcheck_url   => '',
        deployment        => 'scap3',
        deployment_config => true,
    }
}
