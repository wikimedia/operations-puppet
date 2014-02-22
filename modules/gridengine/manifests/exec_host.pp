# gridengine/exec_host.pp

class gridengine::exec_host($gridmaster = $grid_master) {
    class { 'gridengine':
        gridmaster => $gridmaster,
    }

    package { 'gridengine-exec':
        ensure  => latest,
        require => Package['gridengine-common'],
    }
}

