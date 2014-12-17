# Class: install-server::web-server
#
# This class installs and configures nginx to act as a repository for new
# installation enviroments
#
# Parameters:
#
# Actions:
#   Install and configure nginx
#
# Requires:
#
# Sample Usage:
#   include install-server::web-server

class install-server::web-server {
    include ::nginx

    nginx::site { 'install-server':
        source  => 'puppet:///modules/install-server/nginx.conf';
    }

    # prevent a /srv root autoindex; empty for now.
    file { '/srv/index.html':
        ensure  => present,
        content => '',
    }
}
