# Class: role::toollabs::merlbot_proxy
#
# Provision an nginx server acting as an HTTP -> HTTPS reverse proxy.
#
class role::toollabs::merlbot_proxy() {
    class { '::nginx':
        variant => 'light',
    }
    nginx::site { 'merlbot_proxy':
        content => template('role/toollabs/merlbot_proxy/nginx.conf.erb'),
    }
}
