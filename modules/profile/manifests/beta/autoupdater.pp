class profile::beta::autoupdater {
    class { '::beta::autoupdater':
        require =>  Class['::scap::scripts']
    }
}
