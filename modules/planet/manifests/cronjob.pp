# defined type: a cronjob for planet-venus feed updates per language
define planet::cronjob {

    $planet_bin = '/usr/bin/planet'
    $planet_config = "/usr/share/planet-venus/wikimedia/${title}/config.ini"
    $planet_logfile = "/var/log/planet/${title}-planet.log"

    # randomize the minute crons run, using $title as seed
    $minute = fqdn_rand(60, $title)

    # crons only running if in active datacenter
    if $planet::planet_active_dc in $domain {
        $cron_ensure = 'present'
    } else {
        $cron_ensure = 'absent'
    }

    cron { "update-${title}-planet":
        ensure  => $cron_ensure,
        command => "http_proxy=\"${planet::planet_http_proxy}\" https_proxy=\$http_proxy ${planet_bin} -v ${planet_config} > ${planet_logfile} 2>&1",
        user    => 'planet',
        minute  => $minute,
        require => [
            Class['planet::packages'],
            File['/var/log/planet'],
            File[$planet_config],
            User['planet'],
        ],
    }

}
