# == Definition contint::localvhost
#
# Craft an apache configuration file to listen on localhost:$port (default to
# port 9412) and point that vhost to $docroot (default to
# /srv/localhost${name}).
#
# The $name is by default used as a prefix for the Apache logs. You can
# override it using $log_prefix.
#
# == Example:
#
# contint::localvhost { 'qunit:' }
#
# Creates a vhost listening on 127.0.0.1:9412 having a DocumentRoot at
# /srv/localhost/qunit.
#
define contint::localvhost(
    $docroot = "/srv/localhost/${name}",
    $port = 9412,
    $log_prefix = $name,
){

    file { "/etc/apache2/sites-available/${name}.localhost":
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('contint/apache/localvhost.erb'),
    }

    $apache_listens = [
        { 'ip' => '127.0.0.1', 'port' => $port, 'proto' => 'http', },
        { 'ip' => '[::1]',     'port' => $port, 'proto' => 'http', },
    ]
    file { "/etc/apache2/conf.d/listen-localhost-${port}":
        content => template('contint/apache/listen.erb'),
    }

    apache_site { "${name} localhost":
        name => "${name}.localhost"
    }

}
