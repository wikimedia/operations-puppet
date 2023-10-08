# defined type: dirs for (RSS) plugins for a planet-rawdog language
define planet::rawdogplugin {

    file { "/etc/rawdog/${title}/plugins":
        ensure => directory,
        owner  => 'planet',
        group  => 'planet',
        mode   => '0755',
    }

    if debian::codename::ge('bullseye') {
        $plugin_files = 'rss-next.py'
    } else {
        $plugin_file ='rss.py'
    }

    file { "/etc/rawdog/${title}/plugins/${plugin_file}":
        ensure  => present,
        owner   => 'planet',
        group   => 'planet',
        mode    => '0755',
        content => template('planet/plugins/rss.py.erb'),
    }

}

