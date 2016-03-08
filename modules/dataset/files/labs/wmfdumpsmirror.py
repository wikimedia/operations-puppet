import getopt
import os
import re
import sys
import tempfile
import multiprocessing
from subprocess import Popen, PIPE
from Queue import Empty


# note that this was written back in the day when this was used
# to rsync to glusterfs, painfully slow, so we ran multiple jobs
# to get it to finish before the end of the universe. job handling
# isn't needed any more but what the heck might as well leave it in

# things that get here should look like:
# aawikibooks/20120317/aawikibooks-20120317-all-titles-in-ns0.gz
def get_path_elts_from_filename(path):
    if os.sep not in path:
        raise MirrorError("bad line encountered in rsync"
                          "directory list: '%s'" % path)

    components = path.split(os.sep)
    if len(components) < 3 or not RsyncJob.date_pattern.search(components[-2]):
        raise MirrorError("what garbage is this:"
                          "%s in the filenames for rsync? " % path)
    return components


def get_file_size(line):
    return int(line.split()[1])


def get_path(line):
    return line.split()[4]


def check_line_wanted(line):
    """is this a line we want, it has information about a
    file for our jobs? if so return true, if not return
    false.  we assume lines starting with '#' are comments,
    blank lines are to be skipped, and we don't want
    directory entries, only files and/or symlinks"""
    if not line or line[0] == 'd' or line[0] == '#':
        return False
    else:
        return True


def maketempdir():
    return tempfile.mkdtemp()


class Job(object):
    def __init__(self, job_id, job_contents):
        self.job_id = job_id  # this must be unique across all jobs
        self.contents = job_contents
        self.done = False
        self.failed = False

    def mark_done(self):
        self.done = True

    def mark_failed(self):
        self.failed = True

    def check_if_done(self):
        return self.done

    def check_if_failed(self):
        return self.failed


class RsyncJob(Job):
    date_pattern = re.compile('^20[0-9]{6}$')

    def __init__(self, contents):
        super(RsyncJob, self).__init__(contents[0], contents)
        self.rsynced_by_job = self.get_dirs_per_proj_rsynced_by_job()

    def get_dirs_per_proj_rsynced_by_job(self):
        """return has of projects which are partially or completely
        rsynced by this job, each has key having as value the dirs that
        are rsynced"""

        projects = {}
        for line in self.contents:
            if os.sep not in line:
                # files that aren't part of the project dumps but
                # are included in the rsync... for example various
                # html files that might be at the top of the tree;
                # don't dig through their names looking for project dump info
                continue
            components = get_path_elts_from_filename(line)
            if len(components):
                project = os.sep + components[-3]
                project_subdir = components[-2]
                project_file = components[-1]
                if project not in projects.keys():
                    projects[project] = {}
                if project_subdir not in projects[project]:
                    projects[project][project_subdir] = []
                projects[project][project_subdir].append(project_file)

        return projects


class RsyncFilesProcessor(object):
    # for now we have the file list be a flat file, sometime in the
    # not to distant future it will be maybe a stream cause we'll be
    # feeding a list from the api, that will be sketchy
    def __init__(self, file_list_fd, max_files_per_job, max_du_per_job,
                 worker_count, rsync_source_root, rsync_dest_root,
                 rsync_args, verbose, dryrun):
        self.file_list_fd = file_list_fd
        self.max_files_per_job = max_files_per_job
        self.max_du_per_job = max_du_per_job
        self.verbose = verbose
        self.dryrun = dryrun
        self.rsync_args = rsync_args
        self.rsyncer = Rsyncer(rsync_source_root, rsync_dest_root,
                               self.rsync_args, self.verbose, self.dryrun)
        self.jqueue = JobQueue(worker_count, self.rsyncer, self.verbose, self.dryrun)
        self.date_pattern = re.compile('^20[0-9]{6}$')
        self.jobs_per_project = {}
        self.jobs = {}
        self.deleter = DirDeleter(self.jobs_per_project, rsync_dest_root,
                                  self.verbose, self.dryrun)

    def stuff_jobs_on_queue(self):
        file_count = 0
        file_du = 0
        files = []
        line = self.file_list_fd.readline().rstrip()
        while line:
            if not check_line_wanted(line):
                line = self.file_list_fd.readline().rstrip()
                continue
            path = get_path(line)
            if path:
                file_count = file_count + 1
                file_du = file_du + get_file_size(line)
                files.append(path)
                if file_du >= self.max_du_per_job or file_count >= self.max_files_per_job:
                    job = self.make_job(files)
                    if self.dryrun or self.verbose:
                        MirrorMsg.display(
                            "adding job %s (size %d and filecount %d) to queue\n"
                            % (job.job_id, file_du, file_count))
                    self.jqueue.add_to_job_queue(job)
                    file_du = 0
                    file_count = 0
                    files = []
            line = self.file_list_fd.readline().rstrip()

        if file_count:
            if self.dryrun or self.verbose:
                MirrorMsg.display(
                    "adding job %s (size %d and filecount %d) to queue\n"
                    % (job.job_id, file_du, file_count))
            self.jqueue.add_to_job_queue(self.make_job(files))

        self.jqueue.set_end_of_jobs()
        self.deleter.set_job_list(self.jobs)

    def make_job(self, files):
        job = RsyncJob(files)
        for project in job.rsynced_by_job.keys():
            if project not in self.jobs_per_project.keys():
                self.jobs_per_project[project] = []
            self.jobs_per_project[project].append(job.job_id)
        self.jobs[job.job_id] = job
        return job

    def do_postjob_processing(self, skip_deletes):
        while True:
            # any completed jobs?
            job = self.jqueue.get_job_from_notify_queue()
            # no more jobs and mo more workers.
            if job is None:
                if not self.jqueue.get_active_worker_count():
                    if self.dryrun or self.verbose:
                        MirrorMsg.display("no jobs left and no active workers\n")
                    break
                else:
                    continue
            if self.dryrun:
                MirrorMsg.display("job_id %s would have been completed\n" % job.job_id)
            elif self.verbose:
                MirrorMsg.display("job_id %s completed\n" % job.job_id)

            # update status of job in our todo queue
            j = self.jobs[job.job_id]
            if job.check_if_done():
                j.mark_done()
            if job.check_if_failed():
                j.mark_failed()

            if not skip_deletes:
                if self.verbose or self.dryrun:
                    MirrorMsg.display("checking post-job deletions\n")
                self.deleter.check_and_do_deletes(j)


class DirDeleter(object):
    """remove all dirs for the project that are not in the
    list of dirs to rsync, we don't want them any more"""
    def __init__(self, jobs_per_project, dest_path, verbose, dryrun):
        self.jobs_per_project = jobs_per_project
        self.dest_path = dest_path
        self.verbose = verbose
        self.dryrun = dryrun
        self.job_list = None
        self.emptydirpath = None
        self.cmd = Command(verbose, dryrun)

    def cleanup(self):
        if self.emptydirpath is not None:
            try:
                os.rmdir(self.emptydirpath)
            except:
                pass

    def set_job_list(self, job_list):
        self.job_list = job_list

    def check_and_do_deletes(self, job):
        """given a file list, we need to see if we are done with
        one project and on to the next, which things we rsynced and
        which not, and delete the ones not (i.e. left over from previous
        run and we don't want them now); failed rsyncs may not have
        completed normally so we won't do deletions for a project
        with failed jobs"""
        for project in job.rsynced_by_job.keys():
            ids = [self.job_list[job_id] for job_id in self.jobs_per_project[project]
                   if not self.job_list[job_id].check_if_done() or
                   self.job_list[job_id].check_if_failed()]
            if not len(ids):
                if self.dryrun:
                    MirrorMsg.display("Would do deletes for project %s\n" % project)
                elif self.verbose:
                    MirrorMsg.display("Doing deletes for project %s\n" % project)
                self.do_deletes(project)
            else:
                if self.verbose:
                    MirrorMsg.display("No deletes for project %s\n" % project)

    def list_dirs_rsynced_for_proj(self, project):
        """get directories we synced for this project,
        across all jobs"""
        dirs_for_project = []
        for job_id in self.jobs_per_project[project]:
            dirs_for_project.extend(
                [k for k in self.job_list[job_id].rsynced_by_job[project].keys()
                 if k not in dirs_for_project])
        return dirs_for_project

    def list_files_rsynced_for_proj_dir(self, project, dir_name):
        """get files we synced for a specific dir for
        this project, across all jobs"""
        files_for_dir_in_project = []
        for job_id in self.jobs_per_project[project]:
            if dir_name in self.job_list[job_id].rsynced_by_job[project].keys():
                files_for_dir_in_project.extend(
                    self.job_list[job_id].rsynced_by_job[project][dir_name])
        return files_for_dir_in_project

    def do_deletes(self, project):
        # find which dirs were rsynced for this project,
        # on the remote, remove the ones we didn't rsync, as we no longer want them
        project_dirs_rsynced = self.list_dirs_rsynced_for_proj(project)
        # rsync -a --delete --exclude=/20151026/ --exclude=/20151027/ empty/ public/tenwiki/

        if self.emptydirpath is None:
            self.emptydirpath = maketempdir()
            os.chmod(self.emptydirpath, 0755)
        excludes = ["--exclude=/{0}/".format(dirname) for dirname in project_dirs_rsynced]
        command = ["/usr/bin/rsync", "-a", "--delete"]
        command.extend(excludes)
        project = project.strip(os.path.sep)
        command.extend([self.emptydirpath + "/", os.path.join(self.dest_path, project) + "/"])
        if self.dryrun or self.verbose:
            command_string = " ".join(command)
        if self.dryrun:
            MirrorMsg.display("would run %s\n" % command_string)
        elif self.verbose:
            MirrorMsg.display("running %s\n" % command_string)
        return self.cmd.run_command(command, shell=False)


class JobHandler(object):
    def init(self):
        """this should be overriden to set and args
        that you need to actually process a job"""
        pass

    def do_job(self, contents):
        """override this with a function that processes
        contents as desired"""
        print contents
        return False


class Rsyncer(JobHandler):
    """all the info about rsync you ever wanted to
       know but were afraid to ask..."""
    def __init__(self, rsync_source_root, rsync_dest_root,
                 rsync_args, verbose, dryrun):
        self.rsync_source_root = rsync_source_root
        self.rsync_dest_root = rsync_dest_root
        self.rsync_args = rsync_args
        self.verbose = verbose
        self.dryrun = dryrun
        self.cmd = Command(verbose, dryrun)

    def do_job(self, contents):
        return self.do_rsync(contents)

    def do_rsync(self, files):
        command = ["/usr/bin/rsync"]
        command.extend(["--files-from", "-"])
        command.extend(self.rsync_args)
        command.extend([self.rsync_source_root, self.rsync_dest_root])

        if self.dryrun or self.verbose:
            command_string = " ".join(command)
        if self.dryrun:
            MirrorMsg.display("would run %s" % command_string)
        elif self.verbose:
            MirrorMsg.display("running %s" % command_string)
        if self.dryrun or self.verbose:
            MirrorMsg.display("with input:\n" + '\n'.join(files) + '\n', True)
        return self.cmd.run_command(command, shell=False,
                                    input_text='\n'.join(files) + '\n')


class JobQueueHandler(multiprocessing.Process):
    def __init__(self, jqueue, handler, verbose, dryrun):
        multiprocessing.Process.__init__(self)
        self.jqueue = jqueue
        self.handler = handler
        self.verbose = verbose
        self.dryrun = dryrun

    def run(self):
        while True:
            job = self.jqueue.get_job_on_queue()
            if not job:  # no jobs left, we're done
                break
            self.do_job(job)

    def do_job(self, job):
        result = self.handler.do_job(job.contents)
        if result:
            job.mark_failed()
        else:
            job.mark_done()
        self.jqueue.notify_job_done(job)


class JobQueue(object):
    def __init__(self, initial_worker_count, handler, verbose, dryrun):
        """create queue for jobs, plus specified
        number of workers to read from the queue"""
        self.handler = handler
        self.verbose = verbose
        self.dryrun = dryrun
        # queue of jobs to be done (all the info needed, plus job id)
        self.todo_queue = multiprocessing.Queue()

        # queue to which workers write job ids of completed jobs
        self.notify_queue = multiprocessing.Queue()

        # this 'job' on the queue means there are no more
        # jobs. we put on of these on queue for each worker
        self.end_of_jobs = None

        self._initial_worker_count = initial_worker_count
        self._active_workers = []
        if not self._initial_worker_count:
            self._initial_worker_count = 1
        if self.verbose or self.dryrun:
            MirrorMsg.display("about to start up %d workers:"
                              % self._initial_worker_count)
        for i in xrange(0, self._initial_worker_count):
            worker = JobQueueHandler(self, self.handler, self.verbose, self.dryrun)
            worker.start()
            self._active_workers.append(worker)
            if self.verbose or self.dryrun:
                MirrorMsg.display('.', True)
        if self.verbose or self.dryrun:
            MirrorMsg.display("done\n", True)

    def get_job_on_queue(self):
        # after 5 minutes of waiting around we decide that
        # no one is ever going to put stuff on the queue
        # again.  either the main process is done filling
        # the queue or it died or hung

        try:
            job = self.todo_queue.get(timeout=60)
        except Empty:
            if self.verbose or self.dryrun:
                MirrorMsg.display("job todo queue was empty\n")
            return False

        if job == self.end_of_jobs:
            if self.verbose or self.dryrun:
                MirrorMsg.display("found jobs done marker on jobs queue\n")
            return False
        else:
            if self.verbose or self.dryrun:
                MirrorMsg.display("retrieved from the job queue: %s\n" % job.job_id)
            return job

    def notify_job_done(self, job):
        self.notify_queue.put_nowait(job)

    def add_to_job_queue(self, job=None):
        if job:
            self.todo_queue.put_nowait(job)

    def set_end_of_jobs(self):
        """stuff 'None' on the queue, so that when
        a worker reads this, it will clean up and exit"""
        for i in xrange(0, self._initial_worker_count):
            self.todo_queue.put_nowait(self.end_of_jobs)

    def get_job_from_notify_queue(self):
        """see if any job has been put on
        the notify queue (meaning that it has
        been completed)"""
        job_done = None
        # wait up to one minute.  after that we're pretty sure
        # that if there are no active workers there are no more
        # jobs that are going to get done either.
        try:
            job_done = self.notify_queue.get(timeout=60)
        except Empty:
            if not self.get_active_worker_count():
                return None
        return job_done

    def get_active_worker_count(self):
        self._active_workers = [w for w in self._active_workers if w.is_alive()]
        return len(self._active_workers)


class Command(object):
    def __init__(self, verbose, dryrun):
        self.dryrun = dryrun
        self.verbose = verbose

    def run_command(self, command, shell=False, input_text=False):
        """Run a command, expecting no output. Raises MirrorError on
        non-zero return code."""

        if type(command).__name__ == "list":
            command_string = " ".join(command)
        else:
            command_string = command
        if self.dryrun or self.verbose:
            if self.dryrun:
                MirrorMsg.display("would run %s\n" % command_string)
                return
            if self.verbose:
                MirrorMsg.display("about to run %s\n" % command_string)

        if input_text:
            proc = Popen(command, shell=shell, stderr=PIPE, stdin=PIPE)
        else:
            proc = Popen(command, shell=shell, stderr=PIPE)

        output, error = proc.communicate(input_text)
        if output:
            print output

        if proc.returncode:
            MirrorMsg.warn("command '%s failed with return code %s and error %s\n"
                           % (command_string, proc.returncode, error))

        # let the caller decide whether to bail or not
        return proc.returncode


class MirrorError(Exception):
    pass


class MirrorMsg(object):
    def warn(message):
        # maybe this should go to stderr. eh for now...
        print "Warning:", os.getpid(), message
        sys.stdout.flush()

    def display(message, continuation=False):
        # caller must add newlines to messages as desired
        if continuation:
            print message,
        else:
            print "Info: (%d) %s" % (os.getpid(), message),
        sys.stdout.flush()

    warn = staticmethod(warn)
    display = staticmethod(display)


class Mirror(object):
    """reading directories for rsync from a specified file,
    rsync each one; remove directories destly that aren't in the file"""

    def __init__(self, source_host_name, dest_host_name, source_dir_name, dest_dir_name,
                 rsync_list, rsync_args, max_files_per_job,
                 max_du_per_job, worker_count, skip_deletes, verbose, dryrun):
        if source_host_name is not None:
            self.host_name = source_host_name
            self.remote = 'source'
        elif dest_host_name is not None:
            self.remote = 'dest'
            self.host_name = dest_host_name
        else:
            self.remote = None
            self.host_name = None

        if self.host_name is not None and self.remote == "dest":
            self.rsync_dest_root = self.host_name + "::" + dest_dir_name
        else:
            self.rsync_dest_root = dest_dir_name

        if self.host_name is not None and self.remote == "source":
            self.rsync_source_root = self.host_name + "::" + source_dir_name
        else:
            self.rsync_source_root = source_dir_name

        self.rsync_file_list = rsync_list
        self.rsync_args = rsync_args
        self.verbose = verbose
        self.dryrun = dryrun
        self.max_files_per_job = max_files_per_job
        self.max_du_per_job = max_du_per_job
        self.worker_count = worker_count
        self.skip_deletes = skip_deletes
        self.files_processor = None
        self.tempdirname = None

    def cleanup(self):
        if self.tempdirname is not None:
            try:
                os.remove(os.path.join(self.tempdirname, self.rsync_file_list))
                os.rmdir(self.tempdirname)
            except:
                pass
        if self.files_processor is not None:
            self.files_processor.deleter.cleanup()

    def get_rsync_file_listing(self):
        """via rsync, get full list of files for rsync from source host"""
        if self.tempdirname is None:
            self.tempdirname = maketempdir()
        command = ["/usr/bin/rsync", "-tp",
                   self.rsync_source_root + '/' + self.rsync_file_list,
                   self.tempdirname]
        # here we don't do a dry run, we will actually retrieve
        # the list (because otherwise the rest of the run
        # won't produce any information about what the run
        # would do).  we will turn on verbosity though if
        # dryrun was set
        cmd = Command(self.verbose or self.dryrun, False)
        result = cmd.run_command(command, shell=False)
        if result:
            raise MirrorError("_failed to get list of files for rsync\n")
        fdesc = open(os.path.join(self.tempdirname, self.rsync_file_list))
        if not fdesc:
            raise MirrorError("failed to open retrieved list of files for rsync")
        return fdesc

    def process_rsync_file_list(self, fdesc):
        self.files_processor = RsyncFilesProcessor(
            fdesc, self.max_files_per_job, self.max_du_per_job,
            self.worker_count, self.rsync_source_root, self.rsync_dest_root,
            self.rsync_args, self.verbose, self.dryrun)
        # create all jobs and put on todo queue
        self.files_processor.stuff_jobs_on_queue()
        fdesc.close()

        # watch jobs get done and do post job cleanup after each one
        if self.verbose or self.dryrun:
            MirrorMsg.display("waiting for workers to process jobs\n")
        self.files_processor.do_postjob_processing(self.skip_deletes)

    def setup_dir(self, dir_name):
        if self.dryrun:
            return

        if os.path.exists(dir_name):
            if not os.path.isdir(dir_name):
                raise MirrorError(
                    "target directory name %s is not a directory, giving up"
                    % dir_name)
        else:
            os.makedirs(dir_name)


def usage(message=None):
    if message:
        sys.stderr.write("%s\n" % message)
    usage_message = """
Usage: python wmfdumpsmirror.py [--source_hostname dumpserver]
              [--dest_hostname]  -sourcedir dirpath
              --destdir dirpath [--rsyncargs args] [--rsynclist filename]
              [--filesperjob] [--sizeperjob] [--workercount] [--dryrun]
              [--skipdeletes] [--verbose]

This script does a continuous rsync from specified XML dumps rsync server,
rsyncing the last N good dumps of each project and cleaning up old files.
The rsync is done on a list of files, not directories; bear this in mind
when using the --rsyncargs option below.  The list of files should have
been produced by rsync --list-only or be in the same format.

--source_hostname: the name of the source dump rsync server if it is not the
                   local host
--dest_hostname:   the name of the destination dump rsync server if it is not
                   the local host
--sourcedir:       the source path to the top of the dump directory tree
                   containing the mirror
--destdir:         the full path to the top of the dest directory tree
                   containing the mirror
--rsyncargs:       arguments to be passed through to rsync, comma-separated,
                   with 'arg=value' for arguments that require a value
                   example:  --rsyncargs -tp,--bandwidth=10000
                   default: '-aq'
--rsynclist:       the name of the list of dumps for rsync
                   default: rsync-list.txt.rsync
 --filesperjob:    the maximum number of files to pass to a worker to process
                   at once
                   default: 1000
 --sizeperjob:     the maximum size of a batch of files to pass to a worker
                   to process at once (may be specified in K/M/G i.e.
                   kilobytes/megabytes/gigabytes; default is K) to a worker
                   to process at once
                   default: 500M
 --workercount:    the number of worker processes to do simultaneous rsyncs
                   default: 1
 --dryrun:         don't do the rsync of files, just get the rsync file list
                   and print out what would be done
 --skipdeletes: copy or update files but don't delete anything
 --verbose:     print lots of diagnostic output

Example: python wmfdumpsmirror.py --hostname dumps.wikimedia.org
                --destdir /opt/data/dumps --rsyncfile rsync-list.txt.rsync
"""
    sys.stderr.write(usage_message)
    sys.exit(1)


def get_size_in_bytes(value):
    # expect digits optionally followed by one of
    # K M G; if not, then we assume K
    size_pattern = re.compile('^([0-9]+)([K|M|G])?$')
    result = size_pattern.search(value)
    if not result:
        usage("sizeperjob must be a positive integer optionally followed by one of 'K', 'M', 'G'")
    size = int(result.group(1))
    multiplier = result.group(2)
    if multiplier == 'K' or multiplier == '':
        size = size * 1000
    elif multiplier == 'M':
        size = size * 1000000
    elif multiplier == 'G':
        size = size * 1000000000
    return size


def get_rsync_args(value):
    # someday we should really check to make sure that
    # args here make sense.  for now we shuck that job
    # off to the user :-P
    if not value:
        return None
    if ',' not in value:
        return [value]
    else:
        return value.split(',')


def main():
    source_host_name = None
    dest_host_name = None
    dest_dir = None
    source_dir = None
    rsync_list = None
    rsync_args = None
    max_files_per_job = None
    max_du_per_job = None
    worker_count = None
    dryrun = False
    skip_deletes = False
    verbose = False

    try:
        (options, remainder) = getopt.gnu_getopt(
            sys.argv[1:], "", ["source_hostname=", "dest_hostname=",
                               "destdir=", "sourcedir=",
                               "rsynclist=", "rsyncargs=", "filesperjob=",
                               "sizeperjob=", "workercount=", "dryrun",
                               "skipdeletes", "verbose"])
    except:
        usage("Unknown option specified")

    for (opt, val) in options:
        if opt == "--dryrun":
            dryrun = True
        elif opt == "--filesperjob":
            if not val.isdigit():
                usage("filesperjob must be a positive integer")
            max_files_per_job = int(val)
        elif opt == "--source_hostname":
            source_host_name = val
        elif opt == "--dest_hostname":
            dest_host_name = val
        elif opt == "--destdir":
            dest_dir = val
        elif opt == "--sourcedir":
            source_dir = val
        elif opt == "--rsynclist":
            rsync_list = val
        elif opt == "--rsyncargs":
            rsync_args = get_rsync_args(val)
        elif opt == "--sizeperjob":
            max_du_per_job = get_size_in_bytes(val)
        elif opt == "--skipdeletes":
            skip_deletes = True
        elif opt == "--verbose":
            verbose = True
        elif opt == "--workercount":
            if not val.isdigit():
                usage("workercount must be a positive integer")
            worker_count = int(val)

    if len(remainder) > 0:
        usage("Unknown option specified")

    if not source_dir or not dest_dir:
        usage("Missing required option")

    if source_host_name is not None and dest_host_name is not None:
        usage("At most one of source_hostname or dest_hostname may be specified")

    if dest_host_name is None and not os.path.isdir(dest_dir):
        usage("dest rsync directory %s"
              " does not exist or is not a directory" % dest_dir)

    if source_host_name is None and not os.path.isdir(source_dir):
        usage("source rsync directory %s"
              " does not exist or is not a directory" % source_dir)

    if not rsync_list:
        rsync_list = "rsync-list.txt.rsync"

    if not max_files_per_job:
        max_files_per_job = 1000

    if not max_du_per_job:
        max_du_per_job = 500000000

    if not worker_count:
        worker_count = 1

    if not rsync_args:
        rsync_args = ["-aq"]

    if source_dir[-1] == '/':
        source_dir = source_dir[:-1]

    if dest_dir[-1] == '/':
        dest_dir = dest_dir[:-1]

    mirror = Mirror(source_host_name, dest_host_name,
                    source_dir, dest_dir,
                    rsync_list, rsync_args, max_files_per_job,
                    max_du_per_job, worker_count,
                    skip_deletes, verbose, dryrun)

    fdesc = mirror.get_rsync_file_listing()
    try:
        mirror.process_rsync_file_list(fdesc)
    except:
        mirror.cleanup()
        raise
    else:
        mirror.cleanup()


if __name__ == "__main__":
    main()
