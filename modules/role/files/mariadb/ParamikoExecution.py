#!/usr/bin/python3
from RemoteExecution import RemoteExecution, CommandReturn

from multiprocessing import Process, Pipe
import paramiko
import shlex
import time


def run_subprocess(host, command, user, port, host_keys, input_pipe):
    e = ParamikoExecution()
    e.user = user
    e.port = port
    e.host_keys = host_keys
    result = e.run(host, command)
    input_pipe.send(result)


class ParamikoExecution(RemoteExecution):

    def __init__(self, user='root', port=22,
                 host_keys='.ssh/known_hosts'):
        self.user = user
        self.port = port
        self.host_keys = host_keys

    def run(self, host, command):
        client = paramiko.SSHClient()
        try:
            client.load_host_keys(self.host_keys)
        except OSError:
            pass
        client.set_missing_host_key_policy(paramiko.WarningPolicy())
        client.connect(host, username=self.user, port=self.port)
        try:
            stdinfile, stdoutfile, stderrfile = client.exec_command(
                ' '.join([shlex.quote(x) for x in command])
            )
            with stdoutfile as f:
                stdout = f.read()
            with stderrfile as f:
                stderr = f.read()
            stdinfile.close()
            returncode = stdoutfile.channel.recv_exit_status()
        except paramiko.SSHException:
            returncode = -1
            stdout = None
            stderr = None
        client.close()
        return CommandReturn(returncode, stdout, stderr)

    def start_job(self, host, command):
        output_pipe, input_pipe = Pipe()
        job = Process(target=run_subprocess,
                      args=(host, command, self.user, self.port,
                            self.host_keys, input_pipe)
                      )
        job.start()
        input_pipe.close()
        return {'process': job, 'pipe': output_pipe}

    def monitor_job(self, host, job):
        if job['process'].is_alive():
            return CommandReturn(None, None, None)
        else:
            result = job['pipe'].recv()
            job['pipe'].close()
            return result

    def kill_job(self, host, job):
        if job['process'].is_alive():
            job['process'].terminate()

    def wait_job(self, host, job):
        while job['process'].is_alive():
            time.sleep(1)
        result = job['pipe'].recv()
        job['pipe'].close()
        return result
