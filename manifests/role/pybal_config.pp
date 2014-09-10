class role::pybal_config.pp {
    system::role { 'pybal_config': description => 'Pybal configuration HTTP host' }

    include ::pybal::web
}
