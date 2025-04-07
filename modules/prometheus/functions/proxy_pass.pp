# SPDX-License-Identifier: Apache-2.0

# Given a single Prometheus instance configuration, return either a URL or a
# list of URLs where the instance can be found.
function prometheus::proxy_pass (
  Hash $config,
  Stdlib::Fqdn $localhost = $facts['networking']['fqdn'],
) {
  if $localhost in $config['hosts'] {
    "http://localhost:${config['port']}/${config['instance']}"
  } else {
    $remote_hosts = $config['hosts'].filter |$h| { $h =~ "\\.${::site}" }.map |$h| { "https://${h}/${config['instance']}" }
    if empty($remote_hosts) {
      fail('No remote hosts found, aborting')
    }
    $remote_hosts
  }
}
