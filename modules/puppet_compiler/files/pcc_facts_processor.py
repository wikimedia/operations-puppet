#!/usr/bin/env python3
"""example script"""

import logging
import re
import shutil
import tarfile
import tempfile

from argparse import ArgumentParser, Namespace
from pathlib import Path

import pypuppetdb
import requests

from puppet_compiler import prepare
from puppet_compiler.config import ControllerConfig
from puppet_compiler.populate_puppetdb import populate_node, setup_environment


def get_args() -> Namespace:
    """Parse arguments"""
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-u', '--upload-dir', type=Path, default='/srv/pcc_uploader')
    parser.add_argument('-w', '--webroot-dir', type=Path, default='/srv/www/facts')
    parser.add_argument(
        '-c', '--config', type=Path, default='/etc/puppet-compiler.conf'
    )
    # TODO: im not sure if --all ever makes sense???
    parser.add_argument('-a', '--all', action='store_true')
    parser.add_argument('-v', '--verbose', action='count')
    return parser.parse_args()


def get_log_level(args_level: int) -> int:
    """Configure logging"""
    return {
        None: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG,
    }.get(args_level, logging.DEBUG)


def update_puppetdb(facts_dir: Path, config: ControllerConfig) -> None:
    """Update puppetdb with node facts"""
    tmpdir = tempfile.mkdtemp(prefix=__name__)
    environment = 'production' if facts_dir.name == 'production' else 'labs'
    managecode = setup_environment(tmpdir, config)
    srcdir = managecode.prod_dir / "src"
    pdb = pypuppetdb.connect()
    with prepare.pushd(srcdir):
        managecode._copy_hiera(  # pylint: disable=protected-access
            managecode.prod_dir, environment
        )
        managecode._create_puppetconf(  # pylint: disable=protected-access
            managecode.prod_dir, environment
        )
        for fact_file in facts_dir.glob('**/*.yaml'):
            node = fact_file.with_suffix('').name
            try:
                pdb.node(node)
                logging.debug('skipping node: %s', node)
                continue
            except requests.exceptions.HTTPError:
                # dont have info yet
                pass
            populate_node(node, config)
    shutil.rmtree(tmpdir)


def process_tar(tar_file: Path, config: ControllerConfig, realm: str) -> bool:
    """Unpack and process all facts files in a tar"""
    logging.debug('processing tar: %s', tar_file)
    facts_dir = config.puppet_var / 'yaml' / realm
    tar = tarfile.open(tar_file)
    matcher = re.compile(
        r'^yaml(\/facts(\/[a-z-\d\.]+\.(wmnet|wikimedia.(cloud|org)|wmflabs)\.yaml)?)?$',
        re.IGNORECASE,
    )
    for name in tar.getnames():
        logging.debug('checking: %s', name)
        if not matcher.match(name):
            logging.error('%s: tar file contains invalid files', tar_file)
            return False
    # TODO: Make the following less racy
    if facts_dir.is_dir():
        logging.debug('%s: remove', facts_dir)
        shutil.rmtree(facts_dir)
    logging.debug('%s: create', facts_dir)
    facts_dir.mkdir()
    logging.debug('%s: extract', tar)
    tar.extractall(facts_dir)
    update_puppetdb(facts_dir, config)
    return True


def update_webroot(tar_file: Path, dst_file: Path) -> None:
    """Move the tar file to the webroot for other clients to easily download"""
    logging.debug('copy: %s -> %s', tar_file, dst_file)
    if not dst_file.parent.is_dir():
        logging.error("%s: directory doesn't exist cant copy facts", dst_file.parent)
    # TODO: python 3.8 use missing_ok=True
    if dst_file.exists():
        dst_file.unlink()
    tar_file.rename(dst_file)


def process_dir(
    directory: Path, process_all: bool, config: ControllerConfig, webroot_dir: Path
) -> None:
    """process facts in a directory"""
    logging.debug('processing dir: %s', directory)
    tar_files = sorted(
        directory.glob('*.tar.xz'), key=lambda path: path.stat().st_mtime, reverse=True
    )
    # This is used to process the most recent working tar ball
    allowd_idx = 0
    for idx, tar_file in enumerate(tar_files):
        if process_all or idx == allowd_idx:
            if not process_tar(tar_file, config, directory.name):
                allowd_idx += 1
            else:
                update_webroot(tar_file, webroot_dir / f'{directory.name}_facts.tar.gz')
                continue
        logging.debug('delete tar file: %s', tar_file)
        tar_file.unlink()


def main():
    """main entry point"""
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    config = ControllerConfig.from_file(args.config, dict())
    for sub_dir in args.upload_dir.iterdir():
        if sub_dir.is_dir():
            process_dir(sub_dir, args.all, config, args.webroot_dir)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
