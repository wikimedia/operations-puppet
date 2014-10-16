# gridengine/submit_host.pp

class gridengine::submit_host(
    $gridmaster = $grid_master,
    $collectdir)
{
    class { 'gridengine':
        gridmaster => $gridmaster,
    }

    package { [ 'jobutils' ]:
        ensure => latest,
    }

    package { 'gridengine-client':
        ensure => latest,
        require => Package['gridengine-common'],
    }

    file { '/var/lib/gridengine/default/common/accounting':
        ensure => link,
        target => '/data/project/.system/accounting',
    }
}

