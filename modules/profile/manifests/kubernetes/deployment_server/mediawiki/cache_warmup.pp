# SPDX-License-Identifier: Apache-2.0
class profile::kubernetes::deployment_server::mediawiki::cache_warmup {
    ensure_packages('python3-kubernetes')

    class { '::mediawiki::maintenance::cache_warmup':
        ensure => present,
    }
}
