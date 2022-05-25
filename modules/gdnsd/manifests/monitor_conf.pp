# SPDX-License-Identifier: Apache-2.0
class gdnsd::monitor_conf {
    # This is a local NRPE check to validate that the gdnsd server's config
    # and zonefiles still load.  This is an important gaurd against e.g.
    # puppet-deploying an invalid configuration, which might otherwise only
    # cause a single failed puppet run (until someone tries to deploy DNS
    # changes and gets blocked).
    nrpe::plugin { 'check_gdnsd_checkconf':
        source => 'puppet:///modules/gdnsd/check_gdnsd_checkconf',
    }

    nrpe::monitor_service { 'gdnsd_checkconf':
        description  => 'gdnsd checkconf',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_gdnsd_checkconf',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/gdnsd',
    }
}
