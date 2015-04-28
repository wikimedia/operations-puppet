class role::mobileapps {

    system::role { 'role::mobileapps':
        description => 'node.js service for serving content for native mobile apps'
    }

    include ::mobileapps

}

