#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# On a puppetmaster, renew CA and certificates for mcrouter.
import datetime
import logging
import pathlib
import shlex
import shutil
import subprocess
import sys
import tempfile

import git  # type: ignore
from cryptography import x509
from cryptography.hazmat import backends
from OpenSSL import crypto  # type: ignore

MCROUTER_PATH = pathlib.Path('/srv/private/modules/secret/secrets/mcrouter')
MANIFESTS_PATH = pathlib.Path('/etc/cergen/mcrouter.manifests.d')

logger = logging.getLogger(__name__)


class Error(BaseException):
    pass


class PreconditionError(Error):
    """Something was in an unexpected state before we started, so everything is untouched."""
    pass


class ExecutionError(Error):
    """After we started, something didn't work correctly, so we're leaving the work half-done."""
    # TODO: This always requires manual intervention for now, since we'll want to troubleshoot the
    #  script anyway so it's useful to see where it got stuck. In future, we'll automate the
    #  rollback too (but send an alert), so this can run unattended.
    pass


def run(command: str, **kwargs) -> subprocess.CompletedProcess:
    """
    Convenience wrapper for subprocess.run that takes a string instead of a list of args.

    The command is split using shlex, but not run through an actual shell. check=True is set, so
    subprocess.CalledProcessError is raised if the exit status is nonzero.
    """
    return subprocess.run(shlex.split(command), check=True, **kwargs)


def ensure_git_clean():
    """
    Ensure MCROUTER_PATH is in a git repo, `git status` is clean (no files modified, staged, or
    untracked) and the master branch is checked out.

    Raises PreconditionError if any of those conditions isn't true.
    """
    try:
        repo = git.Repo(str(MCROUTER_PATH), search_parent_directories=True)
    except git.InvalidGitRepositoryError:
        raise PreconditionError(f'{MCROUTER_PATH} is not in a git repository.')
    if 'master' not in repo.heads or repo.head.ref != repo.heads.master:
        raise PreconditionError(f'Branch master is not checked out at {repo.working_tree_dir}.')
    if repo.is_dirty(untracked_files=True):
        raise PreconditionError(f'Modified/untracked files under {repo.working_tree_dir}.')


def sample_host() -> str:
    """
    Choose a sample mcrouter host.

    Returns a FQDN that exists as a subdirectory of MCROUTER_PATH, e.g. 'mw1295.eqiad.wmnet'.
    """
    for item in MCROUTER_PATH.iterdir():
        if item.is_dir() and item.name != 'mcrouter_ca':
            return item.name
    raise FileNotFoundError(f'No certs found under {MCROUTER_PATH}.')


def verify(ca_path: pathlib.Path, cert_path: pathlib.Path) -> None:
    """
    Run `openssl verify` to check the given cert with the given CA.

    Raises ExecutionError if verification fails (`openssl verify` exits with nonzero status).
    """

    # TODO: It would be better to use the cryptography library for both this and check_date(), but
    #  it doesn't have this feature yet (https://github.com/pyca/cryptography/issues/2381) so we're
    #  using pyopenssl for now.
    with open(ca_path, 'rb') as ca_file:
        ca_cert = crypto.load_certificate(crypto.FILETYPE_PEM, ca_file.read())

    with open(cert_path, 'rb') as cert_file:
        cert = crypto.load_certificate(crypto.FILETYPE_PEM, cert_file.read())

    try:
        store = crypto.X509Store()
        store.add_cert(ca_cert)
        context = crypto.X509StoreContext(store, cert)
        context.verify_certificate()
    except crypto.X509StoreContextError:
        raise ExecutionError(f'Failed to verify {cert_path} with CA {ca_path}.')


def check_date(cert_path: pathlib.Path) -> None:
    """
    Ensure the start and expiry dates of the given cert are reasonable. "Reasonable" means that the
    cert is valid now, but invalid yesterday, and invalid just over a year in the future.

    Raises ExecutionError if the dates aren't reasonable.
    """
    with open(cert_path, 'rb') as f:
        cert = x509.load_pem_x509_certificate(f.read(), backends.default_backend())

    past = datetime.datetime.utcnow() - datetime.timedelta(days=1)
    present = datetime.datetime.utcnow()
    future = datetime.datetime.utcnow() + datetime.timedelta(days=366)

    if not (past < cert.not_valid_before < present):
        raise ExecutionError(f'notBefore date for {cert_path} is wrong: {cert.not_valid_before}')
    if not (present < cert.not_valid_after < future):
        raise ExecutionError(f'notAfter date for {cert_path} is wrong: {cert.not_valid_after}.')


def main() -> int:
    logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s', level=logging.INFO)

    # Ensure git status is starting clean.
    try:
        ensure_git_clean()
    except PreconditionError as e:
        logger.critical(e)
        return 1

    # Save a copy of the current mcrouter tree under /tmp, so that we can cross-verify the old and
    # new CA and host certs.
    temp_dir = pathlib.Path(tempfile.mkdtemp(prefix='mcrouter-'))
    old_mcrouter_path = temp_dir / 'mcrouter'
    logger.info(f'Copying {MCROUTER_PATH} to: {old_mcrouter_path}')
    shutil.copytree(MCROUTER_PATH, old_mcrouter_path)

    # Save a copy of the current hosts yaml too, before mcrouter_generate_certs rewrites it.
    hosts_yaml = MANIFESTS_PATH / 'mediawiki-hosts.certs.yaml'
    run(f'sudo cp {hosts_yaml} {temp_dir}')

    try:
        # Delete the current public certs. We don't `git rm` them because we'll recreate them all
        # next, so from git's perspective each file gets edited, not deleted.
        logger.info(f'Deleting public certs from {MCROUTER_PATH}...')
        for filename in MCROUTER_PATH.glob('*/*.crt.pem'):
            run(f'sudo rm {filename}')

        # This could import mcrouter_generator as a library instead of forking, but then this whole
        # script would have to be run as root.
        logger.info('Regenerating cergen yaml files, then regenerating certs...')
        run(f'sudo mcrouter_generate_certs --generate --base-path {MCROUTER_PATH} '
            f'--manifests-path {MANIFESTS_PATH}')

        logger.info('Verifying new host certs with old CA...')
        host = sample_host()
        try:
            verify(old_mcrouter_path / 'mcrouter_ca' / 'ca.crt.pem',
                   MCROUTER_PATH / host / f'{host}.crt.pem')
        except ExecutionError:
            # Raise with a better message.
            raise ExecutionError('Verifying new host certs with old CA failed.')

        logger.info('Verifying old host certs with new CA...')
        try:
            verify(MCROUTER_PATH / 'mcrouter_ca' / 'ca.crt.pem',
                   old_mcrouter_path / host / f'{host}.crt.pem')
        except ExecutionError:
            raise ExecutionError('Verifying old host certs with new CA failed.')

        logger.info("Checking the CA cert's start and expiry date...")
        check_date(MCROUTER_PATH / 'mcrouter_ca' / 'ca.crt.pem')

        logger.info("Checking the host certs' start and expiry date...")
        check_date(MCROUTER_PATH / host / f'{host}.crt.pem')

        logger.info('New certs look good. Committing...')
        run('sudo git add .', cwd=MCROUTER_PATH)
        # The commit-msg hook in /srv/private will prepend $SUDO_USER -- that is, the username that
        # ran this script -- so we don't include it in our commit message.
        message = 'mcrouter: Renew CA and certificates\n\nAutomated by renew_mcrouter_certs.py.'
        run(f'sudo git commit -m "{message}"', cwd=MCROUTER_PATH)
    except ExecutionError as e:
        logger.critical(e)
        logger.error(f"Stopping. {MCROUTER_PATH} may have uncommitted changes. You can clean them "
                     f"up with `git reset --hard` or restore from {old_mcrouter_path} which is a "
                     f"copy of the original state. If you manually validate the new certs and find "
                     f"that they're good, you can commit the changes instead. Either way, you "
                     f"should remove {temp_dir} when you're finished.")
        # TODO: Delete the temp copy. For now, it's convenient to leave it for debugging.
        return 1

    # Delete our temp copy of the mcrouter directory. Nothing is lost, since the original state is
    # still preserved in git history.
    logger.info(f'Cleaning up {temp_dir}...')
    shutil.rmtree(temp_dir)
    return 0


if __name__ == '__main__':
    sys.exit(main())
