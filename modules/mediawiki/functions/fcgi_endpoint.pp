# This function allows puppet code to compute the fcgi endpoint address
# from the port and pool names.
function mediawiki::fcgi_endpoint(Optional[Stdlib::Port::User] $port, String $pool) >> String {
    $port ? {
        undef => "unix:/run/php/fpm-${pool}.sock|fcgi://${pool}",
        default => "fcgi://127.0.0.1:${port}"
    }

}
