#!/usr/bin/python3
from RemoteExecution import RemoteExecution
from LocalExecution import LocalExecution

import shlex


class SSHExecution(RemoteExecution):

    def __init__(self, user='root', port=22):
        self.user = user
        self.port = port
        self.localExecution = LocalExecution()

    def get_ssh_command(self, host, command):
        # TODO: accept ipv6-style hosts
        return ['/usr/bin/ssh', '-p', str(self.port),
                '@'.join([self.user, host]), ' '.join([shlex.quote(x)
                                                       for x in command])]

    def run(self, host, command):
        # We use the command line client when paramiko is not available
        return self.localExecution.run('localhost',
                                       self.get_ssh_command(host, command))

    def start_job(self, host, command):
        return self.localExecution.start_job('localhost',
                                             self.get_ssh_command(host,
                                                                  command))

    def monitor_job(self, host, job):
        return self.localExecution.monitor_job('localhost', job)

    def kill_job(self, host, job):
        self.localExecution.kill_job('localhost', job)

    def wait_job(self, host, job):
        return self.localExecution.wait_job('localhost', job)
