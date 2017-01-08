class role::pybal_config {
    system::role { 'pybal_config': description => 'Pybal configuration HTTP host' }

    class { '::pybal::web':
        vhostnames => [
            'config-master.eqiad.wmnet',
            'config-master.codfw.wmnet',
            'config-master.esams.wmnet',
            'config-master.ulsfo.wmnet',
            'config-master.wikimedia.org',
            ],
    }

    ferm::service { 'pybal_conf-http':
        proto  => 'tcp',
        port   => 80,
        srange => '$PRODUCTION_NETWORKS',
    }

}
