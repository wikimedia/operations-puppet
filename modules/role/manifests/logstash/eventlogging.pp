# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash::eventlogging
#
# Configure Logstash to consume validation logs from EventLogging.
#
# filtertags: labs-project-deployment-prep
class role::logstash::eventlogging {
    include ::standard
    include ::base::firewall
    include ::role::lvs::realserver
    include ::profile::logstash::elasticsearch
    include ::profile::logstash::collector
    include ::profile::logstash::apifeatureusage
    include ::profile::logstash::eventlogging

    system::role { 'logstash::eventlogging':
        ensure      => 'present',
        description => 'logstash frontend and eventlogging collector',
    }
}
