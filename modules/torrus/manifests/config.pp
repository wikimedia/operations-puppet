class torrus::config {
    File { require => Package['torrus-common'] }

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
}

