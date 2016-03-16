# = Class: ores::precached
# Run a pre-caching daemon that listens to RCStream
class ores::precached {
    $working_dir = $::ores::base::config_path
    $venv_path  = $::ores::base::venv_path
    base::service_unit { 'precached':
    template_name => 'precached',
    systemd       => true,
    }
}
