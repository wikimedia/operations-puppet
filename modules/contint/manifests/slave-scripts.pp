class contint::slave-scripts {

    if $::realm == 'production' {
        fail("contint::slave-scripts must not be used in production. Slaves are already git-deploy deployment targets.")
    }

    git::clone { 'jenkins CI slave scripts':
        ensure    => 'latest',
        directory => '/srv/deployment/integration/slave-scripts',
        origin    => 'https://gerrit.wikimedia.org/r/p/integration/jenkins.git',
    }

}
