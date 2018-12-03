#!/usr/bin/python3
import sys
import getopt
from subprocess import Popen, PIPE


#############################################################
# This file is maintained by puppet!
# puppet:///modules/snapshot/cron/runphpscriptletonallwikis.py
#############################################################


class PhpRunner():
    """Run a maintenance 'scriptlet' on all wikis
    The maintenance class framework is set up already;
    the caller should supply a few lines of code that would
    go into the execute function."""
    def __init__(self, script_path, php_body, multiversion, wiki):
        self.script_path = script_path
        self.php_body = php_body
        self.multiversion = multiversion
        self.wiki = wiki

    def run_php_scriptlet(self):
        command = ["php", "--", "--wiki=%s" % self.wiki]
        return self.run_command(command)

    def run_command(self, command):
        result = True
        try:
            proc = Popen(command, stdin=PIPE, stdout=PIPE, stderr=PIPE)
            output, error = proc.communicate(self.get_php_code().encode('utf-8'))
            if proc.returncode:
                # don't barf, let the caller decide what to do
                sys.stderr.write("command '%s failed with return code %s and "
                                 "error %s\n" % (command,
                                                 proc.returncode, error.decode('utf-8')))
                result = False
            print(output.decode('utf-8'))
            if error:
                sys.stderr.write(error.decode('utf-8') + '\n')
        except Exception:
            sys.stderr.write("command %s failed\n" % command)
            raise
        return result

    def get_php_code(self):
        if self.multiversion:
            php_setup = (
                "require_once( '%s/MWMultiVersion.php' ); "
                "$dir = MWMultiVersion::getMediaWikiCli(''); "
                "require_once( \"$dir/maintenance/Maintenance.php\" );"
                % self.script_path)
        else:
            php_setup = ("require_once( '%s/maintenance/Maintenance.php' );"
                         % self.script_path)
        return "<?php\n" + php_setup + self.fillin_scriptlet_template()

    def fillin_scriptlet_template(self):
        return """
class MaintenanceScriptlet extends Maintenance {
    public function __construct() {
        parent::__construct();
    }
    public function execute() {
    %s
    }
}
$maintClass = "MaintenanceScriptlet";
require_once( RUN_MAINTENANCE_IF_MAIN );
""" % self.php_body


def usage(message):
    if message:
        sys.stderr.write(message + '\n')
    usagemessage = """Usage: python3 runphpscriptletonallwikis.py --scriptpath path
                 [--wikilist value] [--multiversion] [--multiversion]
                 [--scriptlet text] [--scriptletfile filename] [wikiname]

Options:

--scriptpath:    path to MWMultiVersion.php, if multiversion option is set,
                 or to maintenance/Maintenance.php, otherwise
--wikilist:        path to list of wiki database names one per line
                 if filename is '-' then the list will be read from stdin
--multiversion:  use the WMF multiversion het deployment infrastructure
--scriptlet:     the php code to run, if not provided in a file
--scriptletfile: a filename from which to read the php code to run

Arguments:

wikiname:  name of wiki to process, if specified overrides wikilist

Example:
python3 runphpscriptletonallwikis.py enwiki
"""
    sys.stderr.write(usagemessage)
    sys.exit(1)


def do_main():
    wiki_list_file = None
    script_path = None
    scriptlet = None
    scriptlet_file = None
    multiversion = False
    wiki = None

    try:
        (options, remainder) = getopt.gnu_getopt(sys.argv[1:], "",
                                                 ["wikilist=", "multiversion",
                                                  "scriptpath=", "scriptlet=",
                                                  "scriptletfile="])
    except:
        usage("Unknown option specified")

    for (opt, val) in options:
        if opt == "--wikilist":
            wiki_list_file = val
        elif opt == "--multiversion":
            multiversion = True
        elif opt == "--scriptpath":
            script_path = val
        elif opt == "--scriptlet":
            scriptlet = val
        elif opt == "--scriptletfile":
            scriptlet_file = val

    if remainder:
        if len(remainder) > 1 or remainder[0].startswith("--"):
            usage("Unknown option specified")
        wiki = remainder[0]

    if (not wiki and not wiki_list_file):
        usage("One of wiki or wikilist must be specified")

    if not script_path:
        usage("script_path must be specified")

    if not scriptlet and not scriptlet_file:
        usage("One of scriptlet or scriptletfile must be specified")

    if scriptlet and scriptlet_file:
        usage("Only one of scriptlet or scriptletfile may be specified")

    if wiki:
        wiki_list = [wiki]
    else:
        if wiki_list_file == "-":
            fdesc = sys.stdin
        else:
            fdesc = open(wiki_list_file, "r")
        wiki_list = [line.strip() for line in fdesc]

        if fdesc != sys.stdin:
            fdesc.close()

    if scriptlet_file:
        fdesc = open(scriptlet_file, "r")
        scriptlet = fdesc.read()
        fdesc.close()

    fails = 0
    for wiki in wiki_list:
        prunner = PhpRunner(script_path, scriptlet, multiversion, wiki)
        if not prunner.run_php_scriptlet():
            fails += 1
    if fails:
        sys.stderr.write("%s job(s) failed, see output for details.\n" % fails)


if __name__ == "__main__":
    do_main()
