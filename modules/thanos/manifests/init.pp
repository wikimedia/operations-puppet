# SPDX-License-Identifier: Apache-2.0
class thanos {
    exec { 'reload thanos-rule':
        # Workaround for SIGHUP not working in thanos 0.21.1
        # https://github.com/thanos-io/thanos/issues/4432
        # https://phabricator.wikimedia.org/T303154
        command     => '/usr/bin/curl -X POST localhost:17902/-/reload',
        refreshonly => true,
    }
}
