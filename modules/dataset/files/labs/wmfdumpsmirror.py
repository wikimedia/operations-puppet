import getopt
import os
import re
import sys
import shutil
import multiprocessing

from subprocess import Popen, PIPE
from Queue import Empty


class Job(object):

    def __init__(self, jobId, jobContents):
        self.jobId = jobId  # this must be unique across all jobs
        self.contents = jobContents
        self.done = False
        self.failed = False

    def markDone(self):
        self.done = True

    def markFailed(self):
        self.failed = True

    def checkIfDone(self):
        return self.done

    def checkIfFailed(self):
        return self.failed


class RsyncJob(Job):

    datePattern = re.compile('^20[0-9]{6}$')

    def __init__(self, contents):
        super(RsyncJob, self).__init__(contents[0], contents)
        self.rsyncedByJob = self.getDirsPerProjectRsyncedByJob()

    # things that get here should look like:
    # aawikibooks/20120317/aawikibooks-20120317-all-titles-in-ns0.gz
    def _getPathComponentsFromFileName(self, path):
        if os.sep not in path:
            raise MirrorError(
                "bad line encuntered in rsync directory list: '%s'" % path)

        components = path.split(os.sep)
        if len(components) < 3 or not RsyncJob.datePattern.search(components[-2]):
            raise MirrorError(
                "what garbage is this: %s in the filenames for rsync? " % path)
        return components

    def getDirsPerProjectRsyncedByJob(self):
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
            components = self._getPathComponentsFromFileName(line)
            if len(components):
                project = os.sep + components[-3]
                projectSubdir = components[-2]
                projectFile = components[-1]
                if project not in projects.keys():
                    projects[project] = {}
                if projectSubdir not in projects[project]:
                    projects[project][projectSubdir] = []
                projects[project][projectSubdir].append(projectFile)

        return projects


class RsyncFilesProcessor(object):

    # for now we have the file list be a flat file, sometime in the
    # not to distant future it will be maybe a stream cause we'll be
    # feeding a list from the api, that will be sketchy
    def __init__(self, fileListFd, maxFilesPerJob, maxDuPerJob, workerCount,
                 rsyncRemotePath, localPath, rsyncArgs, verbose, dryrun):
        self.fileListFd = fileListFd
        self.maxFilesPerJob = maxFilesPerJob
        self.maxDuPerJob = maxDuPerJob
        self.verbose = verbose
        self.dryrun = dryrun
        self.rsyncArgs = rsyncArgs
        self.localPath = localPath
        self.rsyncer = Rsyncer(rsyncRemotePath, localPath, self.rsyncArgs,
                               self.verbose, self.dryrun)
        self.jQ = JobQueue(workerCount, self.rsyncer,
                           self.verbose, self.dryrun)
        self.datePattern = re.compile('^20[0-9]{6}$')
        self.jobsPerProject = {}
        self.jobs = {}
        self.deleter = DirDeleter(self.jobsPerProject, self.localPath,
                                  self.verbose, self.dryrun)

    def _getFileSize(self, line):
        return int(line.split()[1])

    def _getPath(self, line):
        return line.split()[4]

    def _checkLineWanted(self, line):
        """is this a line we want, it has information about a
        file for our jobs? if so return true, if not return
        false.  we assume lines starting with '#' are comments,
        blank lines are to be skipped, and we don't want
        directory entries, only files and/or symlinks"""
        if not line or line[0] == 'd' or line[0] == '#':
            return False
        else:
            return True

    def _getFileName(self, line):

        # the input consists of a list of filenames plus other info and we
        # can expect the dumps of one project to be listed in consecutive
        # lines rather than scattered about in the file (which is of no
        # concern for us but is good for rsync)
        # it's produced by rsync --list-only...

        # example:

        # drwxrwxr-x        4096 2012/03/17 13:23:04 aawikibooks
        # drwxr-xr-x        4096 2012/03/17 13:24:10 aawikibooks/20120317
        # -rw-r--r--          39 2012/03/17 13:23:54 aawikibooks/20120317/aawikibooks-20120317-all-titles-in-ns0.gz
        # -rw-r--r--         760 2012/03/17 13:23:39 aawikibooks/20120317/aawikibooks-20120317-category.sql.gz
        # -rw-r--r--         826 2012/03/17 13:23:23 aawikibooks/20120317/aawikibooks-20120317-categorylinks.sql.gz
        # -rw-r--r--        1513 2012/03/17 13:23:30 aawikibooks/20120317/aawikibooks-20120317-externallinks.sql.gz

        # we may also have a few files in the top level directory that
        # we want the mirrors to pick up (text or html files of particular interest)

        # note that the directories are also listed, we want to skip those
        # we'll allow comments in there in case some other script produces the
        # files or humans edit them; skip those and empty lines, the rest
        # should be good data
        path = self._getPath(line)
        if os.sep not in path:
            return line
        else:
            return line.split(os.sep)[-1]

    def stuffJobsOnQueue(self):
        fileCount = 0
        fileDu = 0
        files = []
        line = self.fileListFd.readline().rstrip()
        while line:
            if not self._checkLineWanted(line):
                line = self.fileListFd.readline().rstrip()
                continue
            path = self._getPath(line)
            if path:
                fileCount = fileCount + 1
                fileDu = fileDu + self._getFileSize(line)
                files.append(path)
                if fileDu >= self.maxDuPerJob or fileCount >= self.maxFilesPerJob:
                    job = self.makeJob(files)
                    if self.dryrun or self.verbose:
                        MirrorMsg.display("adding job %s (size %d and filecount %d) to queue\n" % (job.jobId, fileDu, fileCount))
                    self.jQ.addToJobQueue(job)
                    fileDu = 0
                    fileCount = 0
                    files = []
            line = self.fileListFd.readline().rstrip()

        if fileCount:
            if self.dryrun or self.verbose:
                MirrorMsg.display("adding job %s (size %d and filecount %d) to queue\n" % (job.jobId, fileDu, fileCount))
            self.jQ.addToJobQueue(self.makeJob(files))

        self.jQ.setEndOfJobs()
        self.deleter.setJobList(self.jobs)

    def makeJob(self, files):
        job = RsyncJob(files)
        for project in job.rsyncedByJob.keys():
            if project not in self.jobsPerProject.keys():
                self.jobsPerProject[project] = []
            self.jobsPerProject[project].append(job.jobId)
        self.jobs[job.jobId] = job
        return job

    def doPostJobProcessing(self, skipDeletes):
        while True:
            # any completed jobs?
            job = self.jQ.getJobFromNotifyQueue()
            # no more jobs and mo more workers.
            if not job:
                if not self.jQ.getActiveWorkerCount():
                    if self.dryrun or self.verbose:
                        MirrorMsg.display("no jobs left and no active workers\n")
                    break
                else:
                    continue
            if self.dryrun:
                MirrorMsg.display("jobId %s would have been completed\n" %
                                  job.jobId)
            elif self.verbose:
                MirrorMsg.display("jobId %s completed\n" % job.jobId)

            # update status of job in our todo queue
            j = self.jobs[job.jobId]
            if job.checkIfDone():
                j.markDone()
            if job.checkIfFailed():
                j.markFailed()

            if not skipDeletes:
                if self.verbose or self.dryrun:
                    MirrorMsg.display("checking post-job deletions\n")
                self.deleter.checkAndDoDeletes(j)


class DirDeleter(object):
    """remove all dirs for the project that are not in the
    list of dirs to rsync, we don't want them any more"""

    def __init__(self, jobsPerProject, localPath, verbose, dryrun):
        self.jobsPerProject = jobsPerProject
        self.localPath = localPath
        self.verbose = verbose
        self.dryrun = dryrun

    def getFullLocalPath(self, relPath):
        if relPath.startswith(os.sep):
            relPath = relPath[len(os.sep):]
        return(os.path.join(self.localPath, relPath))

    def setJobList(self, jobList):
        self.jobList = jobList

    def checkAndDoDeletes(self, job):
        """given a file list, we need to see if we are done with
        one project and on to the next, which things we rsynced and
        which not, and delete the ones not (i.e. left over from previous
        run and we don't want them now); failed rsyncs may not have
        completed normally so we won't do deletions for a project
        with failed jobs"""
        for project in job.rsyncedByJob.keys():
            ids = [self.jobList[jobId] for jobId in self.jobsPerProject[project] if not self.jobList[jobId].checkIfDone() or self.jobList[jobId].checkIfFailed()]
            if not len(ids):
                if self.dryrun:
                    MirrorMsg.display("Would do deletes for project %s\n" %
                                      project)
                elif self.verbose:
                    MirrorMsg.display("Doing deletes for project %s\n" %
                                      project)
                self.doDeletes(project)
            else:
                if self.verbose:
                    MirrorMsg.display("No deletes for project %s\n" % project)

    def getListOfDirsRsyncedForProject(self, project):
        """get directories we synced for this project,
        across all jobs"""
        dirsForProject = []
        for jobId in self.jobsPerProject[project]:
            dirsForProject.extend([k for k in self.jobList[jobId].rsyncedByJob[project].keys() if k not in dirsForProject])
        return dirsForProject

    def getListOfFilesRsyncedForDirOfProject(self, project, dirName):
        """get files we synced for a specific dir for
        this project, across all jobs"""
        filesForDirInProject = []
        for jobId in self.jobsPerProject[project]:
            if dirName in self.jobList[jobId].rsyncedByJob[project].keys():
                filesForDirInProject.extend(self.jobList[jobId].rsyncedByJob[project][dirName])
        return filesForDirInProject

    def doDeletes(self, project):
        # fixme a sanity check here would be nice before we just remove stuff

        # find which dirs were rsynced for this project,
        # remove the ones we didn't as we no longer want them
        projectDirsRsynced = self.getListOfDirsRsyncedForProject(project)

        if not os.path.exists(self.getFullLocalPath(project)):
            return
        dirs = os.listdir(self.getFullLocalPath(project))

        if self.dryrun or self.verbose:
            MirrorMsg.display("for project %s:" % project)
        if self.dryrun:
            MirrorMsg.display("would delete (dirs): ", True)
        elif self.verbose:
            MirrorMsg.display("deleting (dirs): ", True)

        if not len(dirs):
            if self.dryrun or self.verbose:
                MirrorMsg.display("None", True)

        for d in dirs:
            if d not in projectDirsRsynced:
                dirName = os.path.join(project, d)
                if self.dryrun or self.verbose:
                    MirrorMsg.display("'%s'" % dirName, True)
                if not self.dryrun:
                    try:
                        shutil.rmtree(self.getFullLocalPath(dirName))
                    except:
                        MirrorMsg.warn("failed to remove directory or contents of %s\n" % self.getFullLocalPath(dirName))
                        pass
        if self.dryrun or self.verbose:
            MirrorMsg.display('\n', True)

        # now for the dirs we did rsync, check the files existing now
        # against the files that we rsynced, and remove the extraneous ones
        if self.dryrun or self.verbose:
            MirrorMsg.display("for project %s:" % project)
        if self.dryrun:
            MirrorMsg.display("would delete (files): ", True)
        elif self.verbose:
            MirrorMsg.display("deleting (files): ", True)

        for d in dirs:
            if d in projectDirsRsynced:
                filesExisting = os.listdir(self.getFullLocalPath(os.path.join(project, d)))
                filesRsynced = self.getListOfFilesRsyncedForDirOfProject(project, d)
                filesToToss = [f for f in filesExisting if f not in filesRsynced]

                if self.dryrun or self.verbose:
                    MirrorMsg.display("for directory " + d, True)
                    if not len(filesToToss):
                        MirrorMsg.display("None", True)
                for f in filesToToss:
                    fileName = self.getFullLocalPath(os.path.join(project, d,
                                                                  f))
                    if os.path.isdir(fileName):
                            continue
                    if self.dryrun or self.verbose:
                        # we should never be pushing directories across as part
                        # of the rsync. so if we have a local directory, leave
                        # it alone
                        MirrorMsg.display("'%s'" % f, True)
                    if not self.dryrun:
                        try:
                            os.unlink(fileName)
                        except:
                            MirrorMsg.warn("failed to unlink file %s\n" %
                                           fileName)
                            pass
        if self.dryrun or self.verbose:
            MirrorMsg.display('\n', True)


class JobHandler(object):
    def init(self):
        """this should be overriden to set and args
        that you need to actually process a job"""
        pass

    def doJob(self, contents):
        """override this with a function that processes
        contents as desired"""
        print contents
        return False


class Rsyncer(JobHandler):
    """all the info about rsync you ever wanted to know but were afraid
    to ask..."""

    def __init__(self, rsyncRemotePath, localPath, rsyncArgs, verbose, dryrun):
        self.rsyncRemotePath = rsyncRemotePath
        self.localPath = localPath
        self.rsyncArgs = rsyncArgs
        self.verbose = verbose
        self.dryrun = dryrun
        self.cmd = Command(verbose, dryrun)

    def doJob(self, contents):
        return self.doRsync(contents)

    def doRsync(self, files):
        command = ["/usr/bin/rsync"]
        command.extend(["--files-from", "-"])
        command.extend(self.rsyncArgs)
        command.extend([self.rsyncRemotePath, self.localPath])

        if self.dryrun or self.verbose:
            commandString = " ".join(command)
        if self.dryrun:
            MirrorMsg.display("would run %s" % commandString)
        elif self.verbose:
            MirrorMsg.display("running %s" % commandString)
        if self.dryrun or self.verbose:
            MirrorMsg.display("with input:\n" + '\n'.join(files) + '\n', True)
        return self.cmd.runCommand(command, shell=False,
                                   inputText='\n'.join(files) + '\n')


class JobQueueHandler(multiprocessing.Process):

    def __init__(self, jQ, handler, verbose, dryrun):
        multiprocessing.Process.__init__(self)
        self.jQ = jQ
        self.handler = handler
        self.verbose = verbose
        self.dryrun = dryrun

    def run(self):
        while True:
            job = self.jQ.getJobOnQueue()
            if not job:  # no jobs left, we're done
                break
            self.doJob(job)

    def doJob(self, job):
        result = self.handler.doJob(job.contents)
        if result:
            job.markFailed()
        else:
            job.markDone()
        self.jQ.notifyJobDone(job)


class JobQueue(object):

    def __init__(self, initialWorkerCount, handler, verbose, dryrun):
        """create queue for jobs, plus specified
        number of workers to read from the queue"""
        self.handler = handler
        self.verbose = verbose
        self.dryrun = dryrun
        # queue of jobs to be done (all the info needed, plus job id)
        self.todoQueue = multiprocessing.Queue()

        # queue to which workers write job ids of completed jobs
        self.notifyQueue = multiprocessing.Queue()

        # this 'job' on the queue means there are no more
        # jobs. we put on of these on queue for each worker
        self.endOfJobs = None

        self._initialWorkerCount = workerCount
        self._activeWorkers = []
        if not self._initialWorkerCount:
            self._initialWorkerCount = 1
        if self.verbose or self.dryrun:
            MirrorMsg.display("about to start up %d workers:" %
                              self._initialWorkerCount)
        for i in xrange(0, self._initialWorkerCount):
            w = JobQueueHandler(self, self.handler, self.verbose, self.dryrun)
            w.start()
            self._activeWorkers.append(w)
            if self.verbose or self.dryrun:
                MirrorMsg.display('.', True)
        if self.verbose or self.dryrun:
            MirrorMsg.display("done\n", True)

    def getJobOnQueue(self):
        # after 5 minutes of waiting around we decide that
        # no one is ever going to put stuff on the queue
        # again.  either the main process is done filling
        # the queue or it died or hung

        try:
            job = self.todoQueue.get(timeout=60)
        except Empty:
            if self.verbose or self.dryrun:
                MirrorMsg.display("job todo queue was empty\n")
            return False

        if (job == self.endOfJobs):
            if self.verbose or self.dryrun:
                MirrorMsg.display("found jobs done marker on jobs queue\n")
            return False
        else:
            if self.verbose or self.dryrun:
                MirrorMsg.display("retrieved from the job queue: %s\n" %
                                  job.jobId)
            return job

    def notifyJobDone(self, job):
        self.notifyQueue.put_nowait(job)

    def addToJobQueue(self, job=None):
        if (job):
            self.todoQueue.put_nowait(job)

    def setEndOfJobs(self):
        """stuff 'None' on the queue, so that when
        a worker reads this, it will clean up and exit"""
        for i in xrange(0, self._initialWorkerCount):
            self.todoQueue.put_nowait(self.endOfJobs)

    def getJobFromNotifyQueue(self):
        """see if any job has been put on
        the notify queue (meaning that it has
        been completed)"""
        jobDone = False
        # wait up to one minute.  after that we're pretty sure
        # that if there are no active workers there are no more
        # jobs that are going to get done either.
        try:
            jobDone = self.notifyQueue.get(timeout=60)
        except Empty:
            if not self.getActiveWorkerCount():
                return False
        return jobDone

    def getActiveWorkerCount(self):
        self._activeWorkers = [w for w in self._activeWorkers if w.is_alive()]
        return len(self._activeWorkers)


class Command(object):

    def __init__(self, verbose, dryrun):
        self.dryrun = dryrun
        self.verbose = verbose

    def runCommand(self, command, shell=False, inputText=False):
        """Run a command, expecting no output. Raises MirrorError on
        non-zero return code."""

        if type(command).__name__ == "list":
            commandString = " ".join(command)
        else:
            commandString = command
        if (self.dryrun or self.verbose):
            if self.dryrun:
                MirrorMsg.display("would run %s\n" % commandString)
                return
            if self.verbose:
                MirrorMsg.display("about to run %s\n" % commandString)

        if inputText:
            proc = Popen(command, shell=shell, stderr=PIPE, stdin=PIPE)
        else:
            proc = Popen(command, shell=shell, stderr=PIPE)

        output, error = proc.communicate(inputText)
        if output:
            print output

        if proc.returncode:
            MirrorMsg.warn("command '%s failed with return code %s and error %s\n"
                           % (commandString, proc.returncode, error))

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
    rsync each one; remove directories locally that aren't in the file"""

    def __init__(self, hostName, remoteDirName, localDirName, rsyncList,
                 rsyncArgs, maxFilesPerJob, maxDuPerJob, workerCount,
                 skipDeletes, verbose, dryrun):
        self.hostName = hostName
        self.remoteDirName = remoteDirName
        self.localDirName = localDirName
        if self.hostName:
            self.rsyncRemoteRoot = self.hostName + "::" + self.remoteDirName
        else:
            # the 'remote' dir is actually on the local host and we are
            # rsyncing from one locally mounted filesystem to another
            self.rsyncRemoteRoot = self.remoteDirName
        self.rsyncFileList = rsyncList
        self.rsyncArgs = rsyncArgs
        self.verbose = verbose
        self.dryrun = dryrun
        self.maxFilesPerJob = maxFilesPerJob
        self.maxDuPerJob = maxDuPerJob
        self.workerCount = workerCount
        self.skipDeletes = skipDeletes

    def getFullLocalPath(self, relPath):
        if relPath.startswith(os.sep):
            relPath = relPath[len(os.sep):]
        return(os.path.join(self.localDirName, relPath))

    def getRsyncFileListing(self):
        """via rsync, get full list of files for rsync from remote host"""
        command = ["/usr/bin/rsync", "-tp", self.rsyncRemoteRoot + '/' + self.rsyncFileList, self.localDirName]
        # here we don't do a dry run, we will actually retrieve
        # the list (because otherwise the rest of the run
        # won't produce any information about what the run
        # would do).  we will turn on verbosity though if
        # dryrun was set
        cmd = Command(self.verbose or self.dryrun, False)
        result = cmd.runCommand(command, shell=False)
        if result:
            raise MirrorError("Failed to get list of files for rsync\n")

    def processRsyncFileList(self):
        f = open(self.getFullLocalPath(self.rsyncFileList))
        if not f:
            raise MirrorError("failed to open list of files for rsync",
                              os.path.join(self.localDirName,
                                           self.rsyncFileList))
        self.filesProcessor = RsyncFilesProcessor(f, self.maxFilesPerJob,
                                                  self.maxDuPerJob,
                                                  self.workerCount,
                                                  self.rsyncRemoteRoot,
                                                  self.localDirName,
                                                  self.rsyncArgs,
                                                  self.verbose, self.dryrun)
        # create all jobs and put on todo queue
        self.filesProcessor.stuffJobsOnQueue()
        f.close()

        # watch jobs get done and do post job cleanup after each one
        if self.verbose or self.dryrun:
            MirrorMsg.display("waiting for workers to process jobs\n")
        self.filesProcessor.doPostJobProcessing(self.skipDeletes)

    def setupDir(self, dirName):
        if self.dryrun:
            return

        if os.path.exists(dirName):
            if not os.path.isdir(dirName):
                raise MirrorError(
                    "target directory name %s is not a directory, giving up" %
                    dirName)
        else:
            os.makedirs(dirName)


def usage(message=None):
    if message:
        print message
        print "Usage: python wmfdumpsmirror.py [--hostname dumpserver] -remotedir dirpath"
        print "              --localdir dirpath [--rsyncargs args] [--rsynclist filename]"
        print "              [--filesperjob] [--sizeperjob] [--workercount] [--dryrun]"
        print "              [--skipdeletes] [--verbose]"
        print ""
        print "This script does a continuous rsync from specified XML dumps rsync server,"
        print "rsyncing the last N good dumps of each project and cleaning up old files."
        print "The rsync is done on a list of files, not directories; bear this in mind"
        print "when using the --rsyncargs option below.  The list of files should have"
        print "been produced by rsync --list-only or be in the same format."
        print ""
        print "--hostname:     the name of the dump rsync server to contact"
        print "                if this is left blank, the copy will be done from one path"
        print "                to another on the local host"
        print "--remotedir:   the remote path to the top of the dump directory tree"
        print "                containing the mirror"
        print "--localdir:     the full path to the top of the local directory tree"
        print "                containing the mirror"
        print "--rsyncargs:    arguments to be passed through to rsync, comma-separated,"
        print "                with 'arg=value' for arguments that require a value"
        print "                example:  --rsyncargs -tp,--bandwidth=10000"
        print "                default: '-aq'"
        print "--rsynclist:    the name of the list of dumps for rsync"
        print "                default: rsync-list.txt.rsync"
        print " --filesperjob: the maximum number of files to pass to a worker to process"
        print "                at once"
        print "                default: 1000"
        print " --sizeperjob:  the maximum size of a batch of files to pass to a worker"
        print "                to process at once (may be specified in K/M/G i.e. "
        print "                kilobytes/megabytes/gigabytes; default is K) to a worker"
        print "                to process at once"
        print "                default: 500M"
        print " --workercount: the number of worker processes to do simultaneous rsyncs"
        print "                default: 1"
        print " --dryrun:      don't do the rsync of files, just get the rsync file list"
        print "                and print out what would be done"
        print " --skipdeletes: copy or update files but don't delete anything"
        print " --verbose:     print lots of diagnostic output"
        print ""
        print "Example: python wmfdumpsmirror.py --hostname dumps.wikimedia.org \\"
        print "                --localdir /opt/data/dumps --rsyncfile rsync-list.txt.rsync"
        sys.exit(1)


def getSizeInBytes(value):
    # expect digits optionally followed by one of
    # K M G; if not, then we assume K
    sizePattern = re.compile('^([0-9]+)([K|M|G])?$')
    result = sizePattern.search(value)
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


def getRsyncArgs(value):
    # someday we should really check to make sure that
    # args here make sense.  for now we shuck that job
    # off to the user :-P
    if not value:
        return None
    if ',' not in value:
        return [value]
    else:
        return value.split(',')

if __name__ == "__main__":
    hostName = None
    localDir = None
    remoteDir = None
    rsyncList = None
    rsyncArgs = None
    maxFilesPerJob = None
    maxDuPerJob = None
    workerCount = None
    dryrun = False
    skipDeletes = False
    verbose = False

    try:
        (options, remainder) = getopt.gnu_getopt(sys.argv[1:], "",
                                                 ["hostname=", "localdir=",
                                                  "remotedir=", "rsynclist=",
                                                  "rsyncargs=", "filesperjob=",
                                                  "sizeperjob=",
                                                  "workercount=", "dryrun",
                                                  "skipdeletes", "verbose"])
    except:
        usage("Unknown option specified")

    for (opt, val) in options:
        if opt == "--dryrun":
            dryrun = True
        elif opt == "--filesperjob":
            if not val.isdigit():
                usage("filesperjob must be a positive integer")
            maxFilesPerJob = int(val)
        elif opt == "--hostname":
            hostName = val
        elif opt == "--localdir":
            localDir = val
        elif opt == "--remotedir":
            remoteDir = val
        elif opt == "--rsynclist":
            rsyncList = val
        elif opt == "--rsyncargs":
            rsyncArgs = getRsyncArgs(val)
        elif opt == "--sizeperjob":
            maxDuPerJob = getSizeInBytes(val)
        elif opt == "--skipdeletes":
            skipDeletes = True
        elif opt == "--verbose":
            verbose = True
        elif opt == "--workercount":
            if not val.isdigit():
                usage("workercount must be a positive integer")
            workerCount = int(val)

    if len(remainder) > 0:
        usage("Unknown option specified")

    if not remoteDir or not localDir:
        usage("Missing required option")

    if not os.path.isdir(localDir):
        usage("local rsync directory", localDir,
              "does not exist or is not a directory")

    if not rsyncList:
        rsyncList = "rsync-list.txt.rsync"

    if not maxFilesPerJob:
        maxFilesPerJob = 1000

    if not maxDuPerJob:
        maxDuPerJob = 500000000

    if not workerCount:
        workerCount = 1

    if not rsyncArgs:
        rsyncArgs = ["-aq"]

    if remoteDir[-1] == '/':
        remoteDir = remoteDir[:-1]

    if localDir[-1] == '/':
        localDir = localDir[:-1]

    mirror = Mirror(hostName, remoteDir, localDir, rsyncList, rsyncArgs,
                    maxFilesPerJob, maxDuPerJob, workerCount, skipDeletes,
                    verbose, dryrun)

    mirror.getRsyncFileListing()
    mirror.processRsyncFileList()
