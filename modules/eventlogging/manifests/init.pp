# == Class eventlogging
#
# TODO: Implement the following as part of T118772:
#
# Currently, this class only installs EventLogging dependencies
# and ensures that an unmanaged cloned at /usr/local/src/eventlogging
# exists.  If you want to update eventlogging code, you must manually
# pull it.
#
class eventlogging {
    include ::eventlogging::dependencies

    # TEMPORARY HACK!!!
    # TODO: use scap everywhere: T118772
    # This conditional only exists so as not to conflict with
    # the scap Jessie deployment of eventlogging-service-eventbus.
    # Once we use scap, we might be able to remove this.
    if $::operatingsystem == 'Ubuntu' or $::hostname == 'hafnium' {
        package { 'eventlogging/eventlogging':
            provider => 'trebuchet',
        }
    }
}
