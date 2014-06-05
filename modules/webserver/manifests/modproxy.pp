class webserver::modproxy {

    include webserver::base

    package { 'libapache2-mod-proxy-html':
        ensure => 'present',
    }
}

