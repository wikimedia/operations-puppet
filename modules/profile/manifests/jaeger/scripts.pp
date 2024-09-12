# SPDX-License-Identifier: Apache-2.0
class profile::jaeger::scripts {
  ensure_packages(['python3-opensearch'])

  file { '/usr/local/bin/jaeger-find-traces':
    ensure => present,
    mode   => '0555',
    source => 'puppet:///modules/profile/jaeger/find-traces.py',
  }
}
