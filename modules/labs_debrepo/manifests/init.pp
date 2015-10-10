# Puppet configuration to create local deb repositories and add them
# to your sources.list.

class labs_debrepo {
    labs_debrepo::repo { '/data/project/repo':
    }
}
