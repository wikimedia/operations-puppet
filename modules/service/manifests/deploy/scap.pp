# == Define service::deploy::scap
#
# Creates user and permissions for deploy user
# on service hosts
#
# === Parameters
#
# [*public_key_file*]
#   This is the public_key for the deploy-service user. The private part of this
#   key should reside in the private puppet repo for the environment. By default
#   this public key is set to the deploy-service user's public key for production
#   private puppet. It should be overwritten using hiera in non-production
#   environements.
#
# [*user*]
#   the user to create for deployment
#
# [*service_name*]
#   service name that should be allowed to be restarted via sudo by
#   user.  Default: undef.
#
define service::deploy::scap(
    $public_key_file = 'puppet:///modules/service/servicedeploy_rsa.pub',
    $user            = 'deploy-service',
    $service_name    = undef,
    $manage_user     = false,
) {
    scap::target { $title:
        public_key_source => $public_key_file,
        deploy_user       => $user,
        service_name      => $service_name,
        manage_user       => $manage_user,
    }
}
