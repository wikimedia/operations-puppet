# defined type: a systemd timer for planet feed updates per language
define planet::updatejob (
    Stdlib::Unixpath $planet_bin = '/usr/bin/rawdog',
    String $planet_conf_dir = '/etc/rawdog',
    String $planet_options = '-v -u -w',
){

    $planet_cmd = "${planet_bin} -d ${planet_conf_dir}/${title}/ ${planet_options}"

    systemd::timer::job { "update-${title}-planet":
        ensure          => 'present',
        user            => 'planet',
        description     => 'Update feed content for a planet language version.',
        command         => $planet_cmd,
        interval        => {'start' => 'OnUnitInactiveSec', 'interval' => 'hourly'},
        logfile_basedir => '/var/log/planet',
        logfile_name    => "update-${title}.log",
        require         => [
            Class['planet::packages'],
            File['/var/log/planet'],
            File['/etc/sysusers.d/planet.conf'],
        ],
    }
}
