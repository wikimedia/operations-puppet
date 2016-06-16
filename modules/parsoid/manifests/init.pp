# == Class: parsoid
#
# Parsoid is a wt2HTML and HTML2wt parser able to deliver no-diff round-trip
# conversions between the two formats.
#
# === Parameters
#
# [*port*]
#   Port to run the Parsoid service on. Default: 8000
#
# [*settings_file*]
#   Location of the old-format Parsoid configuration and settings file. Note
#   that Parsoid still draws part of its configuration from there when it is
#   specified. Default: 'conf/wmf/localsettings.js'
#
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
