#!/usr/bin/python3
# encoding: utf-8
'''
download Wikimedia Enterprise HTML dumps for all or for specified wiki projects
'''
import os
import getopt
import hashlib
import json
import logging
import sys
import time
import traceback
import requests
from requests.auth import HTTPBasicAuth


# pylint: disable=W0703


USERAGENT = "wm_enterprise_downloader.py/v0.1 (ops-dumps@wikimedia.org)"
# connect and read timeout
TIMEOUT = 20
# max number of seconds to spend on a single download, longer than that means something broken
# initially set this to something absurdly large until we have initial timings for the run
MAX_REQUEST_TIME = 60 * 90


LOG = logging.getLogger(__name__)


class Downloader():
    '''
    retrieve and stash dumps for one or more wikis
    if we fail for more than maxfail wikis in a row, stop; this means something more
    fundamentally broken and a human should intervene
    '''
    def __init__(self, creds, settings, maxfails=5, date=None):
        self.creds = creds
        self.settings = settings
        self.date = date
        if not date:
            self.date = time.strftime("%Y%m%d", time.gmtime())
        self.maxfails = maxfails
        dumpdir = os.path.join(settings['baseoutdir'], self.date)
        os.makedirs(dumpdir, exist_ok=True)
        tempdir = os.path.join(settings['tempoutdir'], self.date)
        os.makedirs(tempdir, exist_ok=True)

    def get_namespace_ids(self):
        '''
        via Wikimedia Enterprise api, get the ids of all of the supported namespaces for which
        dumps of wikis are created
        '''
        headers = {'user-agent': USERAGENT, "Accept": "application/json"}
        try:
            # even without the timeout, same thing. and I only get the first 565816 bytes,
            # not even a full 1mb so what's up with that.
            url_toget = self.settings['namespacesurl']
            LOG.debug("getting %s", url_toget)
            response = requests.get(url_toget,
                                    auth=HTTPBasicAuth(self.creds['user'], self.creds['passwd']),
                                    headers=headers, timeout=TIMEOUT)

            if response.status_code != 200:
                LOG.error("failed to get namespaces list with response code %s (%s)",
                          response.status_code, response.reason)
                return None
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            LOG.error(repr(traceback.format_exception(exc_type, exc_value, exc_traceback)))
            LOG.error("failed to get namespaces list")
            return None
        try:
            json_contents = json.loads(response.content)
        except Exception:
            LOG.error("failed to load json for wiki list, got: %s", response.content)
            return None
        # schema:
        # [
        #   {
        #     "name": "Article",
        #     "identifier": 0
        #   },
        #   ...
        # ]
        namespaces = [entry['identifier'] for entry in json_contents if'identifier' in entry]
        if not namespaces:
            LOG.error("empty list of namespaces retrieved got: %s", response.content)
        return namespaces

    def get_wiki_list(self, namespace_id):
        '''
        via Wikimedia Enterprise api, get the list of all projects in the given namespace for which
        dumps are created and return it, or None on error
        '''
        headers = {'user-agent': USERAGENT, "Accept": "application/json"}
        try:
            # even without the timeout, same thing. and I only get the first 565816 bytes,
            # not even a full 1mb so what's up with that.
            url_toget = self.settings['wikilisturl'] + str(namespace_id)
            LOG.debug("getting %s", url_toget)
            response = requests.get(url_toget,
                                    auth=HTTPBasicAuth(self.creds['user'], self.creds['passwd']),
                                    headers=headers, timeout=TIMEOUT)

            if response.status_code != 200:
                LOG.error("failed to get wiki list with response code %s (%s)\n",
                          response.status_code, response.reason)
                return None
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            LOG.error(repr(traceback.format_exception(exc_type, exc_value, exc_traceback)))
            return None
        try:
            json_contents = json.loads(response.content)
        except Exception:
            LOG.error("failed to load json for wiki list, got: %s", response.content)
            return None

        tempfile = self.get_tempfile_path(str(namespace_id))
        try:
            with open(tempfile, 'wb') as outf:
                outf.write(response.content)

            # schema:
            # [
            #   {
            #      "name": "Авикипедиа",
            #      "identifier": "abwiki",
            #      "url": "https://ab.wikipedia.org",
            #      "version": <md5hash>,
            #      "date_modified: <YYYY-MM-DDTHH:MM:SS.xxx>,
            #      "size": {
            #          "value": "9.xx",
            #          "unit_text": "MB",
            #      }
            #   },
            #   ...
            # ]

            wikilist = sorted([entry['identifier'] for entry in json_contents
                               if 'identifier' in entry])
            if not wikilist:
                LOG.error("empty list of wikis retrieved, got: %s", response.content)
                sys.exit(1)

            return wikilist
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            LOG.error(repr(traceback.format_exception(exc_type, exc_value, exc_traceback)))
            return None

    def get_dump_outfile_name(self, wiki, namespace_id):
        '''
        produce a filename with wiki and date in it someplace
        '''
        return "{wiki}-NS{ns}-{date}-ENTERPRISE-HTML.json.tar.gz".format(
            wiki=wiki, ns=namespace_id, date=self.date)

    def get_dump_outfile_path(self, wiki, namespace_id):
        '''
        given the (db) name of the wiki, return the path to the output file
        where the downloaded dump should be written
        '''
        path = os.path.join(self.settings['baseoutdir'], self.date,
                            self.get_dump_outfile_name(wiki, namespace_id))
        return path

    def get_projectlist_filename(self, namespace_id=None):
        '''
        given a namespace id, generate the name of the file where the list of all projects
        downloadable for this namespace gets written
        '''
        return "NS{ns}-{date}-ENTERPRISE-PROJECTLIST.json".format(ns=namespace_id, date=self.date)

    def get_tempfile_path(self, namespace_id=None):
        '''
        return the path to the file where the list of
        where the downloaded list of projects for the specified namespace should be written
        '''
        path = os.path.join(self.settings['tempoutdir'], self.date,
                            self.get_projectlist_filename(namespace_id))
        return path

    @staticmethod
    def get_tmp_outfile(path):
        '''
        canonical tmp file name for any generated file that must later be moved into place
        '''
        return path + ".tmp"

    def get_one_wiki_dump(self, wiki, namespace_id, dryrun):
        '''
        download the dump for one wiki, but if the file is already there, just return
        for dry runs, print the url that would be used to retrieve the wiki dump instead
        of getting it
        this method cleans up any temporary download that might have been left from a previous
        download attempt
        returns True on success or a dry run and False on error
        '''
        outfile = self.get_dump_outfile_path(wiki, namespace_id)
        if os.path.exists(outfile):
            return True

        outfile_tmp = self.get_tmp_outfile(outfile)
        try:
            os.unlink(outfile_tmp)
        except Exception:
            pass

        headers = {'user-agent': USERAGENT, "Accept": "application/json"}
        if dryrun:
            LOG.info("would download: %s", os.path.join(
                self.settings['basedumpurl'], str(namespace_id), wiki))
            return True
        try:
            with requests.get(os.path.join(self.settings['basedumpurl'], str(namespace_id), wiki),
                              auth=HTTPBasicAuth(self.creds['user'], self.creds['passwd']),
                              headers=headers, stream=True, timeout=TIMEOUT) as response:
                with open(outfile_tmp, 'wb') as outf:
                    start = time.time()
                    # Chunk size seems ok for speed in limited testing
                    for chunk in response.iter_content(chunk_size=1024*1024):
                        outf.write(chunk)
                        now = time.time()
                        if now - start > MAX_REQUEST_TIME:
                            # we're taking too long. network issues? whatever it is, just give up
                            LOG.error("download of wiki %s taking too long, giving up", wiki)
                            raise TimeoutError
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            LOG.error(repr(traceback.format_exception(exc_type, exc_value, exc_traceback)))
            try:
                # cleanup partial download if any
                os.unlink(outfile_tmp)
            except FileNotFoundError:
                pass
            return False
        return True

    def do_download_prep(self, wiki=None, namespace_id=None):
        '''
        retrieve namespaces and wikis if needed, or convert 'wiki' and 'namespace_id'
        args into lists, and return them
        '''
        wikis = {}
        namespace_ids = []
        if wiki:
            # we have to look up just one wiki from one namespace.
            # construct lists with these args so we can call the usual retrievers
            wikis[namespace_id] = [wiki]
            namespace_ids = [namespace_id]
        else:
            if namespace_id:
                namespace_ids = [namespace_id]
            else:
                namespace_ids = self.get_namespace_ids()
                LOG.debug("namespaces: %s", namespace_ids)
                if not namespace_ids:
                    LOG.error("error retrieving namespace_ids")
                    return namespace_ids, wikis

            for ns_id in namespace_ids:
                LOG.debug("getting wiki list for ns %s", ns_id)
                namespace_wikis = self.get_wiki_list(ns_id)
                if namespace_wikis:
                    LOG.debug("wiki list for namespace %s: %s", str(ns_id),
                              ",".join(namespace_wikis))
                    wikis[ns_id] = namespace_wikis

        if not wikis:
            LOG.error("error retrieving wikis list")

        return namespace_ids, wikis

    def get_dump_info(self, wiki, namespace_id, dryrun):
        '''
        for a given wiki and namespace id, return md5sum and last modified date for
        the current dump, or None, None if there is no information available, or there
        is an error
        '''
        if dryrun:
            return "dummymd5", "dummydate"
        md5sum = None
        last_modified = None
        headers = {'user-agent': USERAGENT, "Accept": "application/json"}
        try:
            response = requests.get(
                os.path.join(self.settings['dumpinfourl'], str(namespace_id), wiki),
                auth=HTTPBasicAuth(self.creds['user'], self.creds['passwd']),
                headers=headers, timeout=TIMEOUT)

            if response.status_code != 200:
                LOG.error("failed to get latest dump info for wiki "
                          " %s, namespace %s with response code %s (%s)",
                          wiki, namespace_id, response.status_code, response.reason)
                return md5sum, last_modified
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            LOG.error(repr(traceback.format_exception(exc_type, exc_value, exc_traceback)))
            LOG.error("Failed to retrieve dump file info "
                      "for wiki %s and namespace %s, got: %s",
                      wiki, namespace_id, response.content)
            return md5sum, last_modified

        try:
            json_contents = json.loads(response.content)
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            LOG.error(repr(traceback.format_exception(exc_type, exc_value, exc_traceback)))
            LOG.error("failed to load json for dump info for wiki %s, namespace %s, got: %s",
                      wiki, namespace_id, response.content)
            return md5sum, last_modified

        # schema:
        # {
        #    "name": "Wikipedia",
        #    "identifier": "enwiki",
        #    "url": "https://en.wikipedia.org",
        #    "version": "66bfde3bb9fb31b4eeee480b583b6c1e",
        #    "date_modified": "2021-10-13T07:51:31.352370106Z",
        #    "size": {
        #        "value": 91455.13,
        #        "unit_text": "MB"
        #    }
        # }
        if 'version' not in json_contents or 'date_modified' not in json_contents:
            LOG.error("version or date modified is missing from dump info "
                      "for wiki %s and namespace %s, got: %s",
                      wiki, namespace_id, response.content)
            return md5sum, last_modified
        md5sum = json_contents['version']
        last_modified = json_contents['date_modified']
        return md5sum, last_modified

    def get_dumpstats_path(self, wiki, namespace_id):
        '''
        return full path to file to which stats about the dump file for the given wiki are written
        '''
        return os.path.join(self.settings['baseoutdir'], self.date,
                            "{wiki}-NS{ns}-{date}-ENTERPRISE-STATS.json".format(
                                wiki=wiki, ns=namespace_id, date=self.date))

    def record_md5sum_last_modified(self, wiki_todo, namespace_id, md5sum_end, last_modified_end):
        '''
        record the md5sum and timestamp of the dump for the specified wiki in a file
        for later download along with the dump file itself
        '''
        outfile = self.get_dumpstats_path(wiki_todo, namespace_id)
        outfile_tmp = outfile + ".tmp"
        dumpstats = {"wiki": wiki_todo, "md5sum": md5sum_end, "date_modified": last_modified_end}
        try:
            json_contents = json.dumps(dumpstats)
            with open(outfile_tmp, 'wb') as outf:
                outf.write(json_contents.encode('utf-8'))
            os.rename(outfile_tmp, outfile)
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            LOG.error(repr(traceback.format_exception(exc_type, exc_value, exc_traceback)))
            return

    def dump_info_exists(self, wiki_todo, ns_id_todo):
        '''
        return True if a dump info file exists for the specified namespace
        id and wiki for this run, False otherwise
        '''
        if os.path.exists(self.get_dumpstats_path(wiki_todo, ns_id_todo)):
            return True
        return False

    def wiki_dump_exists(self, wiki_todo, ns_id_todo):
        '''
        return True if a wiki dump file exists for the specified namespace
        id and wiki for this run, False otherwise
        '''
        if os.path.exists(self.get_dump_outfile_path(wiki_todo, ns_id_todo)):
            return True
        return False

    @staticmethod
    def compute_md5sum(path):
        '''
        compute the md5 sum of the dump file for the given wiki and namespace in
        the specified directory
        returns None on error
        '''
        summer = hashlib.md5()
        try:
            with open(path, "rb") as infile:
                bufsize = 4192 * 32
                buff = infile.read(bufsize)
                while buff:
                    summer.update(buff)
                    buff = infile.read(bufsize)
                infile.close()
            return summer.hexdigest()
        except Exception:
            LOG.error("failed to compute md5sum of %s", path)
            return None

    def dump_done(self, wiki_todo, ns_id_todo):
        '''
        see if the dump info file and dump content file are already
        downloaded for this date
        return True if so, False otherwise
        '''
        if (self.dump_info_exists(wiki_todo, ns_id_todo)
                and self.wiki_dump_exists(wiki_todo, ns_id_todo)):
            LOG.debug("dump info and content files exist for %s (NS %s) for this run, skipping.",
                      wiki_todo, ns_id_todo)
            return True
        return False

    def get_wiki_dump_and_info(self, wiki_todo, ns_id_todo, dryrun):
        '''
        retrieve dump file for a wiki and namespace, along with its md5sum,
        downloading again in the case where the md5sum of the dump or the date
        it was produced doesn't match or may have been changed in the meantime

        if the info file and the dump output file already exist, simply return True

        returns True on success, False on error
        '''
        # get the info for this dump before starting (date last modified, md5 hash)
        md5sum_claimed, last_modified = self.get_dump_info(wiki_todo, ns_id_todo, dryrun)
        if not md5sum_claimed or not last_modified:
            return False
        LOG.debug("Wiki %s, namespace %s, md5sum:%s, modified:%s",
                  wiki_todo, ns_id_todo, md5sum_claimed, last_modified)

        # get the dump content file
        if not self.get_one_wiki_dump(wiki_todo, ns_id_todo, dryrun):
            LOG.debug("error from dump retrieval for %s", wiki_todo)
            return False

        if dryrun:
            # no check of md5sum in dryrun because we didn't actually download anything
            return True

        # check the md5sum of what we just downloaded against what the dump info claims
        outfile = self.get_dump_outfile_path(wiki_todo, ns_id_todo)
        outfile_tmp = self.get_tmp_outfile(outfile)
        md5sum_computed = self.compute_md5sum(outfile_tmp)

        if md5sum_claimed != md5sum_computed:
            # Houston, we have a problem. Try downloading one more time
            if not self.get_one_wiki_dump(wiki_todo, ns_id_todo, dryrun):
                LOG.debug("error from second dump retrieval for %s for namespace %s",
                          wiki_todo, ns_id_todo)
                return False

            md5sum_computed = self.compute_md5sum(outfile_tmp)
            if md5sum_claimed != md5sum_computed:
                # get a new info file and see if that's any better, maybe the new download
                # is a newly produced dump
                md5sum_claimed, last_modified = self.get_dump_info(wiki_todo, ns_id_todo, dryrun)
                if md5sum_claimed != md5sum_computed:
                    try:
                        os.unlink(outfile_tmp)
                    except Exception:
                        pass
                    return False

        # success! move the file into place and call it a day
        try:
            os.rename(outfile_tmp, outfile)
        except Exception:
            LOG.error("Failed to rename %s to %s", outfile_tmp, outfile)
            return False

        self.record_md5sum_last_modified(wiki_todo, ns_id_todo, md5sum_computed, last_modified)

        return True

    def get_wiki_dumps(self, wiki=None, namespace_id=None, test_index=None, dryrun=False):
        '''
        download html dumps for all specified wikis and the given namespace id
        return False on error, True otherwise
        '''
        namespace_ids, wikis = self.do_download_prep(wiki, namespace_id)
        if not namespace_ids or not wikis:
            return False

        first = True
        start = 0
        end = -1

        if test_index:
            fields = test_index.split(',')
            start = int(fields[0])
            end = int(fields[1])

        consecutive_fails = 0
        for ns_id_todo in namespace_ids:
            # for testing purposes, we allow the caller to select a slice of the list to dump;
            # if that slice is empty, nothing is dumped from this namespace
            if test_index:
                wikis[ns_id_todo] = wikis[ns_id_todo][start:end]

            for wiki_todo in wikis[ns_id_todo]:
                if not dryrun:
                    LOG.debug("retrieving dump for %s", wiki_todo)
                if first:
                    first = False
                else:
                    if not dryrun:
                        time.sleep(self.settings['wait'])

                if self.dump_done(wiki_todo, ns_id_todo):
                    continue

                if not self.get_wiki_dump_and_info(wiki_todo, ns_id_todo, dryrun):
                    consecutive_fails += 1
                    if consecutive_fails > self.maxfails:
                        LOG.error("max consecutive failures reached, bailing...")
                        return False

                consecutive_fails = 0
        return True


def usage(message=None):
    '''display usage info about this script'''
    if message is not None:
        print(message)
    usage_message = """Usage: wm_enterprise_downloader.py [--wiki name]
         [--creds path-to-creds-file] [--settings path-to-settings-file]
         [--retries num] [--test num,num] [--maxfails num] [--dryrun] [--verbose]| --help

Arguments:

  --wiki      (-w):  name of the wiki db to download
                     default: None (download all)
  --namespace (-n):  numeric id of the namespace of the wiki to download, if --wiki is
                     specified
  --creds     (-c):  path to plain text file with HTTP Basic Auth credentials
                     format: two lines, varname=value, with the varnames user and passwd
                             blank lines and those starting with '#' are skipped
                     default: .wm_enterprise_creds in current working directory
  --settings  (-s):  path to settings file
                     format: two lines, varname=value; see the sample file in this repo
                             for each setting and its default value
                             blank lines and those starting with '#' are skipped
                     default: wm_enterprise_downloader_settings in current working directory
  --retries   (-r):  number of retries in case downloads fail
                     default: 0 (don't retry)
  --maxfails  (-m):  the maximum number of consecutive wikis for which the dump download may
                     fail before the script exits
  --test      (-t):  a start and end index, comma-separated; only the wiki dump files corresponding
                     to this sublist of the alphabetically sorted list of wikis for each namespace
                     will be dumped, and if the start is larger than the length of the list for
                     some namespace, no dump files for wikis in that namespace will be retrieved.
  --dryrun    (-d):  don't download any wiki dumps but print the list of urls for retrieval
  --verbose   (-v):  show some progress messages while running
  --help      (-h):  display this usage message

Example usage:

   python ./wm_enterprise_downloader.py --wiki elwiki --namespace 0 --verbose
   python ./wm_enterprise_downloader.py --verbose
   python ./wm_enterprise_downloader.py --namespace 0 --test 5,10 --dryrun

"""
    print(usage_message)
    sys.exit(1)


def check_test_args(args):
    '''
    if the --test arg is specified, check its format; it should consist of
    <number>,<number>
    '''
    if args['test']:
        valid = False
        if ',' in args['test']:
            fields = args['test'].split(',')
            if len(fields) == 2:
                if fields[0].isdigit() and fields[1].isdigit():
                    valid = True

        if not valid:
            usage("The 'test' option requires a start and end wiki list index separated by a comma")


def fillin_flags(opt, args):
    '''
    if the specified opt is a flag, set the corresponding arg
    '''
    if opt in ["-d", "--dryrun"]:
        args['dryrun'] = True
    elif opt in ["-v", "--verbose"]:
        args['verbose'] = True
    elif opt in ["-h", "--help"]:
        usage('Help for this script')
    else:
        usage("Unknown option specified: <%s>" % opt)


def fillin_args(options, args):
    '''
    walk through all the provided options and stuff the appropriate values in the args
    '''
    for (opt, val) in options:
        if opt in ["-c", "--creds"]:
            args['creds'] = val
        if opt in ["-n", "--namespace"]:
            args['ns_id'] = val
        elif opt in ["-w", "--wiki"]:
            args['wiki'] = val
        elif opt in ["-s", "--settings"]:
            args['settings'] = val
        elif opt in ["-r", "--retries"]:
            if not val.isdigit():
                usage('Retries value must be a number')
            args['retries'] = int(val)
        elif opt in ["-m", "--maxfails"]:
            if not val.isdigit():
                usage('Maxfails value must be a number')
            args['maxfails'] = int(val)
        elif opt in ["-t", "--test"]:
            args['test'] = val
        else:
            fillin_flags(opt, args)

    check_test_args(args)


def get_args():
    '''
    get and validate command-line args and return them
    '''
    try:
        (options, remainder) = getopt.gnu_getopt(
            sys.argv[1:], "c:m:n:r:s:t:w:dvh", [
                "creds=", "namespace=", "settings=", "retries=", "maxfails=", "wiki=", "test=",
                "dryrun", "verbose", "help"])

    except getopt.GetoptError as err:
        usage("Unknown option specified: " + str(err))

    args = {'namespace:': None, 'retries': 0, 'maxfails': 5, 'ns_id': None,
            'wiki': None, 'test': None, 'dryrun': False, 'verbose': False}
    args['settings'] = os.path.join(os.getcwd(), 'wm_enterprise_downloader_settings')
    args['creds'] = os.path.join(os.getcwd(), '.wm_enterprise_creds')

    fillin_args(options, args)

    if remainder:
        usage("Unknown option(s) specified: {opt}".format(opt=remainder[0]))

    if args['wiki'] and not args['ns_id']:
        usage("You must specify a numeric namespace id if you specify a wiki")

    return args


def read_creds(filepath):
    '''
    read path and return values for user, passwd
    '''
    user = None
    passwd = None
    if not os.path.exists(filepath):
        usage("Failed to find credentials file: " + filepath)
    try:
        with open(filepath) as infile:
            contents = infile.read()
        entries = contents.splitlines()
    except Exception:
        exc_type, exc_value, exc_traceback = sys.exc_info()
        LOG.error(repr(traceback.format_exception(exc_type, exc_value, exc_traceback)))
        usage("Problem with credentials file " + filepath)

    for entry in entries:
        if entry.startswith('#'):
            continue
        entry = entry.strip()
        if not entry:
            continue
        if '=' not in entry:
            usage("Bad format for credentials in " + filepath)
        name, value = entry.split('=', 1)
        if name == 'user':
            user = value
        elif name == 'passwd':
            passwd = value
        else:
            usage("Unknown entry in credentials file " + filepath)

    if not user or not passwd:
        usage("Both 'user' and 'passwd' must be specified in credentials file")

    return user, passwd


def read_settings(filepath):
    '''
    read path and return values for various settings, falling back to defaults
    if they are not in the file
    '''
    settings = {
        'namespacesurl': "https://api.enterprise.wikimedia.com/v1/namespaces",
        'wikilisturl': "https://api.enterprise.wikimedia.com/v1/exports/meta",
        'basedumpurl': "https://api.enterprise.wikimedia.com/v1/exports/download",
        'dumpinfourl': "https://api.enterprise.wikimedia.com/v1/exports/meta",
        'baseoutdir':  "/home/ariel/wmf/okapi/downloader/test",
        'tempoutdir': "/home/ariel/wmf/okapi/downloader/temp",
        'wait': 20,
        'retrywait': 10,
        }
    int_settings = ['wait', 'retrywait']
    try:
        with open(filepath) as infile:
            contents = infile.read()
        entries = contents.splitlines()
    except Exception:
        exc_type, exc_value, exc_traceback = sys.exc_info()
        LOG.error(repr(traceback.format_exception(exc_type, exc_value, exc_traceback)))
        usage("Problems with settings file " + filepath)

    for entry in entries:
        if entry.startswith('#'):
            continue
        entry = entry.strip()
        if not entry:
            continue
        if '=' not in entry:
            usage("Bad format for setting " + entry + " in " + filepath)
        name, value = entry.split('=', 1)
        if name not in settings.keys():
            usage("Unknown entry " + entry + " in settings file " + filepath)
        if name in int_settings:
            settings[name] = int(value)
        else:
            settings[name] = value
    return settings


def setup_logging(args):
    '''
    set up appropriate logging depending on verbose and dryrun flags
    '''
    log_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    log_formatter.converter = time.gmtime
    log_handler = logging.StreamHandler()
    log_handler.setFormatter(log_formatter)
    LOG.addHandler(log_handler)
    if args['verbose']:
        LOG.setLevel(logging.DEBUG)
    elif args['dryrun']:
        LOG.setLevel(logging.INFO)


def get_creds(args):
    '''
    get and return user credentials for access to the WM Enterprise API
    '''
    credspath = args['creds']
    if not os.path.exists(credspath):
        usage('Failed to find specified credentials file ' + credspath)
    user, passwd = read_creds(credspath)
    if not user or not passwd:
        usage("username and password file must be set up with both user and password")
    LOG.debug("Credentials retrieved")
    creds = {'user': user, 'passwd': passwd}
    return creds


def get_settings(args):
    '''
    get and return settings from the file specified in the args
    '''
    settingspath = args['settings']
    if not os.path.exists(settingspath):
        usage('Failed to find specified settings file ' + settingspath)
    settings = read_settings(settingspath)
    return settings


def do_main():
    '''entry point'''
    args = get_args()
    setup_logging(args)
    creds = get_creds(args)
    settings = get_settings(args)

    downloader = Downloader(creds, settings, args['maxfails'])

    retries = 0
    while retries <= args['retries']:
        if args['wiki'] is not None:
            errors = downloader.get_wiki_dumps(args['wiki'], args['ns_id'], test_index=args['test'],
                                               dryrun=args['dryrun'])
        elif args['ns_id'] is not None:
            errors = downloader.get_wiki_dumps(None, args['ns_id'], test_index=args['test'],
                                               dryrun=args['dryrun'])
        else:
            errors = downloader.get_wiki_dumps(test_index=args['test'],
                                               dryrun=args['dryrun'])
        if not errors:
            break
        retries += 1
        if retries < args['retries']:
            LOG.debug("sleeping for %s minutes before retry of failed wikis",
                      settings['retrywait'])
            time.sleep(settings['retrywait'] * 60)


if __name__ == '__main__':
    do_main()
