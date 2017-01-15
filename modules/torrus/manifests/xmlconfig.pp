class torrus::xmlconfig {
    require ::torrus::config
    include ::passwords::network

    file { '/etc/torrus/xmlconfig/':
        source  => 'puppet:///modules/torrus/xmlconfig/',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        recurse => remote,
    }

    file { '/etc/torrus/xmlconfig/site-global.xml':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('torrus/site-global.xml.erb'),
    }
}
