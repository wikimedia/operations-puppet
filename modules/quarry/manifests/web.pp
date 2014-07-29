# = Class: quarry::web
#
# This class sets up a web frontend for Quarry, which lets
# users run SQL queries against LabsDB.
# Deployment is handled using fabric
class quarry::web {
    $clone_path = "/srv/quarry"
    $result_path = "/data/project/quarry/results"
    $venv_path = "/srv/venv"

    include quarry::base

    uwsgi::app { 'quarry-web':
        require             => Git::Clone['analytics/quarry/web'],
        settings            => {
            uwsgi           => {
                'socket'    => '/run/uwsgi/quarry-web.sock',
                'wsgi-file' => "$clone_path/quarry.wsgi",
                'master'    => true,
                'processes' => 8,
                'venv'      => $venv_path,
                'chdir'     => $clone_path,
            }
        }
    }

    nginx::site { 'quarry-web-nginx':
        require => Uwsgi::App['quarry-web'],
        content => template('quarry/quarry-web.nginx.erb')
    }

    diamond::collector::nginx { 'quarry-monitory-diamond': }
}
