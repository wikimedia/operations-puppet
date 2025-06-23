# SPDX-License-Identifier: Apache-2.0
# == Class profile::analytics::geoip
#
# This class simply ensures that the geoip databases are present on a host
class profile::analytics::geoip {
    ensure_resource('class', 'geoip')
}
