# == Class: scap::server
#
# Configures dependencies for a scap3 deployment server.  This includes
# setting up ssh agent keys and repositories configured for deployment.
#
# This class creates keyholder::agent and scap::source resources based on
# the contents of the 'keyholder::agents' and 'scap::sources' hiera variables.
# These would be class parameters instead of hiera lookups, if it were possible
# to do a hiera hash merge using class parameters.  Since hash merge doesn't
# work with class paramaters, these are looked up via hiera_hash and
# must be defined as noted above.
#
# Legacy scap and mediawiki deployment dependencies are in
# scap::master.
#
# == Parameters
#
# [*keyholder_agents*]
#   Hash of keyholder::agent resource declarations to be passed to
#   the create_resources() function.  Default: {}
#
#   keyholder is an ssh agent proxy that allows members of select groups to
#   connect using ssh keys shared with the group. This facilitates multiple
#   deployers to deploy over ssh to corresponding scap::target instances.
#   See keyholder::agent for more information.
#
#   $keyholder_agents lists the details of each ssh key.
#   Actual keys are stored in the `secret` module
#   which is kept in a private location in the puppet modulepath.
#
# [*sources*]
#   Hash of scap::source resource declarations to be passed to
#   the create_resources() function.  Default: {}
#
#   Each repository listed will be cloned via declaration of the
#   scap::source define. You should use scap::target directly on your
#   target hosts that are declared with $package_name matching the keys in
#   this hash.
#   See scap::source for more information.
#
# == Usage
#
#   class { 'scap::server':
#       keyholder_agents => {
#           'deploy-service' => {
#               'trusted_groups' => 'deploy-service',
#           },
#       },
#       sources => {
#           'myrepo/instance' => {
#               'repository' => 'myrepo',
#           },
#       },
#   }
#
class scap::server(
    $keyholder_agents   = {},
    $sources            = {},
) {
    require ::scap

    # Create an instance of $keyholder_agents for each of the key specs.
    create_resources('keyholder::agent', $keyholder_agents)

    # Create an instance of scap::source for each of the key specs in hiera.
    create_resources('scap::source', $sources)
}
