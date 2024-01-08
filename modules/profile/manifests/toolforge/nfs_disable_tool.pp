# SPDX-License-Identifier: Apache-2.0

# This profile should be applied to the primary nfs server.
#  It detects tools scheduled for delete and archives their
#  files.
class profile::toolforge::nfs_disable_tool() {
    require profile::toolforge::disable_tool

    # This includes mysqldump which is used to archive dbs
    ensure_packages('mariadb-client')

    systemd::timer::job { 'disable-tool':
        ensure          => 'present',
        logging_enabled => false,
        user            => 'root',
        description     => 'Archive home dir of deleted or disabled+expired tools',
        command         => '/srv/disable-tool/disable_tool.py archive',
        interval        => {
        'start'    => 'OnCalendar',
        'interval' => '*:0/2', # every 2 minutes
        },
        require         => Class['::profile::toolforge::disable_tool'],
    }
}
