# gridengine/exec_host.pp

## Stupid [mumble] [mumble] puppet

class gridengine::exec_submit_host($gridmaster = $grid_master) {
    class { 'gridengine':
        gridmaster => $gridmaster,
    }

    package { 'gridengine-exec':
        ensure  => latest,
        require => Package['gridengine-common'],
    }

    package { [ 'gridengine-client', 'jobutils' ]:
        ensure => latest,
    }

    file { '/var/lib/gridengine/default/common/accounting':
        ensure => link,
        target => '/data/project/.system/accounting',
    }
}

