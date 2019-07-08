# This class will create a file under /etc/nginx/conf.d/ that will configure the SSL settings for nginx.
#
# === Parameters
#
# [*ensure*]
#   works exactly as for a file resource
#
# [*pfs*]
#   Decides whether we're preferring Perfect-Forward-Secrecy or not.
#   Setting this to false, in the post-Snowden era, should have very compelling reasons.
#
# [*ie6_compat*]
#   If we need to support ie6, we need to enable ssl3 and in general make
#   things less secure.
class nginx::ssl (
    $ensure     = 'present',
    $pfs        = true,
    $ie6_compat = false
) {
    # This will work only on debian derivatives, of course.
    # TODO make it include RH-derivatives as well, or make it fail in that case.
    file {'/etc/nginx/conf.d/ssl.conf':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('nginx/ssl.conf.erb'),
    }
}
