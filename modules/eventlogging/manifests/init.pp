# == Class: eventlogging
#
# EventLogging is a platform for modeling, logging and processing
# arbitrary schemaed JSON data.
#
# This class only installs dependencies and sets up eventlogging code
# deployment.  If you want to configure an eventlogging server that
# will run eventlogging service daemons, include the eventlogging::server
# class, or use one or more of the eventlogging::service::* defines.
#
class eventlogging {
    # Install all eventlogging dependencies from .debs.
    require_package([
        'python-dateutil',
        'python-jsonschema',
        'python-kafka',
        'python-mysqldb',
        'python-pygments',
        'python-pykafka',
        'python-pymongo',
        'python-six',
        'python-sqlalchemy',
        'python-statsd',
        'python-yaml',
        'python-zmq',
    ])

    # TODO: use scap everywhere.
    # This conditional only exists so as not to conflict with
    # the scap Jessie deployment of eventlogging-service-eventbus.
    # Once we use scap, we might be able to remove this.
    if $::operatingsystem == 'Ubuntu' {
        package { 'eventlogging/eventlogging':
            provider => 'trebuchet',
        }
    }
}
