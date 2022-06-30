# This function allows puppet code to compute the fcgi endpoint address
# from the port and pool names.
# the "default" parameter tells us if we're setting up the default php version or not.
function mediawiki::fcgi_endpoint(Optional[Stdlib::Port::User] $port, String $pool, Boolean $default ) >> String {
    $port ? {
        undef => "unix:/run/php/fpm-${pool}.sock|fcgi://${default.bool2str('localhost', $pool)}",
        default => "fcgi://127.0.0.1:${port}"
    }

}
