class role::debdeploy::master {
    include ::standard

    system::role { 'debdeploymaster':
        description => 'debdeploy master',
    }

    include ::debdeploy::master
}
