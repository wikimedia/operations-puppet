# Installs the public key for gerrit replication
class gerrit::replication_key(
    String $user = 'gerrit2',
    Wmflib::Ensure $ensure = present,
){
    ssh::userkey { 'gerrit-replication-publickey':
        ensure => $ensure,
        user   => $user,
        source => 'puppet:///modules/gerrit/id_rsa.pub'
    }
}
