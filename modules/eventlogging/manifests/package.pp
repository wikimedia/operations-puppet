# == Class: eventlogging::package
#
# This class configures a host for having EventLogging software deployed on it.
# As of July 2013, EventLogging's dependencies are available in apt, but
# EventLogging itself is distributed via Trebuchet.
#
class eventlogging::package {
    $path = '/srv/deployment/eventlogging/eventlogging'

    require_package([
        'python-etcd',
        'python-jsonschema',
        'python-kafka',
        'python-mysqldb',
        'python-pygments',
        'python-pykafka',
        'python-pymongo',
        'python-six',
        'python-sqlalchemy',
        'python-zmq',
    ])

    package { 'eventlogging/eventlogging':
        provider => 'trebuchet',
    }
}
