#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import argparse
import grp
import logging
import os
import pwd
import sqlite3
import tempfile
import time
from pathlib import Path
from shutil import copyfile

DEFAULT_RSPAMD_DATA_DIR = Path('/var/lib/rspamd')
DEFAULT_RSPAMD_BACKUP_DIR = Path('/var/lib/rspamd/backup')
DEFAULT_PROM_TEXT_EXPORTER_DIR = Path('/var/lib/prometheus/node.d')
RSPAMD_USER = '_rspamd'
RSPAMD_GROUP = '_rspamd'
SQLITE_BACKUP_SUFFIX = '.backup'
SQLITE_SIDE_SUFFIXES = ('-wal', '-shm')

log = logging.getLogger('rspamd_sqlite_backup')


def configure_logging() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s %(levelname)s: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
    )


def file_mode(value: str) -> int:
    try:
        return int(value, 8)
    except ValueError as error:
        raise argparse.ArgumentTypeError('must be an octal file mode, e.g. 0640') from error


def sqlite_readonly_uri(path: Path) -> str:
    return f'file:{path}?mode=ro'


def backup_path_for(sqlite_path: Path, backup_dir: Path) -> Path:
    return backup_dir / f'{sqlite_path.name}{SQLITE_BACKUP_SUFFIX}'


def backup_sqlite_database(source_path: Path, backup_path: Path) -> None:
    backup_path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(
        prefix=f'.{backup_path.name}.',
        suffix='.tmp',
        dir=str(backup_path.parent),
    )
    os.close(fd)
    tmp_path = Path(tmp_name)

    try:
        log.info('backing up rspamd sqlite database %s to %s', source_path, backup_path)
        source_conn = None
        backup_conn = None
        try:
            source_conn = sqlite3.connect(sqlite_readonly_uri(source_path), uri=True, timeout=30)
            backup_conn = sqlite3.connect(str(tmp_path), timeout=30)
            source_conn.backup(backup_conn)
        finally:
            if backup_conn is not None:
                backup_conn.close()
            if source_conn is not None:
                source_conn.close()
        tmp_path.chmod(0o644)
        tmp_path.replace(backup_path)
    except Exception:
        tmp_path.unlink(missing_ok=True)
        raise


def backup_rspamd_databases(source_dir: Path, backup_dir: Path) -> int:
    if not source_dir.is_dir():
        raise RuntimeError(f'rspamd data directory does not exist: {source_dir}')

    sqlite_sources = sorted(path for path in source_dir.glob('*.sqlite') if path.is_file())
    expected_backup_names = {
        backup_path_for(path, backup_dir).name
        for path in sqlite_sources
    }

    if not sqlite_sources:
        log.warning('no rspamd sqlite databases found in %s', source_dir)
        return 0

    for source_path in sqlite_sources:
        backup_sqlite_database(source_path, backup_path_for(source_path, backup_dir))

    for stale_path in backup_dir.glob(f'*{SQLITE_BACKUP_SUFFIX}'):
        if stale_path.name not in expected_backup_names:
            log.info('removing stale rspamd sqlite backup %s', stale_path)
            stale_path.unlink()

    log.info(
        'rspamd backup complete: %s sqlite database(s) written to %s',
        len(sqlite_sources),
        backup_dir,
    )
    return len(sqlite_sources)


def remove_sqlite_sidecars(sqlite_path: Path) -> None:
    for suffix in SQLITE_SIDE_SUFFIXES:
        Path(f'{sqlite_path}{suffix}').unlink(missing_ok=True)


def restore_sqlite_backup(
    backup_path: Path,
    target_dir: Path,
    uid: int,
    gid: int,
    mode: int,
) -> None:
    if not backup_path.name.endswith(SQLITE_BACKUP_SUFFIX):
        raise RuntimeError(f'invalid rspamd sqlite backup name: {backup_path}')

    sqlite_name = backup_path.name[:-len(SQLITE_BACKUP_SUFFIX)]
    target_path = target_dir / sqlite_name
    target_path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(
        prefix=f'.{target_path.name}.',
        suffix='.tmp',
        dir=str(target_path.parent),
    )
    os.close(fd)
    tmp_path = Path(tmp_name)

    try:
        log.info('restoring rspamd sqlite backup %s to %s', backup_path, target_path)
        copyfile(backup_path, tmp_path)
        os.chown(tmp_path, uid, gid)
        tmp_path.chmod(mode)
        remove_sqlite_sidecars(target_path)
        tmp_path.replace(target_path)
        remove_sqlite_sidecars(target_path)
    except Exception:
        tmp_path.unlink(missing_ok=True)
        raise


def restore_rspamd_backups(
    backup_dir: Path,
    target_dir: Path,
    owner: str,
    group: str,
    mode: int,
) -> int:
    if not backup_dir.is_dir():
        log.warning('no rspamd backup directory found at %s', backup_dir)
        return 0

    backup_paths = sorted(backup_dir.glob(f'*.sqlite{SQLITE_BACKUP_SUFFIX}'))
    if not backup_paths:
        log.warning('no rspamd sqlite backups found in %s', backup_dir)
        return 0

    uid = pwd.getpwnam(owner).pw_uid
    gid = grp.getgrnam(group).gr_gid

    for backup_path in backup_paths:
        restore_sqlite_backup(backup_path, target_dir, uid, gid, mode)

    log.info(
        'rspamd restore complete: %s sqlite database(s) restored to %s',
        len(backup_paths),
        target_dir,
    )
    return len(backup_paths)


def write_prometheus_metrics(
    prom_text_exporter_dir: Path,
    operation: str,
    success: bool,
    file_count: int,
    duration_seconds: float,
) -> None:
    prom_text_exporter_dir.mkdir(parents=True, exist_ok=True)
    metrics_path = prom_text_exporter_dir / f'vrts_rspamd_sqlite_{operation}.prom'
    tmp_path = metrics_path.with_name(f'.{metrics_path.name}.tmp')
    status_value = 1 if success else 0
    timestamp = time.time()
    lines = [
        '# HELP vrts_rspamd_sqlite_last_run_success '
        'Whether the last Rspamd sqlite backup operation succeeded',
        '# TYPE vrts_rspamd_sqlite_last_run_success gauge',
        f'vrts_rspamd_sqlite_last_run_success{{operation="{operation}"}} {status_value}',
        '# HELP vrts_rspamd_sqlite_last_run_files '
        'Number of sqlite files handled by the last Rspamd sqlite backup operation',
        '# TYPE vrts_rspamd_sqlite_last_run_files gauge',
        f'vrts_rspamd_sqlite_last_run_files{{operation="{operation}"}} {file_count}',
        '# HELP vrts_rspamd_sqlite_last_run_duration_seconds '
        'Duration of the last Rspamd sqlite backup operation',
        '# TYPE vrts_rspamd_sqlite_last_run_duration_seconds gauge',
        'vrts_rspamd_sqlite_last_run_duration_seconds'
        f'{{operation="{operation}"}} {duration_seconds:.6f}',
        '# HELP vrts_rspamd_sqlite_last_run_timestamp_seconds '
        'Unix timestamp of the last Rspamd sqlite backup operation',
        '# TYPE vrts_rspamd_sqlite_last_run_timestamp_seconds gauge',
        f'vrts_rspamd_sqlite_last_run_timestamp_seconds{{operation="{operation}"}} {timestamp}',
    ]
    tmp_path.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    tmp_path.replace(metrics_path)
    log.info('wrote prometheus metrics to %s', metrics_path)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description='Backup and restore VRTS Rspamd sqlite data.')
    subparsers = parser.add_subparsers(dest='command', required=True)
    metrics_parser = argparse.ArgumentParser(add_help=False)
    metrics_parser.add_argument(
        '--prom-text-exporter-dir',
        type=Path,
        default=DEFAULT_PROM_TEXT_EXPORTER_DIR,
    )

    backup_parser = subparsers.add_parser('backup', parents=[metrics_parser])
    backup_parser.add_argument('--source-dir', type=Path, default=DEFAULT_RSPAMD_DATA_DIR)
    backup_parser.add_argument('--backup-dir', type=Path, default=DEFAULT_RSPAMD_BACKUP_DIR)

    restore_parser = subparsers.add_parser('restore', parents=[metrics_parser])
    restore_parser.add_argument('--backup-dir', type=Path, default=DEFAULT_RSPAMD_BACKUP_DIR)
    restore_parser.add_argument('--target-dir', type=Path, default=DEFAULT_RSPAMD_DATA_DIR)
    restore_parser.add_argument('--owner', default=RSPAMD_USER)
    restore_parser.add_argument('--group', default=RSPAMD_GROUP)
    restore_parser.add_argument('--mode', type=file_mode, default=0o640)

    return parser.parse_args()


def main() -> int:
    configure_logging()
    args = parse_args()
    start_time = time.time()
    success = False
    file_count = 0

    try:
        if args.command == 'backup':
            file_count = backup_rspamd_databases(args.source_dir, args.backup_dir)
        elif args.command == 'restore':
            file_count = restore_rspamd_backups(
                args.backup_dir,
                args.target_dir,
                args.owner,
                args.group,
                args.mode,
            )
        else:
            raise RuntimeError(f'unknown command: {args.command}')
        success = True
        return 0
    except Exception:
        log.exception('rspamd sqlite %s failed', args.command)
        return 1
    finally:
        duration_seconds = time.time() - start_time
        try:
            write_prometheus_metrics(
                args.prom_text_exporter_dir,
                args.command,
                success,
                file_count,
                duration_seconds,
            )
        except Exception:
            log.exception('failed to write prometheus metrics')


if __name__ == '__main__':
    raise SystemExit(main())
