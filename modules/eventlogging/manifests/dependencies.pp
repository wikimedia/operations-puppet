# == Class: eventlogging::dependencies
#
# EventLogging is a platform for modeling, logging and processing
# arbitrary schemaed JSON data.
#
# This class only installs dependencies.  To set up a deployment target, use
# the eventlogging::deployment::target define.  If you want to configure an
# eventlogging server that will run eventlogging service daemons, include the
# eventlogging::server class, or use one or more of the
# eventlogging::service::* defines.
#
# If you want just a unmanaged clone of eventlogging source code to use,
# use the eventlogging class.
#
class eventlogging::dependencies {
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
}
