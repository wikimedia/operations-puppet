
# Class: mobileapps
#
# This class installs and configures mobileapps
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future mobileapps needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
#
# === Parameters
#
# [*restbase_uri*]
#   The host/IP where to reach RESTBase
#
class mobileapps(
    $restbase_uri = 'http://restbase.svc.eqiad.wmnet:7231/%DOMAIN%/v1',
) {
    service::node { 'mobileapps':
        port            => 8888,
        config          => template('mobileapps/config.yaml.erb'),
        has_spec        => true,
        healthcheck_url => '',
    }
}
