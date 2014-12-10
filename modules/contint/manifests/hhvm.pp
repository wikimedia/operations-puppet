class contint::hhvm {

    class { '::hhvm':
        packages_ensure  => 'latest',

        common_settings => {
            hhvm => {
                log   => { use_syslog => false },
                debug => { core_dump_report => false },
            },
        },

        # Please make sure hhvm.repo.central.path and hhvm.repo.local.path are
        # never set. hhvm will fall back to environment variables
        # HHVM_REPO_CENTRAL_PATH and HHVM_REPO_LOCAL_PATH which uses WORKSPACE.
        # This way we ensure a hhbc per job.
        cli_settings => {
            hhvm => {
                repo => {
                    local   => { mode => 'rw' },
                    eval    => { mode => 'local' },
                    journal => 'memory',
                },
            },
        },

        # We will want to bypass the Repo since code keep changing?
        fcgi_settings => { },
    }

    alternatives::select { 'php':
        path    => '/usr/bin/hhvm',
        require => Package['hhvm'],
    }

}
