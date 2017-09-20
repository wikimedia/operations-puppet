# == Class contint::slave_scripts
#
# Scripts and helpers used by CI.
#
class contint::slave_scripts {

    require ::contint::deployment_dir

    git::clone { 'jenkins CI slave scripts':
        ensure             => 'latest',
        directory          => '/srv/deployment/integration/slave-scripts',
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/jenkins.git',
        recurse_submodules => true,
    }
}
