# vim: set noet:

# Python testing module:
import unittest

# Interpret the 'templates/gerrit/hookconfig.py.erb' template to generate
# a local 'hookconfig' python module with variables filled with test data.
# We shell out to ruby since there is no easy way to expand an erb template
# using python.
import os
ruby_exit_code = os.system( "./generatehookconfig.rb > hookconfig.py" );
if ruby_exit_code != 0:
	import sys
	sys.exit( "Could not execute generatehookconfig.rb" );

# Class we are going to test:
from hookhelper import HookHelper
# Config need to be global in the test suite too:
import hookconfig

helper = HookHelper()

class TestLogToFile( unittest.TestCase ):

	def assertLogFile( self, filename, project, branch ):

		# Ask helper to provide us with the full filename
		actual = helper.get_log_filename( project, branch, '' )
		# and now get ride of the common long directory
		actual = actual.replace( hookconfig.logdir + "/", '' );

		self.assertEqual( filename, actual )

	def test_operations_puppet( self ):
		self.assertLogFile( 'operations.log',
			'operations/puppet',
			'production' )
		self.assertLogFile( 'labs.log',
			'operations/puppet',
			'test' )
		self.assertLogFile( 'labs.log',
			'operations/puppet',
			'IAmNotConfigured' )

	def test_labs_private_to_labs( self ):
		self.assertLogFile( 'labs.log',
			'labs/private',
			'a_branch' )

	def test_labs_default_to_mediawiki( self ):
		self.assertLogFile( 'mediawiki.log',
			'labs/someproject',
			'a_branch' )

	def test_operations_software_to_operations( self ):
		self.assertLogFile( 'operations.log',
			'operations/software',
			'a_branch' )

	def test_operations_dumps_to_operations( self ):
		self.assertLogFile( 'operations.log',
			'operations/dumps',
			'a_branch' )

	def test_operations_to_operations( self ):
		self.assertLogFile( 'operations.log',
			'operations/someProject',
			'a_branch' )

	def test_catchall_to_mediawiki( self ):
		self.assertLogFile( 'mediawiki.log',
			'departement/project',
			'a_branch' )

unittest.main()
