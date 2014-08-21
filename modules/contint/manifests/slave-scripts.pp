class contint::slave-scripts {

    if $::realm == 'production' {
        fail("contint::slave-scripts must not be used in production. Slaves are already Trebuchet deployment targets.")
    }

    git::clone { 'jenkins CI slave scripts':
        ensure             => 'latest',
        directory          => '/srv/deployment/integration/slave-scripts',
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/jenkins.git',
        recurse_submodules => true,
    }

    # We can not Trebuchet on labs, so use the good old git::clone
    git::clone { 'jenkins CI kss':
        ensure             => 'latest',
        directory          => '/srv/deployment/integration/kss',
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/kss.git',
        recurse_submodules => true,
    }
    git::clone { 'jenkins CI Composer':
        ensure             => 'latest',
        directory          => '/srv/deployment/integration/composer',
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/composer.git',
        recurse_submodules => true,
    }
    git::clone { 'jenkins CI phpcs':
        ensure             => 'latest',
        directory          => '/srv/deployment/integration/phpcs',
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/phpcs.git',
        recurse_submodules => true,
    }
    git::clone { 'jenkins CI phpcs MediaWiki standard':
        ensure    => 'latest',
        directory => '/srv/deployment/integration/mediawiki-tools-codesniffer',
        origin    => 'https://gerrit.wikimedia.org/r/mediawiki/tools/codesniffer',
    }
    git::clone { 'jenkins CI phpunit':
        ensure             => 'latest',
        directory          => '/srv/deployment/integration/phpunit',
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/phpunit.git',
        recurse_submodules => true,
    }
}
