# == Class: webperf::asset_check
#
# Remnant class to uninstall asset-check (T164419).
#
class webperf::asset_check {

    file { '/srv/webperf/asset-check.js':
        ensure  => absent,
    }

    file { '/srv/webperf/asset-check.py':
        ensure  => absent,
    }

    file { '/lib/systemd/system/asset-check.service':
        ensure  => absent,
    }

    service { 'asset-check':
        ensure  => stopped,
        enable  => false,
        provider => 'systemd',
    }
}
