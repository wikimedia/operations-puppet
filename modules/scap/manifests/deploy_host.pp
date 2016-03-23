# = class: scap::deploy_host
#
# configures the bare minimum dependencies for a scap3
# deployment host.  legacy scap and mediawiki deployment dependencies are in
# scap::master
class scap::deploy_host() {
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
}
