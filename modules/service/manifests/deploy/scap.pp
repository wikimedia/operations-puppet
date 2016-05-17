# == Define service::deploy::scap
#
# Creates user and permissions for deploy user
# on service hosts
#
# Deprecated: you should use scap::target directly instead of this wrapper.
#
# === Parameters
#
# [*user*]
#   the user to create for deployment
#
# [*service_name*]
#   service name that should be allowed to be restarted via sudo by
#   user.  Default: undef.
#
define service::deploy::scap(
    $user            = 'deploy-service',
    $service_name    = undef,
    $manage_user     = false,
) {
    warning('service::deploy::scap is deprecated. Use scap::target instead')
    scap::target { $title:
        deploy_user  => $user,
        service_name => $service_name,
        manage_user  => $manage_user,
    }
}
