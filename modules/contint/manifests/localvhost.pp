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
# contint::localvhost { 'example': }
#
# Creates a vhost listening on 127.0.0.1:9412 having a DocumentRoot at
# /srv/localhost/example.
#
define contint::localvhost(
    Stdlib::Unixpath $docroot = "/srv/localhost/${name}",
    Stdlib::Port $port = 9412,
    String $log_prefix = $name,
){

    apache::site { "${name}.localhost":
        content => template('contint/apache/localvhost.erb'),
    }

    # Asking Apache to listen on [:1] without IPv6 ends up causing
    # an error preventing Apache from starting up.
    $has_ipv6 = $::realm ? {
        'labs'       => false,
        'production' => true,
        default      => true,
    }

    apache::conf { "listen-localhost-${port}":
        content  => template('contint/apache/listen.erb'),
        replaces => "conf.d/listen-localhost-${port}",
    }
}
