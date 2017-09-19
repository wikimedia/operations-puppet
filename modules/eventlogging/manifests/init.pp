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
}
