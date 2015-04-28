class role::mobileapps {

    system::role { 'role::mobileapps':
        description => 'node.js service for serving content for native mobile apps'
    }

    ferm::service { 'mobileapps':
        proto => 'tcp',
        port  => 6624,
    }

    include ::mobileapps

}

