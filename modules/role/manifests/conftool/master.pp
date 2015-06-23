# === Class role::conftool::master
#
# This class sets up a conftool master server.
#
class role::conftool::master {

    system::role { 'conftool-master':
        description => "Conftool master",
    }

    require puppetmaster::gitclone
    require puppetmaster::scripts
    include conftool

}
