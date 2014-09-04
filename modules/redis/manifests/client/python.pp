# == Class: redis::client::python
#
# This module declares the Python client library for redis.
#
class redis::client::python {
    package { 'python-redis':
        ensure => present,
    }
}
