# == Class: redis::client::python
#
# This module declares the Python client library for redis.
#
class redis::client::python {
    if (debian::codename::ge('bullseye')) {
        ensure_packages('python3-redis')
    } else {
        ensure_packages('python-redis')
    }
}
