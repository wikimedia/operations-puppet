# Python testing module:
import unittest

# Interpret the 'templates/gerrit/hookconfig.py.erb' template to generate
# a local 'hookconfig' python module with variables filled with test data.
# We shell out to ruby since there is no easy way to expand an erb template
# using python.
import os
ruby_exit_code = os.system("./generatehookconfig.rb > hookconfig.py")
if ruby_exit_code != 0:
    import sys
    sys.exit("Could not execute generatehookconfig.rb")

# Class we are going to test:
from hookhelper import HookHelper
# Config need to be global in the test suite too:
import hookconfig

helper = HookHelper()


class TestLogToFile(unittest.TestCase):
    def assertLogFile(self, filename, project, branch='master'):

        # Ask helper to provide us with the full filename
        actual = helper.get_log_filename(project, branch, '')
        # and now get ride of the common long directory
        actual = actual.replace(hookconfig.logdir + "/", '')

        self.assertEqual(filename, actual)

    def test_operations_puppet(self):
        self.assertLogFile('operations.log',
            'operations/puppet',
            'production')
        self.assertLogFile('labs.log',
            'operations/puppet',
            'test')
        self.assertLogFile('labs.log',
            'operations/puppet',
            'IAmNotConfigured')

    def test_labs_private_to_labs(self):
        self.assertLogFile('labs.log',
            'labs/private')

    def test_labs_to_wikimedia_labs(self):
        self.assertLogFile('labs.log',
            'labs/someproject')

    def test_operations_software_to_operations(self):
        self.assertLogFile('operations.log',
            'operations/software')

    def test_operations_dumps_to_operations(self):
        self.assertLogFile('operations.log',
            'operations/dumps')

    def test_operations_to_operations(self):
        self.assertLogFile('operations.log',
            'operations/someProject')

    # Some very specific WMF projects
    def test_parsoid(self):
        self.assertLogFile('parsoid.log',
            'mediawiki/extensions/Parsoid')

    def test_mobile(self):
        self.assertLogFile('mobile.log',
            'mediawiki/extensions/MobileFrontend')

    def test_visualeditor(self):
        self.assertLogFile('visualeditor.log',
            'mediawiki/extensions/VisualEditor')

    # Semantic MediaWiki related
    def test_semantic_mediawiki(self):
        for repo in [
            'SemanticFoobar',
            'Validator',
            'Maps',
            'RDFIO',
            'SolrStore',
            'SMWFoobar',
            ]:
            self.assertLogFile('semantic-mediawiki.log',
                'mediawiki/extensions/%s' % repo
            )

    # Wikidata related
    def test_wikidata_extensions(self):
        for repo in [
            'Wikibase',
            'Diff',
            'DataValues',
            ]:
            self.assertLogFile('wikidata.log',
                'mediawiki/extensions/%s' % repo
            )

    def test_core_wikidata_branch(self):
        # Wikidata branch is sent to a specific log
        self.assertLogFile('wikidata.log',
            'mediawiki/core',
            'Wikidata'
        )
        # Make sure mediawiki/core.git@master is still sent to #mediawiki
        self.assertLogFile('mediawiki.log',
            'mediawiki/core',
            'master'
        )

    def test_mediawiki_tools_to_wikimediadev(self):
        self.assertLogFile('wikimedia-dev.log',
            'mediawiki/tools/codesniffer')
        self.assertLogFile('wikimedia-dev.log',
            'mediawiki/tools/upload/PhotoUpload')

    def test_catchall_to_mediawiki(self):
        self.assertLogFile('mediawiki.log',
            'department/project')

    def test_qa_to_wikimediadev(self):
        self.assertLogFile('wikimedia-dev.log',
            'qa/browsertests')

if __name__ == '__main__':
    unittest.main()
