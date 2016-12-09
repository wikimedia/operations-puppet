#!/usr/bin/python3

import argparse
import os.path
import subprocess

def option_parse():
    """
    Parses the input parameters and returns them as a list.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("-6")
    parser.add_argument("source")
    parser.add_argument("target", nargs='+')
    options = parser.parse_args()
    source_host = options.source.split(':', 1)[0]
    source_path = options.source.split(':', 1)[1]
    target_hosts = []
    for target in options.target:
        target_hosts.append(target.split(':', 1)[0])
    target_path = options.target[0].split(':', 1)[1]
    other_options = []
    return source_host, source_path, target_hosts, target_path, other_options


def remote_execute(host, command):
    """
    Executes command on the remote host indicated and returns its exit code,
    the standard output and the error output. This is supposed to be used for
    commands that do not produce too much output.
    """
    #TODO: Use salt instead for actual remote execution
    result = subprocess.run(command, stdout=subprocess.PIPE)
    return result.returncode, result.stdout, result.stderr


def is_dir(host, path):
    (returncode, stdout, stderr) = remote_execute(host, ['/bin/bash', '-c', '[ -d "{}" ]'.format(path)])
    return not returncode


def file_exists(host, path):
    """
    Returns true if there is a file or a directory with such path on the remote
    host given
    """
    (returncode, stdout, stderr) = remote_execute(host, ['/bin/bash', '-c', '[ -a "{}" ]'.format(path)])
    return not returncode


def disk_usage(host, path):
    """
    Returns the size used on the filesystem by the file path on the given host,
    or the aggregated size of all the files inside path and its subdirectories
    """
    (returncode, stdout, stderr) = remote_execute(host, ['/usr/bin/du', '--bytes', '--summarize', '{}'.format(path)])
    return int(stdout.split()[0])

def copy_file(source_host, source_path, target_host, target_path):
    """
    Copies a single regular file (source_path) from the source_host to the
    target_host. The final path of the file will be targetpath + / +
    basename(source_path); in other words, target_path is assumed to be a
    directory and the file will be copied inside. The target_path cannot be a
    complete file_name.
    """
    (returncode, stdout, stderr) = remote_execute(source_host, ['/bin/cp', '{}'.format(source_path), '{}'.format(target_path)])
    return returncode

def copy_dir(source_host, source_path, target_host, target_path):
    """
    Copies a directory and, recursively, the files and subdirs it containts,
    from from the source_host to the target_host. The final path of the
    directory will be targetpath + / + basename(source_path); in other words,
    target_path is assumed to be a directory and the source_path will be copied
    inside -it will copy the directory itself, not only the contents.
    """
        (returncode, stdout, stderr) = remote_execute(source_host, ['/bin/cp', '--recursive', '--archive', '{}'.format(source_path), '{}'.format(target_path)])
    return returncode


def transfer(source_host, source_path, target_hosts, target_path, options):
    """
    Transfers the file (or the directory and all its contents) given on
    source_path from the source_target machine to all target_hosts hosts, as
    fast as possible. 
    """
    # Sanity checks
    source_path = os.path.normpath(source_path)
    target_path = os.path.normpath(target_path)
    if not file_exists(source_host, source_path):
        print("ERROR: The specified source path {} doesn't exist on {}".format(source_path, source_host))
        return 1
    for target_host in target_hosts:
        if not file_exists(target_host, target_path):
            print("ERROR: The specified target path {} doesn't exist on {}".format(target_path, target_host))
            return 2
        target_final_path = os.path.join(target_path, os.path.basename(source_path))
        if file_exists(target_host, target_final_path):
            print("ERROR: The final target path {} already exists on {}. Copy was aborted there.".format(target_final_path, target_host))
            return 3

    original_size = disk_usage(source_host, source_path)
    source_is_dir = is_dir(source_host, source_path)

    # actual transfer process
    if source_is_dir:
        print('About to transfer {} directory and its contents from {} to {}:{} ({} bytes)'.format(source_path, source_host, target_hosts, target_path, original_size))
    else:
        print('About to transfer {} file from {} to {}:{} ({} bytes)'.format(source_path, source_host, target_hosts, target_path, original_size))

    # post-tranfer checks
    for target_host in target_hosts:
        if source_is_dir:
            result = copy_dir(source_host, source_path, target_host, target_path)
        else:
            result = copy_file(source_host, source_path, target_host, target_path)
        if result > 0:
            print('ERROR: Copy from {}:{} to {}:{} failed'.format(source_host, source_path, target_host, target_path))
            continue

        target_final_path = os.path.join(target_path, os.path.basename(source_path))
        if not file_exists(target_host, target_final_path):
            print('ERROR: file was not found on the target path {} after transfer to {}'.format(target_final_path, target_host))
            continue
        final_size = disk_usage(target_host, target_final_path)
        if original_size == final_size:
            print('{} bytes correctly transferred from {} to {}'.format(final_size, source_host, target_host))
        else:
            print('ERROR: Original size is {} but transferred size is {} for copy to {}'.format(original_size, final_size, target_host))
            continue

    return 0


def main():
    (source_host, source_path, target_hosts, target_path, other_options) = option_parse()    
    return transfer(source_host, source_path, target_hosts, target_path, other_options)


if __name__ == "__main__":
    main()
