# defined type: a systemd timer for planet feed updates per language
# per default all feed updates run hourly but at a random minute
# for each language where the language prefix is the seed
define planet::updatejob (
    Stdlib::Httpsurl $https_proxy,
    Stdlib::Unixpath $planet_bin = '/usr/bin/rawdog',
    String $planet_conf_dir = '/etc/rawdog',
    String $planet_options = '-v -u -w',
){

    $planet_cmd = "${planet_bin} -d ${planet_conf_dir}/${title}/ ${planet_options}"

    $minute = Integer(seeded_rand(60, $title))

    systemd::timer::job { "planet-update-${title}":
        ensure          => present,
        user            => 'planet',
        description     => "Update feed content for Planet language version: ${title}",
        command         => $planet_cmd,
        environment     => { 'HTTPS_PROXY' => $https_proxy },
        interval        => [
            {
            'start'    => 'OnBootSec', # initially start the unit
            'interval' => '10sec',
            },{
            'start'    => 'OnCalendar',
            'interval' => "*-*-* *:${minute}:00", # then hourly at a random minute
            },
        ],
        logfile_basedir => '/var/log/planet',
        logfile_name    => "update-${title}.log",
        require         => [
            Class['planet::packages'],
            File['/var/log/planet'],
            File['/etc/sysusers.d/planet.conf'],
        ],
    }
}
