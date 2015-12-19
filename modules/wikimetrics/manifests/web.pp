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
                route-if-not => equal:${HTTPS};on redirect-permanent:https://${HTTP_HOST}${REQUEST_URI},
            }
        }
    }
}
