#!/usr/bin/python3
from RemoteExecution import RemoteExecution
from LocalExecution import LocalExecution

import shlex
# Salt is not yet Python3-compatible
# import salt.client


class SaltExecution(RemoteExecution):

    def __init__(self):
        self.localExecution = LocalExecution()

    def get_salt_command(self, host, command):
        return ['/usr/bin/salt', host, 'cmd.run'
                ' '.join([shlex.quote(x) for x in command])]

    def run(self, host, command):
        # Salt is not yet Python3-compatible
        # local = salt.client.LocalClient()
        # result = local.cmd(host, 'cmd.run', command)
        # return result['host']
        print(self.get_salt_command(host, command))
        return self.localExecution.run('localhost',
                                       self.get_salt_command(host, command))

    def start_job(self, host, command):
        # Salt is not yet Python3-compatible
        # job = local.cmd_async(host, 'cmd.run', command)
        # return job
        return self.localExecution.start_job('localhost',
                                             self.get_salt_command(host,
                                                                   command))

    def monitor_job(self, host, job):
        return self.localExecution.monitor_job('localhost', job)

    def kill_job(self, host, job):
        self.localExecution.kill_job('localhost', job)

    def wait_job(self, host, job):
        return self.localExecution.wait_job('localhost', job)
