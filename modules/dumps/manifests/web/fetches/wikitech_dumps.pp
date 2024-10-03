class dumps::web::fetches::wikitech_dumps() {
    file { '/usr/local/sbin/wikitech-dumps.sh':
        ensure => absent
    }

    systemd::timer::job { 'dumps-fetches-wikitech':
        ensure => absent,
    }
}
