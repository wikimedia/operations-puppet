class contint::php {

    alternatives::install { 'php':
        link     => '/usr/bin/php',
        path     => '/srv/deployment/integration/slave-scripts/bin/php',
        priority => '60',
        require  => Git::Clone['jenkins CI slave scripts'],
    }

    alternatives::select { 'php':
        path => '/srv/deployment/integration/slave-scripts/bin/php',
    }

}
