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
    # The warn and crit values of 173100 and 259200 correspond to "2d5m" and
    # "3d5m", and are checking the mtime of the files (not the internal expiry
    # times).  This should give us ~24h to fix, assuming we're getting minimum
    # 4-day staples.  The live ssl checker also checks for internal timestamps
    # nearing expiry as well (warn at 2 days left, crit at 1 day left), so
    # we're covered on two fronts here.

    $check_args = '-c 259500 -w 173100 -d /var/cache/ocsp -g "*.ocsp"'
    nrpe::monitor_service { 'ocsp-freshness':
        description  => 'Freshness of OCSP Stapling files',
        nrpe_command => "/usr/lib/nagios/plugins/check-fresh-files-in-dir.py ${check_args}",
        require      => File['/usr/lib/nagios/plugins/check-fresh-files-in-dir.py'],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/HTTPS/Unified_Certificates',
    }

    # systemd unit fragment for running ocsp updater from ExecStartPre
    $sysd_ocsp_conf = '/etc/systemd/system/nginx.service.d/ocsp.conf'

    file { $sysd_ocsp_conf:
        ensure => present,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/tlsproxy/nginx-ocsp.conf',
        before => Class['nginx'],
    }

    exec { 'systemd reload for nginx systemd ocsp fragment':
        refreshonly => true,
        command     => '/bin/systemctl daemon-reload',
        subscribe   => File[$sysd_ocsp_conf],
    }
}
