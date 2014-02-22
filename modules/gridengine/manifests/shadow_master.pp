# gridengine.pp


class gridengine::shadow_master($gridmaster = $grid_master) {
    class { 'gridengine':
        gridmaster => $gridmaster,
    }

    package { 'gridengine-master':
        ensure => latest,
        require => Package['gridengine-common'],
    }

}
