# defined type: a config dir and file for a planet-venus language version
define planet::config {

    file { "/usr/share/planet-venus/wikimedia/${title}":
        ensure => 'directory',
        path   => "/usr/share/planet-venus/wikimedia/${title}",
        mode   => '0755',
        owner  => 'planet',
        group  => 'planet',
    }

    file { "/usr/share/planet-venus/wikimedia/${title}/config.ini":
        ensure  => 'present',
        path    => "/usr/share/planet-venus/wikimedia/${title}/config.ini",
        owner   => 'planet',
        group   => 'planet',
        mode    => '0444',
        content => template("planet/feeds/${title}_config.erb"),
    }
}
