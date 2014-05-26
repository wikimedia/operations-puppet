# Sets up a mongodb master
class toollabs::mongo::master inherits toollabs {
    include toollabs::infrastructure
    include role::labs::lvm::srv

    class { "mongodb":
        settings              => {
            security          => {
                authorization => "enabled"
            }
        }
   }
}
