class torrus::config {

    file { '/etc/torrus/conf/':
        source  => 'puppet:///modules/torrus/conf/',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        recurse => remote,
    }

    file { '/etc/torrus/templates/':
        source  => 'puppet:///modules/torrus/templates/',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        recurse => remote,
    }

    file { '/usr/share/torrus/sup/webplain/wikimedia.css':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/torrus/wikimedia.css',
    }

    exec { 'torrus clearcache':
        command     => '/usr/sbin/torrus clearcache',
        logoutput   => true,
        refreshonly => true,
        before      => Exec["torrus compile"],
    }

    exec { 'torrus compile':
        command     => '/usr/sbin/torrus compile --all',
        logoutput   => true,
        refreshonly => true,
    }

    service { 'torrus-common':
        ensure     => running,
        require    => Exec['torrus compile'],
        subscribe  => File[ ['/etc/torrus/conf/', '/etc/torrus/templates/']],
        hasrestart => false,
    }
}
