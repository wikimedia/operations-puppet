class torrus::web {

    package { 'torrus-apache2':
        ensure => latest,
        before => Class['webserver::apache::service'],
    }

    @webserver::apache::module { ['perl', 'rewrite']: }
}
