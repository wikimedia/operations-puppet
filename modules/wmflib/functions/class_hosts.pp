# @summary function to return a list of hosts running a specific class
#  This function relies on data being present in puppetdb.  This means that new nodes will
#  be returned after their first successful puppet run using the specified class.  It also means
#  that nodes will be removed from the results once they have been purged from puppetdb.  This currently
#  happens when a server has failed to run puppet for 14 days
# @param class the class to search for
# @param optional list of sites if present filter to output based on the sites passed
function wmflib::class_hosts (
    String[1]                                    $class,
    Variant[Wmflib::Sites, Array[Wmflib::Sites]] $location = [],
) >> Array[Stdlib::Host] {

    $_class = $class.split('::').capitalize.join('::')
    wmflib::resource_hosts('class', $location, $_class)
}
