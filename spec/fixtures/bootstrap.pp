# vim: ts=2 sw=2 noet
#
# This puppet manifest is the entry point for our rspec tests. It gives
# us a chance to define several variables before importing our whole puppet
# project.
#

# This would let us add exceptions in our regular manifests for some corner
# cases such as preventing the execution of script which is obviously not
# available on the testing machine. A typical example is:
#
#   generate( '/usr/local/bin/phase-of-the-moon' )
# One could just wrap it in the manifest with:
#  if( !$testing_in_rspec ) {
#   // do something with generate( 'somescript' )
#  }
$testing_in_rspec = true


###### Import the regular manifests ###################################
# FIXME autoloader does not find our class so we lamely import everything
# which REALLY slowdown tests
import 'manifests/site.pp'
