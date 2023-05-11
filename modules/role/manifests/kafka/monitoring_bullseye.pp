# SPDX-License-Identifier: Apache-2.0
class role::kafka::monitoring_bullseye {

    system::role { 'kafka::monitoring_bullseye':
        description => 'Kafka consumer groups lag monitoring'
    }

    include profile::base::production
    include profile::firewall
    include profile::kafka::monitoring
}
