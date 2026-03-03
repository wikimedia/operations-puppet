# SPDX-License-Identifier: Apache-2.0
class grafana::ldap_sync (
  Wmflib::Ensure $ensure,
) {
    ensure_packages(['python3-ldap', 'python3-requests'])

    file { '/usr/local/bin/grafana-ldap-users-sync':
        ensure => present,
        source => 'puppet:///modules/grafana/ldap_users_sync.py',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    systemd::timer::job{ 'grafana-ldap-users-sync':
        ensure      => $ensure,
        description => 'Sync users and roles from LDAP to Grafana',
        command     => '/usr/local/bin/grafana-ldap-users-sync --commit --delete-users',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'daily',
        },
        user        => 'grafana',
        require     => File['/usr/local/bin/grafana-ldap-users-sync'],
    }
}
