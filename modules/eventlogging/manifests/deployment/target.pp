# == Define eventlogging::deployment::target
#
# Abstracts use of scap::target for multiple eventlogging deployment targets.
# A corresponding 'eventlogging/$title' scap::source in the
# scap::server::sources hiera variable must be declared.
# See: hieradata/common/scap/server.yaml and
#      modules/scap/manifests/deploy
#
# == Parameters
#
# [*package_name*]
#   The name of the scap3 deployment package Default: eventlogging/$title
#
# [*service_name*]
#   service_name to pass to scap::target for sudo rules.  Default: undef
#
# [*sudo_rules*]
#   Array of extra sudo rules to pass to scap::target.
#   Default: undef
#
# == Usage
#
#   # Deploy eventlogging/eventbus here, and allow
#   # eventlogging user to restart eventlogging-service-eventbus.
#   eventlogging::deployment::target { 'eventbus':
#       service_name => 'eventlogging-service-eventbus',
#   }
#
#   # Deploy eventlogging/eventlogging here, and allow
#   # eventlogging user to run eventloggingctl as root.
#   eventlogging::deployment::target { 'eventlogging':
#       sudo_rules => ['ALL=(root) NOPASSWD: /sbin/eventloggingctl *']
#   }
#
define eventlogging::deployment::target(
    $package_name = "eventlogging/${title}",
    $service_name = undef,
    $sudo_rules   = undef,
) {
    # Install eventlogging dependencies from .deb packages.
    include ::eventlogging::dependencies

    scap::target { "eventlogging/${title}":
        package_name => $package_name,
        deploy_user  => 'eventlogging',
        service_name => $service_name,
        sudo_rules   => $sudo_rules,
        manage_user  => false,
    }

    # Needed because scap::target doesn't manage_user.
    ssh::userkey { 'eventlogging':
        ensure  => 'present',
        content => secret('keyholder/eventlogging.pub'),
    }
}
