import subprocess, sys, os
from log import getLogger


class UnexpectedReturnCodeException(Exception):        
    def __init__(self, message, process):
        self.process = process
        self.message = message
    
    def __str__(self):
        return self.message
        
class Process():
    def __init__(self, exe, cmd, cwd, env=None, outcome=0, decode=True):
        self.cmd = cmd
        self.cmd.insert(0, exe)
        self.cwd = cwd
        self.env = env
        self.decode = decode
        self.outcome = outcome
        self.logger = getLogger("sub-process(" + exe + ")")
    
    def call(self):
#        os.chdir(self.cwd + "/")
#        self.logger.debug("Current dir: " + os.getcwd() + " Passed in: " + self.cwd)
        self.cmd.insert(1, "--git-dir=" + self.cwd + "/.git/")
        self.logger.debug(' '.join(self.cmd))
        self.process = subprocess.Popen(self.cmd, cwd=self.cwd, env=self.env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = self.process.communicate()
        self.stdout = self.__decode(stdout)
        self.stderr = self.__decode(stderr)
        ## Uncomment this if using the eclipse debugger.  There is some threading issue that causes it to 
        ## barf when using process.communicate(), which is much faster.
#        self.process.wait()
#        self.stdout = self.__decode(self.process.stdout.read())
#        self.stderr = self.__decode(self.process.stderr.read())
        self.returncode = self.process.returncode
        if not self.outcome == "*" and not self.returncode == self.outcome:
            self.logger.error("Unexpected return code!")
            self.logger.error("Return code was " + str(self.returncode) + " expected " + str(self.outcome))
            self.logger.error("Stderr: " + self.stderr)
            self.logger.error("Stdout: " + self.stdout)
            raise UnexpectedReturnCodeException("Unexpected returncode (" + str(self.returncode) + ") when executing " + str(self.cmd), self)
        elif len(self.stderr) > 0:
            self.logger.error("Stderr: " + self.stderr)
    def start(self):
        self.process = subprocess.Popen(self.cmd, cwd=self.cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE, env=self.env, shell=True)
        
    def __decode(self, str):
        if self.decode:
            try:
                return str.decode('utf-8', sys.stdin.encoding)
            except Exception as e:
		try:
                    return str.decode("cp1252", sys.stdin.encoding)
                except Exception as e:
                    return str.decode('utf-8', 'UTF-8')
        return str
    
    def sendInput(self,input):
        self.process.communicate(input)
        

