import os
from datetime import datetime
from customexceptions import MergeException
from log import getLogger
from proc import Process
from util import createTempFile, write

MIN_GIT_VERSION="1.6.3.msysgit.0"

class Git():
    def __init__(self, profile, testMode=False):
        self.repo_dir = profile.get("git") 
        if not os.path.exists(self.repo_dir):
            raise Exception("Git repo " + self.repo_dir + " does not exist!")
        if not os.path.exists(os.path.join(self.repo_dir,'.git')):
            raise Exception(self.repo_dir + " is not a git repo! -- no .git folder found")
        self.logger = getLogger("Git")
        #self.versionCheck()
        self.testMode = testMode
        if self.testMode:
            self.logger.info("Test mode enabled")
        
    def versionCheck(self):
        def extractVersionValue(version_str):
            split = version_str.split(".")
            return int("" + split[0] + split[1] + split[2] + split[4])
        proc = self._exec(['--version'])
        version_str = proc.stdout.split(" ")[2]
        installed_ver = extractVersionValue(version_str)
        if not installed_ver >= extractVersionValue(MIN_GIT_VERSION):
            raise Exception("Git version " + version_str + " is not supported.  You must have version " + MIN_GIT_VERSION + " or later installed.")
        self.logger.info("Installed Git version " + version_str);

    def getCurrentBranch(self):
        for branch in self._exec(['branch']).stdout.split('\n'):
            if branch.startswith('*'):
                branch = branch[2:]
                return branch
        return ""

    def _exec(self, args, check=False, env=None, returnCode=0, decode=True):
        proc = Process('git', args, self.repo_dir, env, outcome=returnCode, decode=decode)
        proc.call()
        
        return proc   
    
    def getBranchList(self):
        def trm(branch):
            return branch[2:]
        return list(map(trm,self._exec(['branch']).stdout.split('\n')))
    
    def createBranch(self,branchname,rootCommit=None):
        command = ['branch',branchname]
        if rootCommit != None:
            command.append(rootCommit)
        self._exec(command)
        
    def branchExists(self,branchname):
        if branchname in self.getBranchList():
            return True
        return False
    
    def deleteBranch(self,branchname,force=False):
        if self.branchExists(branchname):
            deleteArg = '-d'
            if force:
                deleteArg = '-D'
            self._exec(['branch',deleteArg,branchname])

    def getFileHash(self,file):
        return self._exec(['hash-object', file]).stdout[0:-1]
    
    def commit(self,comment="<no comment>",env=None):
        proc = self._exec(['commit','--allow-empty','-m',comment],env)
        commit_id = proc.stdout.split(" ")[1][:-1]
        return commit_id
    
    def add(self,path):
        self._exec(['add',path])
        
    def remove(self,path):
        self._exec(['rm','-f','-r',path])

    def rebase(self,branch):
        proc = self._exec(['rebase', branch], returnCode=0)
        if proc.returncode != 0:
            raise Exception('Error during rebase. ' + proc.stdout + proc.stderr)
        return proc.stdout
    
    def reset(self,commit='HEAD'):
        self._exec(['reset', '--hard', commit])
                    
    def merge(self,branch,message='cc->git auto merge'):
        return self._exec(['merge','-m',message,branch])

    def pull(self):
        ## In testing mode, we don't care if the pull fails.
        if self.testMode:
            self.logger.debug("In test mode, ignoring return code..." )
            return self._exec(['pull'], returnCode="*")
        return self._exec(['pull']).stdout

    def fetch(self):
        return self._exec(['fetch']).stdout
	
    def submodule(self,arg1,arg2):
        return self._exec(['submodule',arg1,arg2])
    
    def push(self,branchName,remote="origin"):
        ## In testing mode, we don't care if the push fails.
        cmd = ['push', remote, branchName]
        if self.testMode:
            self.logger.debug("In test mode, ignoring return code..." )
            return self._exec(cmd, returnCode="*")
        return self._exec(cmd)
        
    def checkout(self,branchname,force=False):
        if force:
            self._exec(['checkout','-f',branchname])
        else:
            self._exec(['checkout',branchname])
            
    def checkoutPath(self,ref,path):
        self._exec(['checkout',ref,path])
        
    def getLastCommit(self, branchname):
        return self.getCommit(branchname)

    def getCommit(self,commit_id):
        output = self._exec(['log', '-n', '1', '--pretty=format:%H?*?%ce?*?%cn?*?%ai?*?%s?*?%b', '%s' % commit_id]).stdout
        split = output.split("?*?")
        return Commit(split[0],split[3],split[2],split[1],split[4] + '\n' + split[5])

    def getCommitHistory(self, start_id, end_id):
        commits = []
        output = self._exec(['log', '-M', '-z', '--reverse', '--pretty=format:%H?*?%ce?*?%cn?*?%ai?*?%s?*?%b', start_id + '..' + end_id]).stdout
        if len(output.strip()) > 0:
            lines = output.split('\x00')
            for line in lines:
                split = line.split("?*?")
                commits.append(Commit(split[0],split[3],split[2],split[1],split[4] + '\n' + split[5]))
        return commits
        
    def checkPristine(self):
        if not os.path.exists(".git"):
            raise Exception('No .git directory found')
        if(len(self._exec(['ls-files', '--modified']).stderr.splitlines()) > 0):
            raise Exception('There are uncommitted files in your git directory')

    def doStash(self, f, stash=True):
        if(stash):
            self._exec(['stash'])
        f()
        if(stash):
            self._exec(['stash', 'pop'])
    
    # Long tag messages or funny characters can cause tagging to fail if the 
    # message is passed as a command line arg.  Thus, we right the message
    # to a file and let Git read the message from that file.        
    def tag(self, tag, id="HEAD", message=None):
        msgTempFile = None
        cmd = ['tag', '-f']
        if message:
            msgTempFile = createTempFile(message)
            cmd.extend(['-F', msgTempFile])
        cmd.extend([tag, id])
        try :
            self._exec(cmd)
        finally :
            if msgTempFile:
                os.unlink(msgTempFile)  
    
    def show(self, sha1):
        proc = self._exec(['show',sha1])
        return proc.stdout
        
    def getParentCommits(self, commit):
        output = self._exec(['log','--pretty=format:%P', '-n', '1' ,commit]).stdout
        if not output:
            return []
        parents = output.split(' ')
        return parents
    
    def getMergeBase(self, commit1, commit2):
        output = self._exec(['merge-base',commit1, commit2]).stdout
        return output

    #===============================================================================
    #  getCommitList - 
    #    Operating on the CURRENT BRANCH, this method generates a list of 
    #    commits that is suited to cherry-pick to another branch.  The list 
    #    of commits provided is the minimal set required to duplicate the
    #    commit history of from startCommit to endCommit, regardless of the number
    #    of merges/branches that exist between the two points.
    #===============================================================================
    def getCommitList(self, startCommit, endCommit):
        commits = []
        def walkHistory(commit):
            parents = self.getParentCommits(commit)
            self.logger.debug("Parent commits" + str(parents))
            if commit == startCommit:
                return None
            for parent in parents:
                if len(commits) > 0 and commits[-1] == startCommit:
                    return None
                if parent == startCommit:
                    commits.append(self.getCommit(parent))
                    return None
                elif self.getMergeBase(startCommit,parent).strip() == startCommit:
                    commits.append(self.getCommit(parent))
                    walkHistory(parent)
        commits.append(self.getCommit(endCommit))  
        walkHistory(endCommit)
        return commits

    def mergeFiles(self, file1, base, file2, outputfile):
        merge_proc = self._exec(['merge-file', '-p', file1, base, file2])
        conflicts = merge_proc.returncode
        if conflicts > 0:
            self.logger.debug("Automatic Merge failed.  " + str(merge_proc.returncode) + ' conflicts need to be resolved manually')
            if not self.openMergeTool(file1, base, file2, outputfile):
                raise MergeException(outputfile, "Manual merge failed.")
        elif conflicts < 0:
            raise MergeException(outputfile, "Error during automatic merge: " + merge_proc.stderr)
        else:
            write(outputfile, merge_proc.stdout)
        
    def openMergeTool(self, local, base, remote, output):
        proc = Process("c:\\Program Files\\Perforce\\p4merge.exe", [base, remote, local, output], self.repo_dir)
        proc.call()
        self.logger.debug("Merge program exited with " + str(proc.returncode))
        if proc.returncode == 0:
            return True
        return False
        
    def getBlob(self, sha, file):
        proc = self._exec(['ls-tree', '-z', sha, file])
        if len(proc.stdout) > 1:
            return proc.stdout.split(' ')[2].split('\t')[0]

    def checkDiff(self, branch1,branch2):
        output = self._exec(['diff','--name-status', branch1, branch2]).stdout
        if len(output.strip()) > 0:
            return output
        else:
            return None
        
    def absolutePath(self, path):
        return os.path.join(self.repo_dir,path)
    
# Representation of a commit object
class Commit(object):
    def __init__(self,id,date,author,email,comment):
        self.id = id
        self.date = datetime.strptime(date[:19], '%Y-%m-%d %H:%M:%S')
        self.author = author
        self.email = email
        self.comment = comment
