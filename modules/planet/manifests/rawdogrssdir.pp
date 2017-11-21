# defined type: rss plugin dirs for a planet-rawdog language
define planet::rawdogrssdir {

    file { "/etc/rawdog/${title}/plugins":
        ensure => directory,
        owner  => 'planet',
        group  => 'planet',
        mode   => '0755',
    }

    file { "/etc/rawdog/${title}/plugins/rss.py":
        ensure  => 'present',
        owner   => 'planet',
        group   => 'planet',
        mode    => '0755',
        content => template('planet/feeds_rawdog/plugins/rss.py.erb'),
    }

}
