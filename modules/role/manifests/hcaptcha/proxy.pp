# SPDX-License-Identifier: Apache-2.0
class role::hcaptcha::proxy {
    include profile::base::production
    include profile::bird::anycast
    include profile::firewall
    include profile::hcaptcha::proxy
    include profile::nginx
}
