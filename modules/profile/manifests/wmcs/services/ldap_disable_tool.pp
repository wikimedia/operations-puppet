# SPDX-License-Identifier: Apache-2.0

# This runs a timer on a single cloudcontrol node to clean up
#  ldap entries of deleted tools. It needs to run in the prod
#  realm to write to ldap.
class profile::wmcs::services::ldap_disable_tool(
    String                    $maintain_dbusers_primary     = lookup('wmcs_maintain_dbusers_primary'),
) {
    require profile::toolforge::disable_tool

    # We only want this to run in one place, re-use the
    # maintain_dbusers host
    if ($facts['fqdn'] == $maintain_dbusers_primary) {
        $enable_service = present
    } else {
        $enable_service = absent
    }

    systemd::timer::job { 'disable-tool':
        ensure          => $enable_service,
        logging_enabled => false,
        user            => 'root',
        description     => 'Delete ldap records of deleted or disabled+expired tools',
        command         => '/srv/disable-tool/disable_tool.py deleteldap',
        interval        => {
        'start'    => 'OnCalendar',
        'interval' => '*:0/2', # every 2 minutes
        },
        require         => Class['::profile::toolforge::disable_tool'],
    }
}
