class profile::ci::gitcache {
    git::clone { 'operations/puppet':
        directory => '/srv/git/operations/puppet.git',
        bare      => true,
    }
}
