# == Class: eventlogging::deployment
#
# This class manages the git-deploy configuration for EventLogging.
#
class eventlogging::deployment {
    $path = '/srv/deployment/eventlogging/EventLogging'

    deployment::target { 'eventlogging':
        before => File['/etc/init/eventlogging'],
    }
}
