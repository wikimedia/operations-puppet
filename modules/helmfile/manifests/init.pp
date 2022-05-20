# SPDX-License-Identifier: Apache-2.0
class helmfile {
    ensure_packages(['helmfile', 'helm-diff'])

    # logging script needed for sal on helmfile
    file { '/usr/local/bin/helmfile_log_sal':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/helmfile/helmfile_log_sal.sh',
    }

}
