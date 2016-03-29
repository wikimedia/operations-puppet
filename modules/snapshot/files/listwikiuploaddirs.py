import os
import sys
import getopt
from subprocess import Popen, PIPE


def get_wikis(all_wikis_file, closed_wikis_file,
              private_wikis_file, skip_wikis_file):

    closed_wikis = []
    private_wikis = []
    skip_wikis = []

    if closed_wikis_file is not None:
        fdesc = open(closed_wikis_file, "r")
        closed_wikis = [line.strip() for line in fdesc]
        fdesc.close()

    if private_wikis_file is not None:
        fdesc = open(private_wikis_file, "r")
        private_wikis = [line.strip() for line in fdesc]
        fdesc.close()

    if skip_wikis_file is not None:
        fdesc = open(skip_wikis_file, "r")
        skip_wikis = [line.strip() for line in fdesc]
        fdesc.close()

    if all_wikis_file == "-":
        fdesc = sys.stdin
    else:
        fdesc = open(all_wikis_file, "r")
    wikilist_temp = [l.strip() for l in fdesc]
    wikilist = [l for l in wikilist_temp if l not in private_wikis
                and l not in closed_wikis and l not in skip_wikis]
    if fdesc != sys.stdin:
        fdesc.close()
    return wikilist


class UploadDir(object):

    def __init__(self, multiversion, script_path, wmfhack):
        self.multiversion = multiversion
        self.script_path = script_path
        self.hack = wmfhack

    def get_media_dir(self, wiki):
        if self.hack:
            # wmf-specific magic. hate hate hate
            site, lang = self.get_dir_from_site_and_lang(wiki)
            if site and lang:
                return os.path.join(site, lang)
            else:
                return None
        else:
            return self.get_upload_dir(wiki)

    def get_dir_from_site_and_lang(self, wiki):
        """using wmf hack... get $site and $lang and build a relative path
        out of those."""
        input_text = 'global $site, $lang; echo \"$site\t$lang\";'
        # expect to find the runphpscriptlet script in dir with this script
        current_dir = os.path.dirname(os.path.realpath(__file__))
        command = ["python", os.path.join(current_dir,
                                          "runphpscriptletonallwikis.py"),
                   "--scriptpath", self.script_path, "--scriptlet", input_text]
        result = self.run_command(command, wiki)
        if not result:
            return None, None
        if '\t' not in result:
            command_string = ' '.join(command)
            sys.stderr.write("unexpected output from '%s'"
                             "(getting site and lang for %s)\n"
                             % (command_string, wiki))
            sys.stderr.write("output received was: %s\n" % result)
            return None, None
        site, lang = result.split('\t', 1)
        return site, lang

    def get_upload_dir(self, wiki):
        """yay, someone is running this elsewhere. they get
        the nice wgupload_directory value, hope that's what they
        want."""
        input_text = "global $wgupload_directory; echo \"$wgupload_directory\";"
        command = ["python", "runphpscriptletonallwikis.py", "--scriptpath",
                   self.script_path, "--scriptlet", input_text]
        return self.run_command(command, wiki)

    def run_command(self, command, wiki):
        """run a generic command (per wiki) and whine as required
        or return the stripped output"""
        if self.multiversion:
            command.append("--multiversion")
        command.append(wiki)

        command_string = ' '.join(command)
        error = None
        try:
            proc = Popen(command, stdout=PIPE, stderr=PIPE)
            output, error = proc.communicate()
        except:
            sys.stderr.write("exception encountered running command %s for "
                             " wiki %s with error: %s\n" % (command_string,
                                                            wiki, error))
            return None
        if proc.returncode or error:
            sys.stderr.write("command %s failed with return code %s and "
                             "error %s\n" % (command_string,
                                             proc.returncode, error))
            return None
        if not output or not output.strip():
            sys.stderr.write("No output from: '%s' (getting site and lang "
                             "for wiki %s)\n" % (command_string, wiki))
            return None
        return output.strip()


def usage(message=None):
    if message:
        sys.stderr.write(message)
    usagemessage = """Usage: python listwikiuploaddirs.py --allwikis filename --scriptpath dir
                                   [multiversion] [closedwikis filename]
                                   [privatewikis filename] [skipwikis filename] [wmfhack]

This script dumps a list of media upload dirs for all specified wikis.
If names of closed and/or private wikis are provided, files in these lists
will be skipped.
Note that this produces an *absolute path* based on the value of
$wgupload_directory unless the 'wmfhack' option is specified, see below for that

--allwikis:      name of a file which contains all wikis to be processed,
                 one per line; if '-' is specified, the list will be read
                 from stdin
--scriptpath:    path to MWVersion.php, if multiversion option is set,
                  (see 'multiversion' below), or to Maintenance.php otherwise

Optional arguments:

--multiversion:  use the WMF multiversion het deployment infrastructure
--closedwikis:   name of a file which contains all closed wikis (these will be
                 skipped even if they are included in the allwikis file
--privatewikis:  name of a file which contains all private wikis (these will be
                 skipped even if they are included in the allwikis file
--skipwikis:     name of a file which contains other wikis to be skipped
                 even if they are included in the allwikis file
--wmfhack:       use $site/$lang to put together the upload dir; works for WMF
                 wikis only and it is a hack so you have been warned. Note that
                 this produces a path relative to the root of the WMF upload
                 directory
"""
    sys.stderr.write(usagemessage)
    sys.exit(1)


def main():
    multiversion = False
    script_path = None
    wmfhack = False
    all_wikis_file = closed_wikis_file = private_wikis_file = skip_wikis_file = None

    try:
        (options, rem) = getopt.gnu_getopt(sys.argv[1:], "",
                                           ["allwikis=", "closedwikis=",
                                            "privatewikis=", "scriptpath=",
                                            "skipwikis=", "multiversion", "wmfhack"])
    except:
        usage("Unknown option specified\n")

    for (opt, val) in options:
        if opt == "--allwikis":
            all_wikis_file = val
        elif opt == "--closedwikis":
            closed_wikis_file = val
        elif opt == "--privatewikis":
            private_wikis_file = val
        elif opt == "--multiversion":
            multiversion = True
        elif opt == "--scriptpath":
            script_path = val
        elif opt == "--skipwikis":
            skip_wikis_file = val
        elif opt == "--wmfhack":
            wmfhack = True

    if len(rem) > 0:
        usage("Unknown option specified\n")

    if not all_wikis_file or not script_path:
        usage("One or more mandatory options is missing\n")

    wikilist = get_wikis(all_wikis_file, closed_wikis_file,
                         private_wikis_file, skip_wikis_file)

    upload = UploadDir(multiversion, script_path, wmfhack)

    for wiki in wikilist:
        result = upload.get_media_dir(wiki)
        if result:
            print "%s\t%s" % (wiki, result)

if __name__ == "__main__":
    main()
