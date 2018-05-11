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

    compress_group = parser.add_mutually_exclusive_group()
    compress_group.add_argument('--compress', action='store_true', dest='compress')
    compress_group.add_argument('--no-compress', action='store_false', dest='compress')
    parser.set_defaults(compress=True)

    encrypt_group = parser.add_mutually_exclusive_group()
    encrypt_group.add_argument('--encrypt', action='store_true', dest='encrypt')
    encrypt_group.add_argument('--no-encrypt', action='store_false', dest='encrypt')
    parser.set_defaults(encrypt=True)

    options = parser.parse_args()
    source_host = options.source.split(':', 1)[0]
    source_path = options.source.split(':', 1)[1]
    target_hosts = []
    target_paths = []
    for target in options.target:
        target_hosts.append(target.split(':', 1)[0])
        target_paths.append(target.split(':', 1)[1])
    other_options = {
        'port': options.port,
        'compress': options.compress,
        'encrypt': options.encrypt
    }
    return source_host, source_path, target_hosts, target_paths, other_options


class Transferer(object):
    def __init__(self, source_host, source_path, target_hosts, target_paths, options={}):
        self.source_host = source_host
        self.source_path = source_path
        self.target_hosts = target_hosts
        self.target_paths = target_paths
        self.options = options

        self.remote_executor = RemoteExecution()

        self.source_is_dir = False
        self.original_size = 0
        self.checksum = None

        self._password = None
        self.cipher = 'chacha20'
        self.buffer_size = 8

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

    def calculate_checksum(self, host, path):
        hash_executable = '/usr/bin/md5sum'
        parent_dir = os.path.normpath(os.path.join(path, '..'))
        basename = os.path.basename(os.path.normpath(path))
        if self.source_is_dir:
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

    @property
    def compress_command(self):
        if self.options['compress']:
            if self.source_is_dir:
                compress_command = '| /usr/bin/pigz -c'
            else:
                compress_command = '/usr/bin/pigz -c'
        else:
            if self.source_is_dir:
                compress_command = ''
            else:
                compress_command = '/bin/cat'

        return compress_command

    @property
    def decompress_command(self):
        if self.options['compress']:
            decompress_command = '| /usr/bin/pigz -c -d'
        else:
            decompress_command = ''

        return decompress_command

    @property
    def password(self):
        if self._password is None:
            self._password = base64.b64encode(os.urandom(24)).decode('utf-8')

        return self._password

    @property
    def encrypt_command(self):
        if self.options['encrypt']:
            encrypt_command = ('| /usr/bin/openssl enc -{}'
                               ' -pass pass:{} -bufsize {}').format(self.cipher,
                                                                    self.password,
                                                                    self.buffer_size)
        else:
            encrypt_command = ''

        return encrypt_command

    @property
    def decrypt_command(self):
        if self.options['encrypt']:
            decrypt_command = ('| /usr/bin/openssl enc -d -{}'
                               ' -pass pass:{} -bufsize {}').format(self.cipher,
                                                                    self.password,
                                                                    self.buffer_size)
        else:
            decrypt_command = ''

        return decrypt_command

    def copy_to(self, target_host, target_path):
        """
        Copies the source file or dir on the source host to 'target_host'.
        'target_path' is assumed to be a *directory* and the source file or
        directory will be copied inside.
        """

        if self.source_is_dir:
            source_parent_dir = os.path.normpath(os.path.join(self.source_path, '..'))
            source_basename = os.path.basename(os.path.normpath(self.source_path))
            src_command = ['/bin/bash', '-c', r'"cd {} && /bin/tar cf - {} {} {} | /bin/nc -q 0 {} {}"'
                           .format(source_parent_dir, source_basename,
                                   self.compress_command, self.encrypt_command,
                                   target_host, self.options['port'])]

            dst_command = ['/bin/bash', '-c', r'"cd {} && /bin/nc -l -p {} {} {} | /bin/tar xf -"'
                           .format(target_path, self.options['port'],
                                   self.decrypt_command, self.decompress_command)]
        else:
            src_command = ['/bin/bash', '-c', r'"{} < {} {} | /bin/nc -q 0 {} {}"'
                           .format(self.compress_command, self.source_path, self.encrypt_command,
                                   target_host, self.options['port'])]

            final_file = os.path.join(os.path.normpath(target_path),
                                      os.path.basename(self.source_path))
            dst_command = ['/bin/bash', '-c', r'"/bin/nc -l -p {} {} {} > {}"'
                           .format(self.options['port'], self.decrypt_command,
                                   self.decompress_command, final_file)]

        job = self.remote_executor.start_job(target_host, dst_command)
        import time; time.sleep(1)  # FIXME: Work on a better way to wait for nc to be listening
        result = self._run(self.source_host, src_command)
        if result.returncode != 0:
            self.remote_executor.kill_job(target_host, job)
        else:
            self.remote_executor.wait_job(target_host, job)
        return result.returncode

    def open_firewall(self, target_host):
        command = ['/sbin/iptables', '-A', 'INPUT', '-p', 'tcp', '-s',
                   '{}'.format(self.source_host),
                   '--dport', '{}'.format(self.options['port']),
                   '-j', 'ACCEPT']
        result = self._run(target_host, command)
        if result.returncode != 0:
            raise Exception('iptables execution failed')

    def close_firewall(self, target_host):
        command = ['/sbin/iptables', '-D', 'INPUT', '-p', 'tcp', '-s',
                   '{}'.format(self.source_host),
                   '--dport', '{}'.format(self.options['port']),
                   '-j', 'ACCEPT']
        result = self._run(target_host, command)
        return result.returncode

    def sanity_checks(self):
        self.source_path = os.path.normpath(self.source_path)
        if not self.file_exists(self.source_host, self.source_path):
            raise ValueError("The specified source path {} doesn't exist on {}"
                             .format(self.source_path, self.source_host))
        self.original_size = self.disk_usage(self.source_host, self.source_path)
        for target_host, target_path in zip(self.target_hosts, self.target_paths):
            if not self.file_exists(target_host, target_path):
                raise ValueError("The specified target path {} doesn't exist on {}"
                                 .format(target_path, target_host))
            target_final_path = os.path.join(os.path.normpath(target_path),
                                             os.path.basename(self.source_path))
            if self.file_exists(target_host, target_final_path):
                raise ValueError("The final target path {} already exists on {}."
                                 .format(target_final_path, target_host))
            if not self.has_available_disk_space(target_host, target_path,
                                                 self.original_size):
                raise ValueError("{} doesn't have enough space on {}"
                                 .format(target_host, target_path))

        self.source_is_dir = self.is_dir(self.source_host, self.source_path)
        self.checksum = self.calculate_checksum(self.source_host, self.source_path)

    def after_transfer_checks(self, result, target_host, target_path):
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
        if self.original_size != final_size:
            print('WARNING: Original size is {} but transferred size is {} for'
                  ' copy to {}'.format(self.original_size, final_size, target_host))
        target_checksum = self.calculate_checksum(target_host, target_final_path)
        if self.checksum != target_checksum:
            print('ERROR: Original checksum {} on {} is different than checksum {}'
                  ' on {}'.format(self.checksum, self.source_host, target_checksum,
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
        try:
            self.sanity_checks()
        except ValueError as e:
            print("ERROR: {}".format(str(e)))
            return -1

        print('About to transfer {} from {} to {}:{} ({} bytes)'
              .format(self.source_path, self.source_host,
                      self.target_hosts, self.target_paths,
                      self.original_size))

        transfer_sucessful = []
        # actual transfer process- this is done serially until we implement a
        # multicast-like process
        for target_host, target_path in zip(self.target_hosts, self.target_paths):
            self.open_firewall(target_host)

            result = self.copy_to(target_host, target_path)

            if self.close_firewall(target_host) != 0:
                print('WARNING: Firewall\'s temporary rule could not be deleted')

            transfer_sucessful.append(self.after_transfer_checks(result,
                                                                 target_host,
                                                                 target_path))

        return transfer_sucessful


def main():
    (source_host, source_path, target_hosts, target_paths, other_options) = option_parse()
    t = Transferer(source_host, source_path, target_hosts, target_paths, other_options)
    t.run()


if __name__ == "__main__":
    main()
