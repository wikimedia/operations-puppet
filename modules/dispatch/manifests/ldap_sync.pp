# SPDX-License-Identifier: Apache-2.0
class dispatch::ldap_sync (
  Wmflib::Ensure $ensure,
) {
    ensure_packages(['python3-ldap', 'python3-requests'])

    file { '/usr/local/bin/dispatch-ldap-users-sync':
        ensure => present,
        source => 'puppet:///modules/dispatch/ldap_users_sync.py',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    systemd::timer::job { 'dispatch-ldap-users-sync':
        ensure      => $ensure,
        description => 'Sync roles and user info from LDAP to Dispatch',
        command     => '/usr/local/bin/dispatch-ldap-users-sync --commit',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'daily',
        },
        user        => 'nobody',
        require     => File['/usr/local/bin/dispatch-ldap-users-sync'],
    }
}
