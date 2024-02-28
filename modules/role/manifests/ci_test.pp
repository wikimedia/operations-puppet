# SPDX-License-Identifier: Apache-2.0
#
# role::ci_test
#
class role::ci_test {
    system::role { 'ci_test': description => 'CI test server' }

    include ::profile::base::production

    include ::profile::zuul::merger
    include ::profile::zuul::server
    include ::profile::ci::proxy_zuul
}
