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

    if os_version('debian >= stretch') {
        $php_module = 'php7.0'
        require_package('php-cli')
    } else {
        $php_module = 'php5'
        require_package('php5-cli')
    }

    class { '::httpd':
        modules => ['rewrite', $php_module],
    }

}
