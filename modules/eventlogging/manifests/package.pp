# == Class: eventlogging::package
#
# This class configures a host for having EventLogging software deployed on it.
# As of July 2013, EventLogging's dependencies are available in apt, but
# EventLogging itself is distributed via Trebuchet.
#
class eventlogging::package {
    $path = '/srv/deployment/eventlogging/EventLogging'

    require_package([
        'python-jsonschema',
        'python-kafka',
        'python-mysqldb',
        'python-pygments',
        'python-pymongo',
        'python-six',
        'python-sqlalchemy',
        'python-zmq',
    ])

    package { 'eventlogging/EventLogging':
        provider => 'trebuchet',
        before   => File['/etc/init/eventlogging'],
    }
}
