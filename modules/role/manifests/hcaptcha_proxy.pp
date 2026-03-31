# SPDX-License-Identifier: Apache-2.0
class role::hcaptcha_proxy {
    include profile::base::production
    include profile::firewall
    include profile::hcaptcha::proxy
    include profile::nginx
}
