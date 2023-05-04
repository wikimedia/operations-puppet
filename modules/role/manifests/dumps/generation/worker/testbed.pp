# SPDX-License-Identifier: Apache-2.0
class role::dumps::generation::worker::testbed {
    include ::profile::base::production
    include ::profile::base::firewall

    include profile::dumps::generation::worker::common
    include profile::dumps::generation::worker::crontester

    include profile::dumps::generation::worker::nfstester

    system::role { 'dumps::generation::worker::testbed':
        description => 'testbed for dumps of XML/SQL wiki content',
    }
}
