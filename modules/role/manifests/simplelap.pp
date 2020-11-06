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

    # TODO: another case for php_version facte
    $php_module = debian::version::ge('buster') ? {
        true    => 'php7.3',
        default => 'php7.0',
    }

    ensure_packages(["libapache2-mod-${php_module}", 'php-cli'])

    class { 'httpd':
        modules => ['rewrite', $php_module],
    }
}
