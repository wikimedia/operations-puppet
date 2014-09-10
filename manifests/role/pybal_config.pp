class role::pybal_config {
    system::role { 'pybal_config': description => 'Pybal configuration HTTP host' }

    class { '::pybal::web':
        vhostnames => [
                       'config-master.eqiad.wmnet',
                       'config-master.codfw.wmnet',
                       'config-master.esams.wmnet',
                       'config-master.ulsfo.wmnet',
                       ]
    }
}
