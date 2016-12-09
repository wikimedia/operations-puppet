#!/usr/bin/python3

from LocalExecution import LocalExecution as RemoteExecution
import argparse
import os
import os.path
import base64


def option_parse():
    """
    Parses the input parameters and returns them as a list.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-6")
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


def is_dir(host, path):
    command = ['/bin/bash', '-c', '[ -d "{}" ]'.format(path)]
    result = RemoteExecution().run(host, command)
    return not result.returncode


def file_exists(host, path):
    """
    Returns true if there is a file or a directory with such path on the remote
    host given
    """
    command = ['/bin/bash', '-c', '[ -a "{}" ]'.format(path)]
    result = RemoteExecution().run(host, command)
    return not result.returncode


def calculate_checksum(host, path, is_dir):

    hash_executable = '/usr/bin/md5sum'
    parent_dir = os.path.normpath(os.path.join(path, '..'))
    basename = os.path.basename(os.path.normpath(path))
    if is_dir:
        command = ['/bin/bash', '-c',
                   'cd {} && /usr/bin/find {} -type f -exec {} {}'
                   .format(parent_dir, basename, hash_executable, '\{\} \;')]
        result = RemoteExecution().run(host, command)
    else:
        command = ['/bin/bash', '-c', 'cd {} && {} {}'
                   .format(parent_dir, hash_executable, basename)]
        result = RemoteExecution().run(host, command)
    if result.returncode != 0:
        raise Exception('md5sum execution failed')
    return result.stdout


def has_available_disk_space(host, path, size):
    command = ['/bin/bash', '-c', ('df --block-size=1 --output=avail {} '
                                   '| /usr/bin/tail -n 1').format(path)]
    result = RemoteExecution().run(host, command)
    if result.returncode != 0:
        raise Exception('df execution failed')
    return int(result.stdout) > size


def disk_usage(host, path):
    """
    Returns the size used on the filesystem by the file path on the given host,
    or the aggregated size of all the files inside path and its subdirectories
    """
    command = ['/usr/bin/du', '--bytes', '--summarize', '{}'.format(path)]
    result = RemoteExecution().run(host, command)
    if result.returncode != 0:
        raise Exception('du execution failed')
    return int(result.stdout.split()[0])


def copy_file(source_host, source_path, target_host, target_path, port=4444,
              compression=True, encryption=True, password=None):
    """
    Copies a single regular file (source_path) from the source_host to the
    target_host. The final path of the file will be targetpath + / +
    basename(source_path); in other words, target_path is assumed to be a
    directory and the file will be copied inside. The target_path cannot be a
    complete file_name.
    """
    final_file = os.path.join(os.path.normpath(target_path),
                              os.path.basename(source_path))
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
        cipher = 'rc4'
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
    e = RemoteExecution()
    command = ['/bin/bash', '-c', '/bin/nc -l {} {} {} > {}'
               .format(port, decrypt_command, decompress_command, final_file)]
    job = e.start_job(target_host, command)
    command = ['/bin/bash', '-c', '{} < {} {} | /bin/nc {} {}'
               .format(compress_command, source_path, encrypt_command,
                       target_host, port)]
    result = RemoteExecution().run(source_host, command)
    if result.returncode != 0:
        e.kill_job(target_host, job)
    else:
        e.wait_job(target_host, job)
    return result.returncode


def copy_dir(source_host, source_path, target_host, target_path, port=4444,
             compression=True, encryption=True, password=None):
    """
    Copies a directory and, recursively, the files and subdirs it containts,
    from from the source_host to the target_host. The final path of the
    directory will be targetpath + / + basename(source_path); in other words,
    target_path is assumed to be a directory and the source_path will be copied
    inside -it will copy the directory itself, not only the contents.
    """
    source_parent_dir = os.path.normpath(os.path.join(source_path, '..'))
    source_basename = os.path.basename(os.path.normpath(source_path))
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
        cipher = 'rc4'
        encrypt_command = ('/usr/bin/openssl enc -{} -pass pass:{}'
                           ' -bufsize {} |'
                           ).format(cipher, password, buffer_size)
        decrypt_command = ('/usr/bin/openssl enc -d -{} -pass pass:{}'
                           ' -bufsize {} |'
                           ).format(cipher, password, buffer_size)
    else:
        encrypt_command = ''
        decrypt_command = ''

    e = RemoteExecution()
    command = ['/bin/bash', '-c', ('cd {} && /bin/nc -l {}'
                                   ' | {} {} /bin/tar xf -'
                                   ).format(target_path, port, decrypt_command,
                                            decompress_command)]
    job = e.start_job(target_host, command)
    command = ['/bin/bash', '-c', ('cd {} && /bin/tar cf - {}'
                                   ' | {} {} /bin/nc {} {}'
                                   ).format(source_parent_dir, source_basename,
                                            compress_command, encrypt_command,
                                            target_host, port)]
    result = RemoteExecution().run(source_host, command)
    if result.returncode != 0:
        e.kill_job(target_host, job)
    else:
        e.wait_job(target_host, job)
    return result.returncode


def open_firewall(source_host, target_host, port):
    command = ['/sbin/iptables', '-A', 'INPUT', '-p', 'tcp', '-s',
               '{}'.format(source_host), '--dport', '{}'.format(port), '-j',
               'ACCEPT']
    result = RemoteExecution().run(target_host, command)
    if result.returncode != 0:
        raise Exception('iptables execution failed')


def close_firewall(source_host, target_host, port):
    command = ['/sbin/iptables', '-D', 'INPUT', '-p', 'tcp', '-s',
               '{}'.format(source_host), '--dport', '{}'.format(port), '-j',
               'ACCEPT']
    result = RemoteExecution().run(target_host, command)
    return result.returncode


def sanity_checks(source_host, source_path, target_hosts, target_paths):
    source_path = os.path.normpath(source_path)
    if not file_exists(source_host, source_path):
        print("ERROR: The specified source path {} doesn't exist on {}"
              .format(source_path, source_host))
        return None
    original_size = disk_usage(source_host, source_path)
    for target_host, target_path in zip(target_hosts, target_paths):
        if not file_exists(target_host, target_path):
            print("ERROR: The specified target path {} doesn't exist on {}"
                  .format(target_path, target_host))
            return None
        target_final_path = os.path.join(os.path.normpath(target_path),
                                         os.path.basename(source_path))
        if file_exists(target_host, target_final_path):
            print("ERROR: The final target path {} already exists on {}."
                  .format(target_final_path, target_host))
            return None
        if not has_available_disk_space(target_host, target_path,
                                        original_size):
            print("ERROR: {} doesn't have enough space on {}"
                  .format(target_host, target_path))
            return None
    source_is_dir = is_dir(source_host, source_path)
    source_checksum = calculate_checksum(source_host, source_path,
                                         source_is_dir)
    return source_path, source_is_dir, source_checksum, original_size


def after_transfer_checks(result, source_host, source_path, target_host,
                          target_path, original_size, source_checksum,
                          source_is_dir):
    # post-transfer checks
    if result != 0:
        print('ERROR: Copy from {}:{} to {}:{} failed'
              .format(source_host, source_path, target_host, target_path))
        return 1

    target_final_path = os.path.join(os.path.normpath(target_path),
                                     os.path.basename(source_path))
    if not file_exists(target_host, target_final_path):
        print(('ERROR: file was not found on the target path {} after transfer'
               ' to {}').format(target_final_path, target_host))
        return 2
    final_size = disk_usage(target_host, target_final_path)
    if original_size != final_size:
        print('WARNING: Original size is {} but transferred size is {} for'
              ' copy to {}'.format(original_size, final_size, target_host))
    target_checksum = calculate_checksum(target_host, target_final_path,
                                         is_dir=source_is_dir)
    if source_checksum != target_checksum:
        print('ERROR: Original checksum {} on {} is different than checksum {}'
              ' on {}'.format(source_checksum, source_host, target_checksum,
                              target_host))
        return 3
    else:
        print(('Checksum of all original files on {} and the trasmitted ones'
               ' on {} match.').format(source_host, target_host))
    print('{} bytes correctly transferred from {} to {}'
          .format(final_size, source_host, target_host))
    return 0


def transfer(source_host, source_path, target_hosts, target_paths, options={}):
    """
    Transfers the file (or the directory and all its contents) given on
    source_path from the source_target machine to all target_hosts hosts, as
    fast as possible. Returns an array of exit codes, one per target host,
    indicating if the transfer was successful (0) or not (<> 0).
    """
    # pre-execution sanity checks
    result = sanity_checks(source_host, source_path, target_hosts,
                           target_paths)
    if result is None:
        return -1
    else:
        (source_path, source_is_dir, source_checksum, original_size) = result

    if source_is_dir:
        print('About to transfer {} directory and its contents from {} to'
              ' {}:{} ({} bytes)'.format(source_path, source_host,
                                         target_hosts, target_paths,
                                         original_size))
    else:
        print('About to transfer {} file from {} to {}:{} ({} bytes)'
              .format(source_path, source_host, target_hosts, target_paths,
                      original_size))

    transfer_sucessful = []
    # actual transfer process- this is done serially until we implement a
    # multicast-like process
    for target_host, target_path in zip(target_hosts, target_paths):
        open_firewall(source_host, target_host, options['port'])
        if source_is_dir:
            result = copy_dir(source_host, source_path, target_host,
                              target_path, options['port'])
        else:
            result = copy_file(source_host, source_path, target_host,
                               target_path, options['port'])
        if close_firewall(source_host, target_host, options['port']) != 0:
            print('WARNING: Firewall\'s temporary rule could not be deleted')

        transfer_sucessful.append(after_transfer_checks(result,
                                                        source_host,
                                                        source_path,
                                                        target_host,
                                                        target_path,
                                                        original_size,
                                                        source_checksum,
                                                        source_is_dir))

    return transfer_sucessful


def main():
    (source_host, source_path, target_hosts, target_paths,
     other_options) = option_parse()
    return transfer(source_host, source_path, target_hosts, target_paths,
                    other_options)


if __name__ == "__main__":
    main()
