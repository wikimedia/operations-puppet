# Installs the public key for gerrit replication
class gerrit::replication_key($user = 'gerrit2', $ensure = present) {
    ssh::userkey { 'gerrit-replication-publickey':
        ensure => $ensure,
        user   => $user,
        source => 'puppet:///modules/gerrit/id_rsa.pub'
    }
}
