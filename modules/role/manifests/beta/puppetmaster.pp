# = Class: role::beta::puppetmaster
# Add nice things to the beta puppetmaster.
class role::beta::puppetmaster {
    class { 'puppetmaster::logstash':
        logstash_host => 'deployment-logstash2.deployment-prep.eqiad.wmflabs',
        logstash_port => 5229,
    }
}

