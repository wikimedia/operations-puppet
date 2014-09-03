# == Class: redis::client::python
#
# This module declares the Python client library for redis.
#
class redis::client {
    package { 'python-redis':
        ensure => present,
    }
}
