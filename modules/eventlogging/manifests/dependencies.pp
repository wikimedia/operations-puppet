# == Class: eventlogging::dependencies
#
# EventLogging is a platform for modeling, logging and processing
# arbitrary schemaed JSON data.
#
# This class only installs dependencies. If you want to configure an
# eventlogging server that will run eventlogging service daemons, include the
# eventlogging::server class, or use one or more of the
# eventlogging::service::* defines.
#
# If you want just a unmanaged clone of eventlogging source code to use,
# use the eventlogging class.
#
class eventlogging::dependencies {
    # Use newer  librdkafka versions from stretch backports
    if os_version('debian == stretch') {
        apt::pin { 'librdkafka1':
            pin      => 'release a=stretch-backports',
            package  => 'librdkafka1',
            priority => '1001',
        }
    }

    # Install all eventlogging dependencies from .debs.
    require_package([
        'python-dateutil',
        'python-jsonschema',
        'python-confluent-kafka',
        # Python snappy allows python-kafka to consume Snappy compressed data.
        'python-snappy',
        'python-mysqldb',
        'python-pygments',
        'python-pykafka',
        'python-six',
        'python-sqlalchemy',
        'python-statsd',
        'python-yaml',
        'python-zmq',
        'python-ua-parser'
    ])

    # Ensure python-kafka for eventlogging
    # is at 1.4.1.  There is an upstream bug
    # https://github.com/dpkp/kafka-python/issues/1418.
    # Our apt repo (as of 2019-09) has python-kafka 1.4.6
    # for use with coal.  We want to ensure we
    # don't accidentally upgrade on eventloggging
    # until this is fixed.
    # See also: https://phabricator.wikimedia.org/T222941
    if !defined(Package['python-kafka']) {
        package { 'python-kafka':
            ensure => '1.4.1-1~stretch1'
        }
    }
}
