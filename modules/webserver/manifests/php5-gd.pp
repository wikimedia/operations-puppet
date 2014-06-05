class webserver::php5-gd {

    include webserver::base

    package { 'php5-gd':
        ensure => 'present',
    }
}

