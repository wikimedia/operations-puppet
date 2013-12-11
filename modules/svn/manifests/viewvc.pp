class svn::viewvc {
    require svn::server

    package { 'viewvc':
        ensure => latest,
    }

    file { '/etc/apache2/svn-authz':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///private/svn/svn-authz',
    }

    file { '/etc/viewvc/viewvc.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/svn/viewvc.conf',
    }

    file { '/etc/viewvc/templates/revision.ezt':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/svn/revision.ezt',
    }
}

