class subversion::viewvc {

    require subversion

    package { 'viewvc':
        ensure => present,
    }

    file { '/etc/apache2/svn-authz':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        # lint:ignore:puppet_url_without_modules
        source => 'puppet:///private/svn/svn-authz',
        # lint:endignore
    }

    file { '/etc/viewvc/viewvc.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/subversion/viewvc.conf',
    }

    file { '/etc/viewvc/templates/revision.ezt':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/subversion/revision.ezt',
    }

}

