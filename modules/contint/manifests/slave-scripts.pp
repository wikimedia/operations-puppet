class contint::slave-scripts {

    if $::realm == 'production' {
        fail("contint::slave-scripts must not be used in production. Slaves are already git-deploy deployment targets.")
    }

    git::clone { 'jenkins CI slave scripts':
        ensure    => 'latest',
        directory => '/srv/deployment/integration/slave-scripts',
        origin    => 'https://gerrit.wikimedia.org/r/p/integration/jenkins.git',
    }

    # We can not git-deploy on labs, so use the good old git::clone
    git::clone { 'jenkins CI kss':
        ensure    => 'latest',
        directory => '/srv/deployment/integration/kss',
        origin    => 'https://gerrit.wikimedia.org/r/p/integration/kss.git',
    }
    git::clone { 'jenkins CI phpcs':
        ensure    => 'latest',
        directory => '/srv/deployment/integration/phpcs',
        origin    => 'https://gerrit.wikimedia.org/r/p/integration/phpcs.git',
    }
    git::clone { 'jenkins CI phpunit':
        ensure    => 'latest',
        directory => '/srv/deployment/integration/phpunit',
        origin    => 'https://gerrit.wikimedia.org/r/p/integration/phpunit.git',
    }
}
