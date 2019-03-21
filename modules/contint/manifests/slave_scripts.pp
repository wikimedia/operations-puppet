# == Class contint::slave_scripts
#
# Scripts and helpers used by CI.
#
class contint::slave_scripts {

    require ::contint::deployment_dir

    git::clone { 'jenkins CI slave scripts':
        ensure             => 'latest',
        directory          => '/srv/deployment/integration/slave-scripts',
        origin             => 'https://gerrit.wikimedia.org/r/integration/jenkins.git',
        recurse_submodules => true,
    }
    # bin/mw-fetch-composer-dev.sh requires jq
    require_package(['jq'])
}
