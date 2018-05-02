# == Class: coal::web
#
# Run the web portion of the coal service (provides metrics for
# performance.wikimedia.org)
#
class coal::web() {

    # Include common things for coal
    include ::coal::common
    include ::apache

    require_package('python-flask')
    require_package('python-numpy')
    require_package('python-requests')

    uwsgi::app { 'coal':
        service_settings => '--die-on-term',
        settings         => {
            uwsgi => {
                'plugins'   => 'python',
                'socket'    => '/run/uwsgi/coal.sock',
                'wsgi-file' => '/srv/deployment/performance/coal/coal/coal_web.py',
                'callable'  => 'app',
                'master'    => true,
                'processes' => 8,
            },
        },
    }
}