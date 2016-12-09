#!/usr/bin/python3
import abc


class CommandReturn():
    """
    Class that provides a standarized method to return command execution.
    It assumes the standard output and errors are "small" enough to be stored
    on memory.
    """
    def __init__(self, returncode, stdout, stderr):
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr


class RemoteExecution(metaclass=abc.ABCMeta):
    """
    Fully-abstract class that defines the interface for implementable remote
    execution methods.
    """

    @abc.abstractmethod
    def run(self, host, command):
        """
        Executes a command on a host and gets blocked until it finishes.
        returns the exit code, the stdout and the stderr.
        """
        pass

    @abc.abstractmethod
    def start_job(self, host, command):
        """
        Starts the given command in the background and returns immediately.
        Returns a job id for monitoring purposes.
        """
        pass

    @abc.abstractmethod
    def monitor_job(self, host, job):
        """
        Returns a CommandReturn object of the command- None as the returncode if
        the command is still in progress, an integer with the actual code
        returned if it finished.
        """
        pass

    @abc.abstractmethod
    def kill_job(self, host, job):
        """
        Forces the stop of a running job.
        """
        pass

    @abc.abstractmethod
    def wait_job(self, host, job):
        """
        Waits until job finishes, then returns a CommandReturn object.
        """
        pass
