# Installs the public key for gerrit replication
#
# @param user Unix user for which to setup the public ssh key
class gerrit::replication_key(
    String $user,
    Wmflib::Ensure $ensure = present,
){
    ssh::userkey { 'gerrit-replication-publickey':
        ensure => $ensure,
        user   => $user,
        source => 'puppet:///modules/gerrit/id_rsa.pub'
    }
}
