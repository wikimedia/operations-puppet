# == Class: wikimetrics::web
# Sets up a uwsgi based web server for Wikimetrics

class wikimetrics::web(
    $workers = 1,
) {
    require wikimetrics::base

    uwsgi::app { 'wikimetrics-web':
        settings => {
            uwsgi => {
                plugins      => 'python, router_redirect',
                'wsgi-file'  => "${wikimetrics::base::source_path}/wikimetrics/api.wsgi",
                master       => true,
                chdir        => $wikimetrics::base::source_path,
                http-socket  => '0.0.0.0:8080',
                venv         => $wikimetrics::base::venv_path,
                processes    => $workers,
                # Serve static files on /static
                static-map   => /static="${wikimetrics::base::source_path}/wikimetrics/static"
                # Look at the X_FORWARDED_PROTO, and if it's http, redirect to https
                route-if     => "equal:${HTTP_X_FORWARDED_PROTO};http redirect-permanent:https://${HTTP_HOST}${REQUEST_URI}",
            }
        }
    }
}
