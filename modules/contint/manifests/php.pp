class contint::php {

    alternatives::install { 'php':
        link     => '/usr/bin/php',
        path     => '/srv/deployment/integration/slave-scripts/bin/php',
        priority => '60',
    }

}
