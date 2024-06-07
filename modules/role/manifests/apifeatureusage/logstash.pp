# == Class: role::apifeatureusage::logstash
#
# Provisions Api Feature Usage log colector.
#
class role::apifeatureusage::logstash {
  include profile::base::production
  include profile::firewall
  include profile::apifeatureusage::logstash
}
