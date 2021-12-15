# == Class: role::apifeatureusage::logstash
#
# Provisions Api Feature Usage log colector.
#
class role::apifeatureusage::logstash {
  system::role { 'apifeatureusage::logstash':
    description => 'Api Feature Usage Logstash collector',
  }

  include profile::base::production
  include profile::base::firewall
  include profile::apifeatureusage::logstash

}
