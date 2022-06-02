# SPDX-License-Identifier: Apache-2.0
# PoolCounter server
# See http://wikitech.wikimedia.org/view/PoolCounter

class poolcounter {
    ensure_packages(['poolcounter'])

    service { 'poolcounter':
        ensure  => 'running',
        require => Package['poolcounter'],
    }
}
