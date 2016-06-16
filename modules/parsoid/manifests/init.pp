# == Class: parsoid
class parsoid(
    $port          = 8000,
    $settings_file = 'conf/wmf/localsettings.js',
) {

    service::node { 'parsoid':
        port            => $port,
        starter_module  => 'src/lib/index.js',
        entrypoint      => 'apiServiceWorker',
        starter_script  => 'src/bin/server.js',
        config          => {
            localsettings => $settings_file,
        },
        heartbeat_to    => 300000,
        healthcheck_url => '/',
        has_spec        => false,
    }

}
