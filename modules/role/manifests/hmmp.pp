# = class: role::hmmp
#
# Sets up a simple LAMP server for use by arbitrary php applications.
#
# A new LAMP or HMMP.
#
# (L)inux (A)pache (httpd) (M)emcached (M)ariaDB (P)HP
#
# Started as a copy and then replaces role::simplelamp.
#
# Uses the httpd module instead of the apache module and the
# mariadb module instead of the mysql module.
#
# The intention is to let projects migrates to the new class
# without having to do all at once and once done rename this back
# to the original name.
#
# filtertags: labs-common
class role::hmmp {

    system::role { 'HMMP': description => 'httpd - memcached - mariadb - php' }

    include ::standard
    include ::profile::hmmp
}
