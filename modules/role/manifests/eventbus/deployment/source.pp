# == Class role::eventbus::deployment::source
# Configures a deploy server to deploy eventlogging source
# for the eventbus service.  Scap configs must exist
# in the scap/eventlogging/eventbus repo.
#
class role::eventbus::deployment::source {
    eventlogging::deployment::source { 'eventbus': }
}
