#!/usr/bin/python3
from RemoteExecution import RemoteExecution, CommandReturn

import subprocess


class LocalExecution(RemoteExecution):
    """
    RemoteExecution implementation that ignores the host and just runs the
    command directly on localhost
    """

    def run(self, host, command):
        result = subprocess.run(command, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE)
        return CommandReturn(result.returncode, result.stdout, result.stderr)

    def start_job(self, host, command):
        print(command)
        process = subprocess.Popen(command, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
        return process

    def monitor_job(self, host, job):
        job.poll()
        if job.returncode is None:
            return CommandReturn(None, None, None)
        else:
            stdout, stderr = job.communicate()
            return CommandReturn(job.returncode, stdout, stderr)

    def kill_job(self, host, job):
        job.kill()

    def wait_job(self, host, job):
        stdout, stderr = job.communicate()
        return CommandReturn(job.returncode, stdout, stderr)
