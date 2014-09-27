# == Class: eventlogging::deployment
#
# This class manages the deployment configuration for EventLogging.
#
class eventlogging::deployment {
    $path = '/srv/deployment/eventlogging/EventLogging'

    package { 'eventlogging':
        provider => 'trebuchet',
        before   => File['/etc/init/eventlogging'],
    }
}
