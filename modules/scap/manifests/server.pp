# == Class: scap::server
#
# Configures the bare minimum dependencies for a scap3
# deployment server.  Legacy scap and mediawiki deployment dependencies are in
# scap::master.
#
# This class creates keyholder::agent and scap::source resources based on
# the contents of the 'keyholder::agents' and 'scap::sources' hiera variables.
#
class scap::server {
    require ::keyholder
    require ::keyholder::monitoring
    require ::scap

    # keyholder is an ssh agent proxy that allows members of select groups to
    # connect using ssh keys shared with the group. This facilitates multiple
    # deployers to deploy over ssh to corresponding scap::target instances.

    # For a given deployment server, we list the details of each key in hiera
    # under keyholder::agents, actual keys are stored in the `secret` module
    # which is kept in a private location in the puppet modulepath.
    $agent_keys = hiera_hash('keyholder::agents', {})

    # Create an instance of keyholder::agent for each of the key specs in hiera:
    create_resources('keyholder::agent', $agent_keys)

    # Each repository listed in scap::sources hiera variable
    # will be cloned via declaration of the scap::source define.
    # You should use scap::target directly on your target hosts that
    # are declared with $package_name matching the keys in the
    # scap::sources hiera variable.
    $scap_sources = hiera_hash('scap::sources', {})
    create_resources('scap::source', $scap_sources)
}
