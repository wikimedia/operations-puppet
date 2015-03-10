# backup::set is probably what you want
define backup::set($jobdefaults=$role::backup::host::jobdefaults) {
    if $jobdefaults != undef {
        @bacula::client::job { "${name}-${jobdefaults}":
            fileset     => $name,
            jobdefaults => $jobdefaults,
        }

        $motd_content = "#!/bin/sh\necho \"Backed up on this host: ${name}\""
        @motd::script { "backups-${name}":
            ensure   => present,
            priority => 06,
            content  => $motd_content,
            tag      => 'backup-motd',
        }
    }
}
