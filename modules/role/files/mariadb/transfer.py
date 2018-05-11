#!/usr/bin/python3

from CuminExecution import CuminExecution as RemoteExecution
import argparse
import os
import os.path
import base64


def option_parse():
    """
    Parses the input parameters and returns them as a list.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=4444)
    parser.add_argument("source")
    parser.add_argument("target", nargs='+')
    options = parser.parse_args()
    source_host = options.source.split(':', 1)[0]
    source_path = options.source.split(':', 1)[1]
    target_hosts = []
    target_paths = []
    for target in options.target:
        target_hosts.append(target.split(':', 1)[0])
        target_paths.append(target.split(':', 1)[1])
    other_options = {'port': options.port}
    return source_host, source_path, target_hosts, target_paths, other_options


class Transferer(object):
    def __init__(self, source_host, source_path, target_hosts, target_paths, options={}):
        self.source_host = source_host
        self.source_path = source_path
        self.target_hosts = target_hosts
        self.target_paths = target_paths
        self.options = options

        self.remote_executor = RemoteExecution()

    def _run(self, host, command):
        return self.remote_executor.run(host, command)

    def is_dir(self, host, path):
        command = ['/bin/bash', '-c', r'"[ -d "{}" ]"'.format(path)]
        result = self._run(host, command)
        return not result.returncode

    def file_exists(self, host, path):
        """
        Returns true if there is a file or a directory with such path on the remote
        host given
        """
        command = ['/bin/bash', '-c', r'"[ -a "{}" ]"'.format(path)]
        result = self._run(host, command)
        return not result.returncode

    def calculate_checksum(self, host, path, is_dir):

        hash_executable = '/usr/bin/md5sum'
        parent_dir = os.path.normpath(os.path.join(path, '..'))
        basename = os.path.basename(os.path.normpath(path))
        if is_dir:
            command = ['/bin/bash', '-c',
                       r'"cd {} && /usr/bin/find {} -type f -exec {} {}"'
                       .format(parent_dir, basename, hash_executable, '\{\} \;')]
        else:
            command = ['/bin/bash', '-c', r'"cd {} && {} {}"'
                       .format(parent_dir, hash_executable, basename)]
        result = self._run(host, command)
        if result.returncode != 0:
            raise Exception('md5sum execution failed')
        return result.stdout

    def has_available_disk_space(self, host, path, size):
        command = ['/bin/bash', '-c',
                   r'"df --block-size=1 --output=avail {} | /usr/bin/tail -n 1"'.format(path)]
        result = self._run(host, command)
        if result.returncode != 0:
            raise Exception('df execution failed')
        return int(result.stdout) > size

    def disk_usage(self, host, path):
        """
        Returns the size used on the filesystem by the file path on the given host,
        or the aggregated size of all the files inside path and its subdirectories
        """
        command = ['/usr/bin/du', '--bytes', '--summarize', '{}'.format(path)]
        result = self._run(host, command)
        if result.returncode != 0:
            raise Exception('du execution failed')
        return int(result.stdout.split()[0])

    def copy_file(self, target_host, target_path, port=4444,
                  compression=True, encryption=True, password=None):
        """
        Copies a single regular file (source_path) from the source_host to the
        target_host. The final path of the file will be targetpath + / +
        basename(source_path); in other words, target_path is assumed to be a
        directory and the file will be copied inside. The target_path cannot be a
        complete file_name.
        """
        final_file = os.path.join(os.path.normpath(target_path),
                                  os.path.basename(self.source_path))
        if compression:
            compress_command = '/usr/bin/pigz -c'
            decompress_command = '| /usr/bin/pigz -c -d'
        else:
            compress_command = '/bin/cat'
            decompress_command = ''
        if encryption:
            if password is None:
                password = base64.b64encode(os.urandom(24)).decode('utf-8')
            buffer_size = 8
            cipher = 'chacha20'
            encrypt_command = ('| /usr/bin/openssl enc -{}'
                               ' -pass pass:{} -bufsize {}').format(cipher,
                                                                    password,
                                                                    buffer_size)
            decrypt_command = ('| /usr/bin/openssl enc -d -{}'
                               ' -pass pass:{} -bufsize {}').format(cipher,
                                                                    password,
                                                                    buffer_size)
        else:
            encrypt_command = ''
            decrypt_command = ''
        command = ['/bin/bash', '-c', r'"/bin/nc -l -p {} {} {} > {}"'
                   .format(port, decrypt_command, decompress_command, final_file)]
        job = self.remote_executor.start_job(target_host, command)
        command = ['/bin/bash', '-c', r'"{} < {} {} | /bin/nc -q 0 {} {}"'
                   .format(compress_command, self.source_path, encrypt_command,
                           target_host, port)]
        result = self._run(self.source_host, command)
        if result.returncode != 0:
            self.remote_executor.kill_job(target_host, job)
        else:
            self.remote_executor.wait_job(target_host, job)
        return result.returncode

    def copy_dir(self, target_host, target_path, port=4444,
                 compression=True, encryption=True, password=None):
        """
        Copies a directory and, recursively, the files and subdirs it containts,
        from from the source_host to the target_host. The final path of the
        directory will be targetpath + / + basename(source_path); in other words,
        target_path is assumed to be a directory and the source_path will be copied
        inside -it will copy the directory itself, not only the contents.
        """
        source_parent_dir = os.path.normpath(os.path.join(self.source_path, '..'))
        source_basename = os.path.basename(os.path.normpath(self.source_path))
        if compression:
            compress_command = '/usr/bin/pigz -c |'
            decompress_command = '/usr/bin/pigz -c -d |'
        else:
            compress_command = ''
            decompress_command = ''
        if encryption:
            if password is None:
                password = base64.b64encode(os.urandom(24)).decode('utf-8')
            buffer_size = 8
            cipher = 'chacha20'
            encrypt_command = ('/usr/bin/openssl enc -{} -pass pass:{}'
                               ' -bufsize {} |'
                               ).format(cipher, password, buffer_size)
            decrypt_command = ('/usr/bin/openssl enc -d -{} -pass pass:{}'
                               ' -bufsize {} |'
                               ).format(cipher, password, buffer_size)
        else:
            encrypt_command = ''
            decrypt_command = ''

        command = ['/bin/bash', '-c', r'"cd {} && /bin/nc -l -p {} | {} {} /bin/tar xf -"'
                   .format(target_path, port, decrypt_command, decompress_command)]
        job = self.remote_executor.start_job(target_host, command)
        command = ['/bin/bash', '-c', r'"cd {} && /bin/tar cf - {} | {} {} /bin/nc -q 0 {} {}"'
                   .format(source_parent_dir, source_basename, compress_command, encrypt_command,
                           target_host, port)]
        result = self._run(self.source_host, command)
        if result.returncode != 0:
            self.remote_executor.kill_job(target_host, job)
        else:
            self.remote_executor.wait_job(target_host, job)
        return result.returncode

    def open_firewall(self, target_host, port):
        command = ['/sbin/iptables', '-A', 'INPUT', '-p', 'tcp', '-s',
                   '{}'.format(self.source_host), '--dport', '{}'.format(port), '-j',
                   'ACCEPT']
        result = self._run(target_host, command)
        if result.returncode != 0:
            raise Exception('iptables execution failed')

    def close_firewall(self, target_host, port):
        command = ['/sbin/iptables', '-D', 'INPUT', '-p', 'tcp', '-s',
                   '{}'.format(self.source_host), '--dport', '{}'.format(port), '-j',
                   'ACCEPT']
        result = self._run(target_host, command)
        return result.returncode

    def sanity_checks(self):
        self.source_path = os.path.normpath(self.source_path)
        if not self.file_exists(self.source_host, self.source_path):
            print("ERROR: The specified source path {} doesn't exist on {}"
                  .format(self.source_path, self.source_host))
            return None
        original_size = self.disk_usage(self.source_host, self.source_path)
        for target_host, target_path in zip(self.target_hosts, self.target_paths):
            if not self.file_exists(target_host, target_path):
                print("ERROR: The specified target path {} doesn't exist on {}"
                      .format(target_path, target_host))
                return None
            target_final_path = os.path.join(os.path.normpath(target_path),
                                             os.path.basename(self.source_path))
            if self.file_exists(target_host, target_final_path):
                print("ERROR: The final target path {} already exists on {}."
                      .format(target_final_path, target_host))
                return None
            if not self.has_available_disk_space(target_host, target_path,
                                                 original_size):
                print("ERROR: {} doesn't have enough space on {}"
                      .format(target_host, target_path))
                return None
        source_is_dir = self.is_dir(self.source_host, self.source_path)
        source_checksum = self.calculate_checksum(self.source_host, self.source_path,
                                                  source_is_dir)
        return source_is_dir, source_checksum, original_size

    def after_transfer_checks(self, result, target_host, target_path,
                              original_size, source_checksum, source_is_dir):
        # post-transfer checks
        if result != 0:
            print('ERROR: Copy from {}:{} to {}:{} failed'
                  .format(self.source_host, self.source_path, target_host, target_path))
            return 1

        target_final_path = os.path.join(os.path.normpath(target_path),
                                         os.path.basename(self.source_path))
        if not self.file_exists(target_host, target_final_path):
            print(('ERROR: file was not found on the target path {} after transfer'
                   ' to {}').format(target_final_path, target_host))
            return 2
        final_size = self.disk_usage(target_host, target_final_path)
        if original_size != final_size:
            print('WARNING: Original size is {} but transferred size is {} for'
                  ' copy to {}'.format(original_size, final_size, target_host))
        target_checksum = self.calculate_checksum(target_host, target_final_path,
                                                  is_dir=source_is_dir)
        if source_checksum != target_checksum:
            print('ERROR: Original checksum {} on {} is different than checksum {}'
                  ' on {}'.format(source_checksum, self.source_host, target_checksum,
                                  target_host))
            return 3
        else:
            print(('Checksum of all original files on {} and the trasmitted ones'
                   ' on {} match.').format(self.source_host, target_host))
        print('{} bytes correctly transferred from {} to {}'
              .format(final_size, self.source_host, target_host))
        return 0

    def run(self):
        """
        Transfers the file (or the directory and all its contents) given on
        source_path from the source_target machine to all target_hosts hosts, as
        fast as possible. Returns an array of exit codes, one per target host,
        indicating if the transfer was successful (0) or not (<> 0).
        """
        # pre-execution sanity checks
        result = self.sanity_checks()
        if result is None:
            return -1
        else:
            (source_is_dir, source_checksum, original_size) = result

        if source_is_dir:
            print('About to transfer {} directory and its contents from {} to'
                  ' {}:{} ({} bytes)'.format(self.source_path, self.source_host,
                                             self.target_hosts, self.target_paths,
                                             original_size))
        else:
            print('About to transfer {} file from {} to {}:{} ({} bytes)'
                  .format(self.source_path, self.source_host,
                          self.target_hosts, self.target_paths,
                          original_size))

        transfer_sucessful = []
        # actual transfer process- this is done serially until we implement a
        # multicast-like process
        for target_host, target_path in zip(self.target_hosts, self.target_paths):
            self.open_firewall(target_host, self.options['port'])
            if source_is_dir:
                result = self.copy_dir(target_host, target_path, self.options['port'])
            else:
                result = self.copy_file(target_host, target_path, self.options['port'])
            if self.close_firewall(target_host, self.options['port']) != 0:
                print('WARNING: Firewall\'s temporary rule could not be deleted')

            transfer_sucessful.append(self.after_transfer_checks(result,
                                                                 target_host,
                                                                 target_path,
                                                                 original_size,
                                                                 source_checksum,
                                                                 source_is_dir))

        return transfer_sucessful


def main():
    (source_host, source_path, target_hosts, target_paths,
     other_options) = option_parse()
    t = Transferer(source_host, source_path, target_hosts, target_paths, other_options)
    t.run()


if __name__ == "__main__":
    main()
