# SPDX-License-Identifier: Apache-2.0

# @type Prometheus::Blackbox::SmokeHosts

# A map from hostname to host metadata for Blackbox to probe.

type Prometheus::Blackbox::SmokeHosts = Hash[
  Stdlib::Fqdn,
  Prometheus::Blackbox::Host
]
