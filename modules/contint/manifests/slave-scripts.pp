class contint::slave-scripts {

    git::clone { 'jenkins CI slave scripts':
        ensure    => 'latest',
        directory => '/srv/slave-scripts',
        origin    => 'https://gerrit.wikimedia.org/r/p/integration/jenkins.git',
    }

}
