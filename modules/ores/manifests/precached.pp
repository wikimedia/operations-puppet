# = Class: ores::precached
# Run a pre-caching daemon that listens to RCStream
class ores::precached {
    include ::ores::web

    $working_dir = $::ores::base::config_path
    $venv_path  = $::ores::base::venv_path
    $host = 'https://ores.wmflabs.org'
    $config_dir = "${working_dir}/config"

    base::service_unit { 'precached':
        require        => Class['ores::web'],
        template_name  => 'precached',
        systemd        => true,
        service_params => {
            enable     => true,
            hasstatus  => true,
            hasrestart => true,
        },
    }
}
