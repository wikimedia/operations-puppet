# SPDX-License-Identifier: Apache-2.0
# Sets up SSH config for gerrit replication
#
class gerrit::replication_ssh_config {

    file { '/srv/gerrit/.ssh/config':
        ensure  => file,
        owner   => 'gerrit',
        group   => 'gerrit',
        mode    => '0600',
        content => @(EOF),
        # Accept keys for any Gerrit SSH server on port 29418
        # IF it already trusts them in the global SSH known_hosts file.
            Host gerrit*.wikimedia.org
            Port 29418
            StrictHostKeyChecking accept-new
        EOF
    }
}
