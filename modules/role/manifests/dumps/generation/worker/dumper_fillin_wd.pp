# SPDX-License-Identifier: Apache-2.0

class role::dumps::generation::worker::dumper_fillin_wd {
    include ::profile::base::production
    include ::profile::firewall

    include profile::dumps::generation::worker::common
    include profile::dumps::generation::worker::dumper_fillin_wd
    include profile::dumps::generation::worker::crontester

    system::role { 'dumps::generation::worker::dumper':
        description => 'fill-in dumper of XML/SQL wiki content (wikidatawiki)',
    }
}
