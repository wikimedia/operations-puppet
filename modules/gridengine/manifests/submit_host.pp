# gridengine.pp

class gridengine::submit_host($gridmaster = $grid_master) {
    class { 'gridengine':
        gridmaster => $gridmaster,
    }

    package { [ 'jobutils' ]:
        ensure => latest,
    }

    package { 'gridengine-client':
        ensure  => latest,
        require => Package['gridengine-common'],
    }

    file { '/var/lib/gridengine/default/common/accounting':
        ensure => link,
        target => '/data/project/.system/accounting',
    }

    # Temporary hack to manage obsolete files in /usr/local/bin.
    # TODO: Remove when no longer needed.
    file { '/usr/local/bin/job':
        ensure => link,
        target => '/usr/bin/job',
    }
    file { '/usr/local/bin/jstart':
        ensure => link,
        target => '/usr/bin/jstart',
    }
    file { '/usr/local/bin/jstop':
        ensure => link,
        target => '/usr/bin/jstop',
    }
    file { '/usr/local/bin/jsub':
        ensure => link,
        target => '/usr/bin/jsub',
    }
}
