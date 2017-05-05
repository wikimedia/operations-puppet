# == Class: tlsproxy::ocsp

class tlsproxy::ocsp {
    # nginx does not automatically pick up new OCSP responses from the
    # filesystem. Install a hook for update-ocsp that reloads nginx after
    # fetching new responses.
    sslcert::ocsp::hook { 'nginx-reload':
        ensure => 'present',
        source => 'puppet:///modules/tlsproxy/update-ocsp-nginx-hook',
    }

    # Generate icinga alert if OCSP files falling out of date due to errors
    #
    # Note this makes no provision for un-configured stapling at this time, so
    # it will generate warnings if you don't clean up old /var/cache/ocsp/
    # entries after removing a tlsproxy::ocsp_stapler cert from a server!
    #
    # The cron above attempts to get fresh data once a day, and a good fresh
    # fetch of data has a 4-7 day lifetime depending on the vendor (GlobalSign
    # or Digicert)
    #
    # The crit/warn values of 259205 and 86405 correspond to "1d5m" and
    # "3d5m", so those are basically warning if 1 updates in a row failed
    # for a given cert, and critical if 3 updates in a row failed (at which
    # point we have ~24h left to fix the situation before the validity window
    # expires).

    $check_args = '-c 259205 -w 86405 -d /var/cache/ocsp -g "*.ocsp"'
    nrpe::monitor_service { 'ocsp-freshness':
        description  => 'Freshness of OCSP Stapling files',
        nrpe_command => "/usr/lib/nagios/plugins/check-fresh-files-in-dir.py ${check_args}",
        require      => File['/usr/lib/nagios/plugins/check-fresh-files-in-dir.py'],
    }
}
