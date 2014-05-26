# Sets up a mongodb master
class toollabs::mongo::master inherits toollabs {
    include toollabs::infrastructure

   class { "mongodb":
       settings              => {
           security          => {
               authorization => "enabled"
           }
       }
   }
}
