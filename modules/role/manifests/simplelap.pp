# = class: role::simplelap
#
# For times when you do not want mysql, 
# and just apache and PHP
#
# This was originally created because there
# were a lot of labs instances using the old
# webserver::apache and webserver::php5 roles
# that needed to go away. This probably will
# not end up being publicly used
#
# filtertags: labs-project-signwriting labs-project-editor-engagement
class role::simplelap{

    if os_version('debian >= buster') {
        $php_module = 'php7.3'
    } else {
        $php_module = 'php7.0'
    }

    require_package("libapache2-mod-${php_module}", 'php-cli')

    class { '::httpd':
        modules => ['rewrite', $php_module],
    }
}
