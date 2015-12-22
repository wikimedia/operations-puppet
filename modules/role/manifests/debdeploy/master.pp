class role::debdeploy::master {
    include standard

    system::role { 'role::debdeploymaster':
        description => 'debdeploy master',
    }

    include ::debdeploy::master
}
