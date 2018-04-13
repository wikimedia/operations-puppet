# = Class: quarry::web
#
# This class sets up a web frontend for Quarry, which lets
# users run SQL queries against LabsDB.
# Deployment is handled using fabric
class quarry::web {
    require_package('python-flask', 'python-mwoauth')

    require ::quarry::base

    $clone_path = $::quarry::base::clone_path

    uwsgi::app { 'quarry-web':
        require  => Git::Clone['analytics/quarry/web'],
        settings => {
            uwsgi => {
                'plugins'   => 'python',
                'socket'    => '/run/uwsgi/quarry-web.sock',
                'wsgi-file' => "${clone_path}/quarry.wsgi",
                'master'    => true,
                'processes' => 8,
                'chdir'     => $clone_path,
            },
        },
    }

    nginx::site { 'quarry-web-nginx':
        require => Uwsgi::App['quarry-web'],
        content => template('quarry/quarry-web.nginx.erb'),
    }
}
