# defined type: a cronjob for planet feed updates per language
define planet::cronjob (
    Stdlib::Unixpath $planet_bin = '/usr/bin/rawdog',
) {
    $planet_cmd = "-d /etc/rawdog/${title}/ -v -u -w"
    $planet_logfile = "/var/log/planet/${title}-planet.log"

    # randomize the minute crons run, using $title as seed
    $minute = fqdn_rand(60, $title)

    cron { "update-${title}-planet":
        ensure  => 'present',
        command => "http_proxy=\"${planet::http_proxy}\" https_proxy=\$http_proxy ${planet_bin} ${planet_cmd} > ${planet_logfile} 2>&1",
        user    => 'planet',
        minute  => $minute,
        require => [
            Class['planet::packages'],
            File['/var/log/planet'],
            User['planet'],
        ],
    }
}
