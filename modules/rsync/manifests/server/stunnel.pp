# SPDX-License-Identifier: Apache-2.0
# @summary deploy stunnel rsync wrapper
#
class rsync::server::stunnel(
    Wmflib::Ensure          $ensure         = present,
    Stdlib::Ensure::Service $ensure_service = 'running',
) {
    include rsync::server

    ensure_packages(['stunnel4'])

    file { '/etc/stunnel/rsync.conf':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('rsync/stunnel.conf.erb'),
    }

    file_line { 'enable_stunnel':
        ensure   => present,
        path     => '/etc/default/stunnel4',
        line     => 'ENABLED=1  # Managed by puppet',
        match    => '^ENABLED=',
        multiple => false,
    }

    service { 'stunnel4':
        ensure    => $ensure_service,
        enable    => true,
        subscribe => [
            Concat[$rsync::server::rsync_conf],
            File['/etc/default/rsync', '/etc/stunnel/rsync.conf'],
            File_line['enable_stunnel'],
            Package['stunnel4'],
        ],
    }

}
