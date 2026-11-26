class varnish::common::director_scripts {
    # The script that should restart varnish once the file is written.
    file { '/usr/local/bin/confd-reload-vcl':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/varnish/confd-reload-vcl.sh',
    }

    file { '/var/log/confd-reload-vcl.log':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    logrotate::rule { 'confd_reload_vcl_log':
        ensure       => present,
        file_glob    => '/var/log/confd-reload-vcl.log',
        frequency    => 'daily',
        not_if_empty => true,
        rotate       => 3,
        compress     => true,
        missing_ok   => true,
    }

    file { '/usr/local/lib/nagios/plugins/check_vcl_reload':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/varnish/check_vcl_reload.sh';
    }

    # TODO: extend the check to everything including the exec in puppet?
    nrpe::monitor_service { 'confd_vcl_reload':
        description    => 'Confd vcl based reload',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_vcl_reload',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Varnish',
        migration_task => 'T367149',
    }
}
