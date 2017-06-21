# defined type: a config dir and file for a planet-venus language version
define planet::config {

    if os_version('debian == stretch') {
        file { '/etc/rawdog':
            ensure => 'directory'
        }
        $config_path = '/etc/rawdog'
    } else {
        $config_path = '/usr/share/planet-venus/wikimedia'
    }

    file { "${config_path}/${title}":
        ensure => 'directory',
        path   => "${config_path}/${title}",
        mode   => '0755',
        owner  => 'planet',
        group  => 'planet',
    }

    file { "${config_path}/${title}/config.ini":
        ensure  => 'present',
        path    => "${config_path}/${title}/config.ini",
        owner   => 'planet',
        group   => 'planet',
        mode    => '0444',
        content => template("planet/feeds/${title}_config.erb"),
    }
}
