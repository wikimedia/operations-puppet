class role::ci::repository {

    require role::labs::lvm::srv

    class { '::nexus':
        data_dir => '/srv/nexus'
    }

}
