class profile::beta::autoupdater {
    class { '::scap::scripts': }
    class { '::beta::autoupdater':
        require =>  Class['::scap::scripts']
    }
}
