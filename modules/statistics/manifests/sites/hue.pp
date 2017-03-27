# == Class statistics::sites::yarn
# hue.wikimedia.org
#
# This site will be a simple reverse proxy to localhost:8888
#
# Bug: T159527
#
class statistics::sites::hue {
    require ::statistics::web

    include ::apache::mod::proxy_http
    include ::apache::mod::proxy

    # Set up the VirtualHost
    apache::site { 'hue.wikimedia.org':
        content => template('statistics/hue.wikimedia.org.erb'),
    }

    ferm::service { 'hue-http':
        proto => 'tcp',
        port  => '80',
    }

}