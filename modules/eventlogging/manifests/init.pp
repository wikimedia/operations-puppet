# == Class eventlogging
#
# Currently, this class only installs EventLogging dependencies
# and ensures that an unmanaged cloned at /usr/local/src/eventlogging
# exists.  If you want to update eventlogging code, you must manually
# pull it.
#
class eventlogging {
    include ::eventlogging::dependencies
}
