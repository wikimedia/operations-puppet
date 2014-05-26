# Sets up a mongodb master
class toollabs::mongo::master inherits toollabs {
    include toollabs::infrastructure

    # We need all the space we can get!
    include role::labs::lvm::srv

    class { "mongodb":
        storage    => {
            dbPath      => "/srv/mongod"
        },
        systemLog       => {
            destination => 'file',
            logAppend   => true,
            path        => '/var/log/mongodb/mongodb.log',
        },
        settings              => {
            security          => {
                authorization => "enabled"
            }
        }
   }
}
