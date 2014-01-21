# defined type: a cronjob for planet-venus feed updates per language
define planet::cronjob {

    $planet_bin = '/usr/bin/planet'
    $planet_config = "/usr/share/planet-venus/wikimedia/${title}/config.ini"
    $planet_logfile = "/var/log/planet/${title}-planet.log"

    cron { "update-${title}-planet":
        ensure  => 'present',
        command => "${planet_bin} -v ${planet_config} > ${planet_logfile} 2>&1",
        user    => 'planet',
        minute  => '0',
        require => [
            Class['planet::packages'],
            File['/var/log/planet'],
            File[$planet_config],
            User['planet'],
        ],
    }

}
