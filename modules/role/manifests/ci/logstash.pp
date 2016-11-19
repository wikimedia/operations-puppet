#
# https://logstash-beta.wmflabs.org/
#
class role::ci::logstash {

    require role::labs::lvm::srv

    # Configuration done via Hiera in Horizon
    include role::logstash
    include role::kibana

    ferm::service { 'CI_Jenkins_master':
        proto  => 'tcp',
        port   => '9200',
        srange => '@resolve(contint1001.wikimedia.org)',
    }

}
