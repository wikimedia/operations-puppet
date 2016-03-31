# == Define eventlogging::deployment::source
#
# Sets up scap3 deployment source on a deploy server for the eventlogging
# source repository.
#
# This expects that your scap directory is hosted in a repository
# at scap/eventlogging/$title.  This repository will be cloned
# alongside of the eventlogging source repo on the deploy server.
#
# == Usage
#
#   # Make sure both of 'eventlogging' and 'scap/eventlogging/eventbus'
#   # are both repositories in gerrit.
#   eventlogging::deployment::source { 'eventbus': }
#
define eventlogging::deployment::source()
    include ::eventlogging::deployment::keys

    # Clones the eventlogging repository into
    # /srv/deployment/eventlogging/$title and
    # clones the scap/eventlogging/$title repository
    # into /srv/deployment/eventlogging/eventbus/scap
    scap::source { "eventlogging/${title}":
        repository         => 'eventlogging',
        recurse_submodules => true,
    }
}
