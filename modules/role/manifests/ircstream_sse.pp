# SPDX-License-Identifier: Apache-2.0

class role::ircstream_sse {
    include profile::base::production
    include profile::firewall
    include profile::ircstream
}
