# = class: role::scap::master
#
# Sets up a scap master 
class role::scap::master {
    system::role { 'misc::deployment': 
        description => 'Deployment host' 
    }

    include scap::master
    include scap::l10nupdate
}
