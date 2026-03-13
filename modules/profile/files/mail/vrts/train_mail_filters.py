#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import argparse
import fcntl
import logging
import logging.handlers
import mailbox
import subprocess
import sys
import time
from email import policy
from pathlib import Path
from shutil import chown
from typing import Optional

LOCK_FILE = Path('/run/lock/train_mail_filters.lock')
DEFAULT_LOG_FILE = Path('/var/log/train_mail_filters.log')
DEFAULT_LOG_RETENTION_DAYS = 7
DEFAULT_SPOOL_DIR = Path('/var/spool/spam')
DEFAULT_RSPAMD_CONTROLLER = 'localhost:11334'
PROMETHEUS_BACKENDS = ('spamassassin', 'rspamd')
PROMETHEUS_LABELS = ('spam', 'ham')
PROMETHEUS_STATUSES = ('success', 'error')
SPAMASSASSIN_USER = 'debian-spamd'
SPAMASSASSIN_GROUP = 'debian-spamd'

log = logging.getLogger('train_mail_filters')


class CommandError(RuntimeError):
    def __init__(self, command, result, *, context: Optional[str] = None) -> None:
        self.command = command
        self.result = result
        self.context = context
        super().__init__(_format_command_failure(command, result, context=context))


class MaxLevelFilter(logging.Filter):
    def __init__(self, max_level: int) -> None:
        super().__init__()
        self.max_level = max_level

    def filter(self, record: logging.LogRecord) -> bool:
        return record.levelno < self.max_level


def positive_int(value: str) -> int:
    parsed_value = int(value)
    if parsed_value < 1:
        raise argparse.ArgumentTypeError('must be greater than or equal to 1')
    return parsed_value


def initialize_prometheus_metrics() -> dict:
    return {
        'message_counts': {
            (backend, label, status): 0
            for backend in PROMETHEUS_BACKENDS
            for label in PROMETHEUS_LABELS
            for status in PROMETHEUS_STATUSES
        },
        'duplicate_counts': {
            label: 0
            for label in PROMETHEUS_LABELS
        },
    }


def increment_prometheus_metric(
    metrics: dict,
    backend: str,
    label: str,
    status: str,
    count: int = 1,
) -> None:
    metrics['message_counts'][(backend, label, status)] += count


def increment_prometheus_duplicate_metric(
    metrics: dict,
    label: str,
    count: int = 1,
) -> None:
    metrics['duplicate_counts'][label] += count


def write_prometheus_metrics(metrics_path: Path, metrics: dict, last_run_timestamp: float) -> None:
    lines = [
        '# HELP train_mail_filters_last_run_timestamp_seconds '
        'Unix timestamp of the last completed run',
        '# TYPE train_mail_filters_last_run_timestamp_seconds gauge',
        f'train_mail_filters_last_run_timestamp_seconds {last_run_timestamp}',
        '# HELP train_mail_filters_last_run_messages Messages processed during the last run',
        '# TYPE train_mail_filters_last_run_messages gauge',
    ]

    for backend in PROMETHEUS_BACKENDS:
        for label in PROMETHEUS_LABELS:
            for status in PROMETHEUS_STATUSES:
                value = metrics['message_counts'][(backend, label, status)]
                lines.append(
                    'train_mail_filters_last_run_messages'
                    f'{{backend="{backend}",label="{label}",status="{status}"}} {value}'
                )

    lines.extend([
        '# HELP train_mail_filters_last_run_duplicate_messages '
        'Rspamd duplicate messages found during the last run',
        '# TYPE train_mail_filters_last_run_duplicate_messages gauge',
    ])
    for label in PROMETHEUS_LABELS:
        value = metrics['duplicate_counts'][label]
        lines.append(
            'train_mail_filters_last_run_duplicate_messages'
            f'{{backend="rspamd",label="{label}"}} {value}'
        )

    metrics_path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = metrics_path.with_name(f'{metrics_path.name}~')
    tmp_path.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    tmp_path.replace(metrics_path)


def configure_logging(log_file: Path, retention_days: int, debug: bool) -> None:
    if log.handlers:
        return

    level = logging.DEBUG if debug else logging.INFO
    log.setLevel(level)
    log.propagate = False

    formatter = logging.Formatter(
        fmt='%(asctime)s %(levelname)s: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
    )

    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setLevel(level)
    stdout_handler.addFilter(MaxLevelFilter(logging.WARNING))
    stdout_handler.setFormatter(formatter)

    stderr_handler = logging.StreamHandler(sys.stderr)
    stderr_handler.setLevel(logging.WARNING)
    stderr_handler.setFormatter(formatter)

    log_file.parent.mkdir(parents=True, exist_ok=True)
    file_handler = logging.handlers.TimedRotatingFileHandler(
        str(log_file),
        when='midnight',
        interval=1,
        backupCount=retention_days,
        encoding='utf-8',
    )
    file_handler.setLevel(level)
    file_handler.setFormatter(formatter)

    log.addHandler(stdout_handler)
    log.addHandler(stderr_handler)
    log.addHandler(file_handler)


def format_command_for_log(command) -> str:
    redacted_command = []
    redact_next = False
    for argument in command:
        if redact_next:
            redacted_command.append('<redacted>')
            redact_next = False
            continue
        redacted_command.append(argument)
        if argument == '-P':
            redact_next = True
    return ' '.join(redacted_command)


def run_command(
    command,
    *,
    input_bytes=None,
    stdin_path=None,
    context: Optional[str] = None,
) -> subprocess.CompletedProcess:
    command_string = format_command_for_log(command)
    if context is None:
        log.debug('running command: %s', command_string)
    else:
        log.debug('running %s: %s', context, command_string)

    kwargs = {
        'capture_output': True,
        'check': False,
    }
    if input_bytes is not None:
        kwargs['input'] = input_bytes
    elif stdin_path is not None:
        with open(stdin_path, 'rb') as stdin_handle:
            result = subprocess.run(command, stdin=stdin_handle, **kwargs)
        _log_process_result(command, result, context=context)
        if result.returncode != 0:
            _log_command_failure(command, result, context=context)
            raise CommandError(command, result, context=context)
        return result

    result = subprocess.run(command, **kwargs)
    _log_process_result(command, result, context=context)
    if result.returncode != 0:
        _log_command_failure(command, result, context=context)
        raise CommandError(command, result, context=context)
    return result


def _decode_process_output(result) -> tuple[list[str], list[str]]:
    stdout = result.stdout.decode('utf-8', errors='replace').strip()
    stderr = result.stderr.decode('utf-8', errors='replace').strip()
    return stdout.splitlines(), stderr.splitlines()


def _format_command_failure(command, result, *, context: Optional[str] = None) -> str:
    command_string = format_command_for_log(command)
    stdout_lines, stderr_lines = _decode_process_output(result)
    details = []
    if stdout_lines:
        details.append(f'stdout tail: {stdout_lines[-1]}')
    if stderr_lines:
        details.append(f'stderr tail: {stderr_lines[-1]}')

    detail_suffix = f" ({'; '.join(details)})" if details else ''
    subject = context or 'command'
    return f'{subject} failed with exit code {result.returncode}: {command_string}{detail_suffix}'


def _log_command_failure(command, result, *, context: Optional[str] = None) -> None:
    command_string = format_command_for_log(command)
    subject = context or 'command'
    log.error('%s exited with non-zero status %s: %s', subject, result.returncode, command_string)


def _log_process_result(command, result, *, context: Optional[str] = None) -> None:
    command_string = context or format_command_for_log(command)
    stdout_lines, stderr_lines = _decode_process_output(result)

    if stdout_lines:
        for line in stdout_lines:
            log.info('%s: %s', command_string, line)
    if stderr_lines:
        for line in stderr_lines:
            log.error('%s: %s', command_string, line)


def read_password(password_file: Path) -> str:
    password = password_file.read_text(encoding='utf-8').strip()
    if not password:
        raise RuntimeError(f'empty rspamd password file: {password_file}')
    return password


def duplicated_path(spool_dir: Path, label: str) -> Path:
    return spool_dir / f'{label}.duplicated'


def append_message_to_mbox(mbox_path: Path, message) -> None:
    mbox = mailbox.mbox(str(mbox_path))
    try:
        mbox.lock()
        mbox.add(message)
        mbox.flush()
    finally:
        try:
            mbox.unlock()
        except Exception:
            pass
        mbox.close()


def count_mbox_messages(mbox_path: Path) -> int:
    mbox = mailbox.mbox(str(mbox_path), create=False)
    try:
        return sum(1 for _ in mbox)
    finally:
        mbox.close()


def is_rspamd_already_learned_error(error: CommandError) -> bool:
    stdout_lines, stderr_lines = _decode_process_output(error.result)
    combined_output = '\n'.join(stdout_lines + stderr_lines).lower()
    return 'already learned as' in combined_output


def marker_path(mbox_path: Path, marker_name: str) -> Path:
    return Path(f'{mbox_path}.{marker_name}')


def train_spamassassin(mbox_path: Path, label: str, metrics: dict) -> None:
    log.info('starting spamassassin training for %s from %s', label, mbox_path)
    chown(mbox_path, user=SPAMASSASSIN_USER, group=SPAMASSASSIN_GROUP)

    learn_mode = 'spam' if label == 'spam' else 'ham'
    list_command = '--add-to-blacklist' if label == 'spam' else '--add-to-whitelist'
    message_count = count_mbox_messages(mbox_path)

    try:
        run_command([
            '/bin/su',
            '-',
            SPAMASSASSIN_USER,
            '-s',
            '/bin/sh',
            '-c',
            f'/usr/bin/sa-learn --{learn_mode} --mbox {mbox_path}',
        ], context=f'spamassassin {label} bayes training')
        run_command([
            '/bin/su',
            '-',
            SPAMASSASSIN_USER,
            '-s',
            '/bin/sh',
            '-c',
            f'/usr/bin/spamassassin {list_command} --mbox',
        ], stdin_path=mbox_path, context=f'spamassassin {label} list update')
    except CommandError:
        increment_prometheus_metric(metrics, 'spamassassin', label, 'error', message_count)
        raise

    increment_prometheus_metric(metrics, 'spamassassin', label, 'success', message_count)


def train_rspamd(
    mbox_path: Path,
    label: str,
    controller: str,
    password_file: Optional[Path],
    metrics: dict,
) -> None:
    log.info('starting rspamd training for %s from %s via %s', label, mbox_path, controller)
    learn_command = 'learn_spam' if label == 'spam' else 'learn_ham'
    rspamc_command = ['/usr/bin/rspamc', '-h', controller]
    if password_file is not None:
        rspamc_command.extend(['-P', read_password(password_file)])
    rspamc_command.append(learn_command)
    duplicated_mbox_path = duplicated_path(mbox_path.parent, label)

    mbox = mailbox.mbox(str(mbox_path), create=False)
    try:
        learned_messages = 0
        duplicated_messages = 0
        for message in mbox:
            message_index = learned_messages + duplicated_messages + 1
            message_id = message.get('Message-ID', '<no Message-ID>')
            try:
                run_command(
                    rspamc_command,
                    input_bytes=message.as_bytes(policy=policy.SMTP),
                    context=f'rspamd {label} training message {message_index}',
                )
                learned_messages += 1
                increment_prometheus_metric(metrics, 'rspamd', label, 'success')
            except CommandError as error:
                if is_rspamd_already_learned_error(error):
                    append_message_to_mbox(duplicated_mbox_path, message)
                    duplicated_messages += 1
                    increment_prometheus_duplicate_metric(metrics, label)
                    log.warning(
                        'rspamd %s training message %s already learned; appended %s to %s',
                        label,
                        message_index,
                        message_id,
                        duplicated_mbox_path,
                    )
                    continue
                increment_prometheus_metric(metrics, 'rspamd', label, 'error')
                raise
    finally:
        mbox.close()

    log.info('processed %s messages from %s as %s for rspamd', learned_messages, mbox_path, label)
    if duplicated_messages:
        log.warning(
            'appended %s rspamd %s duplicate message(s) from %s to %s',
            duplicated_messages,
            label,
            mbox_path,
            duplicated_mbox_path,
        )


def get_processing_path(spool_dir: Path, label: str) -> Optional[Path]:
    source_path = spool_dir / label
    processing_path = spool_dir / f'{label}.processing'

    if processing_path.exists():
        if source_path.exists():
            log.warning('%s exists; deferring new source file %s', processing_path, source_path)
        return processing_path

    if not source_path.exists():
        log.debug('no %s source mbox found in %s', label, spool_dir)
        return None

    source_path.replace(processing_path)
    log.info('moved %s to %s for processing', source_path, processing_path)
    return processing_path


def cleanup_processing_file(mbox_path: Path, markers) -> None:
    for marker in markers:
        marker.unlink(missing_ok=True)
    mbox_path.unlink(missing_ok=True)


def process_label(args, label: str, metrics: dict) -> bool:
    mbox_path = get_processing_path(args.spool_dir, label)
    if mbox_path is None:
        return False

    markers = []
    had_non_blocking_error = False

    if args.train_spamassassin:
        spamassassin_marker = marker_path(mbox_path, 'sa_done')
        markers.append(spamassassin_marker)
        if not spamassassin_marker.exists():
            try:
                train_spamassassin(mbox_path, label, metrics)
            except CommandError as error:
                had_non_blocking_error = True
                log.error(
                    'spamassassin %s training failed for %s; '
                    'continuing with remaining backends: %s',
                    label,
                    mbox_path,
                    error,
                )
            else:
                spamassassin_marker.touch()
                log.info('processed %s as %s for spamassassin', mbox_path, label)
        else:
            log.debug('spamassassin marker already present for %s', mbox_path)

    if args.train_rspamd:
        rspamd_marker = marker_path(mbox_path, 'rspamd_done')
        markers.append(rspamd_marker)
        if not rspamd_marker.exists():
            try:
                train_rspamd(
                    mbox_path,
                    label,
                    args.rspamd_controller,
                    args.rspamd_password_file,
                    metrics,
                )
            except CommandError as error:
                had_non_blocking_error = True
                log.error(
                    'rspamd %s training failed for %s; '
                    'continuing with remaining labels: %s',
                    label,
                    mbox_path,
                    error,
                )
            else:
                rspamd_marker.touch()
        else:
            log.debug('rspamd marker already present for %s', mbox_path)

    if had_non_blocking_error:
        log.warning(
            'keeping %s for retry because at least one non-blocking backend error occurred',
            mbox_path,
        )
        return True

    cleanup_processing_file(mbox_path, markers)
    log.info('finished processing %s mbox %s', label, mbox_path)
    return False


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description='Train VRTS mail filters from mbox files.')
    parser.add_argument('--spool-dir', type=Path, default=DEFAULT_SPOOL_DIR)
    parser.add_argument('--lock-file', type=Path, default=LOCK_FILE)
    parser.add_argument('--log-file', type=Path, default=DEFAULT_LOG_FILE)
    parser.add_argument('--prometheus-metrics-path', type=Path)
    parser.add_argument(
        '--log-retention-days',
        type=positive_int,
        default=DEFAULT_LOG_RETENTION_DAYS,
    )
    parser.add_argument('--debug', action='store_true')
    parser.add_argument('--train-spamassassin', action='store_true')
    parser.add_argument('--train-rspamd', action='store_true')
    parser.add_argument('--rspamd-controller', default=DEFAULT_RSPAMD_CONTROLLER)
    parser.add_argument('--rspamd-password-file', type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    configure_logging(args.log_file, args.log_retention_days, args.debug)
    metrics = initialize_prometheus_metrics()

    log.info(
        'starting training run '
        '(spool_dir=%s, lock_file=%s, train_spamassassin=%s, train_rspamd=%s, '
        'log_file=%s, retention_days=%s, debug=%s, prometheus_metrics_path=%s)',
        args.spool_dir,
        args.lock_file,
        args.train_spamassassin,
        args.train_rspamd,
        args.log_file,
        args.log_retention_days,
        args.debug,
        args.prometheus_metrics_path,
    )

    try:
        if not args.train_spamassassin and not args.train_rspamd:
            log.warning('nothing to do, no training backends enabled')
            return 0

        args.spool_dir.mkdir(mode=0o775, parents=True, exist_ok=True)

        with open(args.lock_file, 'w', encoding='utf-8') as lock_handle:
            try:
                fcntl.flock(lock_handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
                log.debug('acquired lock %s', args.lock_file)
            except OSError:
                log.warning('another training process is already running')
                return 0

            had_non_blocking_errors = False
            for label in ('spam', 'ham'):
                had_non_blocking_errors |= process_label(args, label, metrics)

        if had_non_blocking_errors:
            log.error('training run completed with non-blocking backend errors')
            return 1

        log.info('done')
        return 0
    finally:
        if args.prometheus_metrics_path is not None:
            write_prometheus_metrics(args.prometheus_metrics_path, metrics, time.time())
            log.info('wrote prometheus metrics to %s', args.prometheus_metrics_path)


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except Exception:
        log.exception('train_mail_filters failed')
        raise SystemExit(1)
