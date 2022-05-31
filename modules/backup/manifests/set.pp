# SPDX-License-Identifier: Apache-2.0
# backup::set is probably what you want.
define backup::set(
    $extras=undef,
    $jobdefaults=undef,
) {
    if defined(Class['profile::backup::host']) {
        if $jobdefaults {
            $real_jobdefaults = $jobdefaults
        } else {
            $real_jobdefaults = $profile::backup::host::jobdefaults
        }
        @bacula::client::job { "${name}-${real_jobdefaults}":
            fileset     => $name,
            jobdefaults => $real_jobdefaults,
            extras      => $extras,
        }

        $motd_content = "#!/bin/sh\necho \"Backed up on this host: ${name}\""
        @motd::script { "backups-${name}":
            ensure   => present,
            priority => 6,
            content  => $motd_content,
            tag      => 'backup-motd',
        }
    }
}
