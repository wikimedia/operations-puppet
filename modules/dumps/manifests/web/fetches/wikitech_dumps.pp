class dumps::web::fetches::wikitech_dumps(
    $url            = undef,
    $miscdatasetsdir = undef,
) {

    $wikitechdir = "${miscdatasetsdir}/wikitech"

    file { $wikitechdir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/usr/local/sbin/wikitech-dumps.sh':
        source => 'puppet:///modules/dumps/fetches/wikitech-dumps.sh',
        mode   => '0554',
        owner  => 'root',
        group  => 'root',
    }

    systemd::timer::job { 'dumps-fetches-wikitech':
        ensure      => 'absent',
        description => 'Download XML dumps for WikiTech',
        user        => 'root',
        command     => "/usr/local/sbin/wikitech-dumps.sh ${url} ${wikitechdir}",
        interval    => {'start' => 'OnCalendar', 'interval' => '03:20:00'},
    }
}
