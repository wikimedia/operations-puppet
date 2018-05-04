from multiprocessing import Process, Pipe

import cumin
from cumin import query, transport, transports

from RemoteExecution import RemoteExecution, CommandReturn


# TODO: Refactor with the one on ParamikoExecution or find a better approach
def run_subprocess(host, command, input_pipe):
    e = CuminExecution()
    result = e.run(host, command)
    input_pipe.send(result)


class CuminExecution(RemoteExecution):
    """
    RemoteExecution implementation using Cumin
    """

    def __init__(self):
        # TODO
        self.config = cumin.Config('config.yaml')

    def format_command(self, command):
        if isinstance(command, str):
            return command
        else:
            return ' '.join(command)

    def run(self, host, command):
        hosts = query.Query(self.config).execute(host)
        target = transports.Target(hosts)
        worker = transport.Transport.new(self.config, target)
        worker.commands = [self.format_command(command)]
        worker.handler = 'sync'
        return_code = worker.execute()
        for nodes, output in worker.get_results():
            if host in nodes:
                result = str(bytes(output), 'utf-8')
                return CommandReturn(return_code, result, None)

        return CommandReturn(return_code, None, None)

    def start_job(self, host, command):
        output_pipe, input_pipe = Pipe()
        job = Process(target=run_subprocess, args=(host, command, input_pipe))
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
        job['process'].join()
        result = job['pipe'].recv()
        job['pipe'].close()
        return result
