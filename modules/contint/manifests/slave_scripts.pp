# == Class contint::slave_scripts
#
# Scripts and helpers used by CI.
#
class contint::slave_scripts {

    if $::realm == 'production' {
        fail('contint::slave_scripts must not be used in production. Slaves are already Trebuchet deployment targets.')
    }

    require ::contint::deployment_dir

    git::clone { 'jenkins CI slave scripts':
        ensure             => 'latest',
        directory          => '/srv/deployment/integration/slave-scripts',
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/jenkins.git',
        recurse_submodules => true,
    }
}
