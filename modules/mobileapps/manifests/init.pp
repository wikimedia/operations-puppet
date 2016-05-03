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
#   The host/IP where to reach RESTBase. Default:
#   http://restbase.svc.${::rb_site}.wmnet:7231
# [*mwapi_uri*]
#   The host/IP where to reach the MW API. Default:
#   http://api.svc.${::mw_primary}.wmnet/w/api.php
# [*user_agent*]
#   The user agent header to send to other services. Default: WMF Mobile Content
#   Service
#
class mobileapps(
    $restbase_uri = "http://restbase.svc.${::rb_site}.wmnet:7231",
    $mwapi_uri    = "http://api.svc.${::mw_primary}.wmnet/w/api.php",
    $user_agent   = 'WMF Mobile Content Service',
) {
    service::node { 'mobileapps':
        port            => 8888,
        config          => template('mobileapps/config.yaml.erb'),
        has_spec        => true,
        healthcheck_url => '',
        deployment      => 'scap3',
    }
}
