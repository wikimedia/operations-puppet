# SPDX-License-Identifier: Apache-2.0
# @summary
#   Install and configures Dragonfly supernode (with cdn pattern "source").
#
# @param listen_port
#   The TCP port supernode will listen for connections of P2P nodes (dfget) on.
#
# @param download_port
#   The TCP port of a local HTTP server (needs to be provided manually) which is used as source for initial parts (seeder)
#   by P2P clients (dfget). It should be set to @listen_port if @cdn_pattern = 'source' is used, see:
#   https://github.com/dragonflyoss/Dragonfly/issues/1558
#
# @param cdn_pattern
#   This may be 'local' if a local HTTP server is provided to seed parts, or 'source' if clients (dfget) should use the
#   original source as seeder for parts.
#
class dragonfly::supernode (
  Stdlib::Port::Unprivileged $listen_port = 8002,
  Stdlib::Port::Unprivileged $download_port = 8002,
  Enum['local', 'source']    $cdn_pattern = 'source',
){
  ensure_packages('dragonfly-supernode')

  file { '/etc/dragonfly/supernode.yml':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dragonfly/supernode.yml.erb'),
    notify  => Service['dragonfly-supernode'],
  }

  service { 'dragonfly-supernode':
    ensure  => running,
  }
}
