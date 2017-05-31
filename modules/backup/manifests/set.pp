# backup::set is probably what you want.
define backup::set($extras=undef) {
    if defined(Class['profile::backup::host']) {
        $jobdefaults=$profile::backup::host::jobdefaults
        @bacula::client::job { "${name}-${jobdefaults}":
            fileset     => $name,
            jobdefaults => $jobdefaults,
            extras      => $extras,
        }

        $motd_content = "#!/bin/sh\necho \"Backed up on this host: ${name}\""
        @motd::script { "backups-${name}":
            ensure   => present,
            priority => 16,
            content  => $motd_content,
            tag      => 'backup-motd',
        }
    }
}
