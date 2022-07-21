# SPDX-License-Identifier: Apache-2.0
# Provisions a systemd service instance of jwt-authorizer.
#
# The jwt-authorizer service provides integrated auth with GitLab CI jobs via
# their short lived JSON Web Tokens to other services like
# docker_registry_ha. See the nginx configuration of the latter for usage.
#
# @param listen Address or UNIX socket to bind to (e.g. tcp://127.0.0.1:1337,
#               unix:///some/unix.sock)
# @param keys_url URL from which to periodically fetch public JSON Web Token
#                 issuer keys for validating bearer tokens.
# @param issuer Issuer name to enforce on tokens.
# @param ensure Systemd service state.
# @param owner Service process owner.
# @param group Service process group owner.
# @param mode Creation mode of the unix socket if used.
# @param request_prefix Request path prefix to ignore when comparing against
#                       project_path during token validation.
# @param validation_template Go template used to further validate JWT claims
#                            beyond signature correctness and expiry. See
#                            https://gitlab.wikimedia.org/repos/releng/jwt-authorizer
define jwt_authorizer::service(
    String $listen,
    Stdlib::HTTPUrl $keys_url,
    Stdlib::Host $issuer,
    Wmflib::Ensure $ensure = 'present',
    String $owner = 'www-data',
    String $group = 'www-data',
    Stdlib::Filemode $mode = '0700',
    Stdlib::Unixpath $request_prefix = '/',
    Optional[Stdlib::Filesource] $validation_template = undef,
) {
    require jwt_authorizer

    $validation_template_path = "/etc/jwt-authorizer/${title}-validations.tmpl"
    $validation_template_ensure = $validation_template ? {
        undef   => 'absent',
        default => $ensure,
    }

    file { $validation_template_path:
        ensure => stdlib::ensure($validation_template_ensure, 'file'),
        source => $validation_template,
        owner  => 'root',
        group  => 'www-data',
        mode   => '0640',
        before => Systemd::Service[$title],
        notify => Service[$title],
    }

    systemd::service { $title:
        ensure  => stdlib::ensure($ensure, 'service'),
        content => template('jwt_authorizer/authorizer.service.erb'),
        restart => true,
    }
}
