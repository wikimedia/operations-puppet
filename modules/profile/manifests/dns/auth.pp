# SPDX-License-Identifier: Apache-2.0
class profile::dns::auth {
    include ::profile::dns::auth::acmechief_target
    include ::profile::dns::auth::monitoring
    include ::profile::dns::auth::discovery
    include ::profile::dns::auth::config
    include ::profile::dns::auth::update
    include ::profile::dns::auth::dotls
    include ::profile::dns::auth::perf
    include ::profile::dns::check_dns_query
    include ::profile::bird::anycast

    class { 'gdnsd': }
}
