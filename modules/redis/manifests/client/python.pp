# == Class: redis::client::python
#
# This module declares the Python client library for redis.
#
class redis::client::python {
    require_package('python-redis')
}
