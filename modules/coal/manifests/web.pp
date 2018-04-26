# == Class: coal::web
#
# Run the web portion of the coal service (provides metrics for
# performance.wikimedia.org)
#
class coal::web() {
    require_package('python-flask')
    require_package('python-numpy')
    require_package('python-whisper')
	
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