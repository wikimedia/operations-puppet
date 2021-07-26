# = Class: profile::quarry::web
#
# This class sets up a web frontend for Quarry, which lets
# users run SQL queries against LabsDB.
# Deployment is handled using fabric
class profile::quarry::web(
    Stdlib::Unixpath $clone_path = lookup('profile::quarry::base::clone_path'),
    Stdlib::Unixpath $venv_path  = lookup('profile::quarry::base::venv_path'),
) {
    require ::profile::quarry::base

    uwsgi::app { 'quarry-web':
        require  => Git::Clone['analytics/quarry/web'],
        settings => {
            uwsgi => {
                'plugins'   => 'python3',
                'socket'    => '/run/uwsgi/quarry-web.sock',
                'wsgi-file' => "${clone_path}/quarry.wsgi",
                'master'    => true,
                'processes' => 8,
                'chdir'     => $clone_path,
                'venv'      => $venv_path,
            },
        },
    }

    nginx::site { 'quarry-web-nginx':
        require => Uwsgi::App['quarry-web'],
        content => template('quarry/quarry-web.nginx.erb'),
    }

    # Install tmpreaper to clean up tempfiles leaked by xlsxwriter
    #  T238375
    package { 'tmpreaper':
        ensure => 'installed',
    }
    file { '/etc/tmpreaper.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/profile/quarry/tmpreaper.conf',
        require => Package['tmpreaper'],
    }
}
