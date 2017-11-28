# = Class: ores::precached
# Run a pre-caching daemon that listens to RCStream
class ores::precached {
    include ::ores::web

    $working_dir = $::ores::base::config_path
    $venv_path  = $::ores::base::venv_path
    $host = 'https://ores.wmflabs.org'
    $config_dir = "${working_dir}/config"

    systemd::service { 'precached':
        require        => Class['ores::web'],
        content        => systemd_template('precached'),
        restart        => true,
        service_params => {
            enable     => true,
            hasstatus  => true,
            hasrestart => true,
        },
    }
}
