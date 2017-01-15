# == Class contint::phpunit
#
# Install PHPUnit using a Git repository from Gerrit.
#
# Most jobs are using composer instead. But operations/mediawiki-config
# still depends on a local copy.
class contint::phpunit {

    require ::contint::deployment_dir

    git::clone { 'jenkins CI phpunit':
        ensure             => 'latest',
        directory          => '/srv/deployment/integration/phpunit',
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/phpunit.git',
        recurse_submodules => true,
    }
}
