class contint::php {

    require ::contint::slave_scripts

    alternatives::install { 'php':
        link     => '/usr/bin/php',
        path     => '/srv/deployment/integration/slave-scripts/bin/php',
        # php7 has prio 70
        priority => '100',
        require  => Git::Clone['jenkins CI slave scripts'],
    }

    alternatives::select { 'php':
        path => '/srv/deployment/integration/slave-scripts/bin/php',
    }

}
