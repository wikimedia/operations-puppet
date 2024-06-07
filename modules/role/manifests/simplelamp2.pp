# SPDX-License-Identifier: Apache-2.0
# = class: role::simplelamp2
#
# Sets up a simple LAMP server for use by arbitrary php applications
#
# httpd ("apache"), memcached, PHP, MariaDB
#
# As opposed to the original simplelamp role it uses
# MariaDB instead of MySQL and the httpd instead of the apache module.
#
class role::simplelamp2 {
    include profile::simplelamp2
}
