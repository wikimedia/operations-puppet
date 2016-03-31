# == Define eventlogging::deployment::target
#
# Abstracts use of scap::target for multiple eventlogging
# deployment targets.
#
# TODO: Use $sudo_rules after https://gerrit.wikimedia.org/r/#/c/279717/
#       is merged.
#
# == Parameters
# [*package_name*]
#   Default: eventlogging/$title
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
    $sudo_rules = undef,
) {
    include eventlogging
    $path = "/srv/deployment/${package_name}"

    # eventlogging code for eventbus is configured to deploy
    # from the eventlogging/eventbus deploy target
    # via scap/scap.cfg on the deployment host.
    scap::target { $package_name:
        deploy_user       => 'eventlogging',
        public_key_source => "puppet:///modules/eventlogging/deployment/eventlogging_rsa.pub.${::realm}",
        service_name      => $service_name,
        sudo_rules        => $sudo_rules,
        manage_user       => false,
    }
}
