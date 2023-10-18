#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import shutil
import time
from datetime import timezone
from pathlib import Path

import git
import mwopenstackclients
import pymysql
from git.remote import PushInfo
from oslo_config import cfg
from oslo_log import log as logging

logger = logging.getLogger(__name__)


def configure_logger():
    logging.register_options(cfg.CONF)
    logging.setup(cfg.CONF, "puppet-enc-git-worker")


def configure_options():
    cfgGroup = cfg.OptGroup("enc")
    opts = [
        cfg.StrOpt("mysql_host"),
        cfg.StrOpt("mysql_db"),
        cfg.StrOpt("mysql_username", secret=True),
        cfg.StrOpt("mysql_password"),
        cfg.StrOpt("git_repository_path"),
        cfg.StrOpt("git_repository_url"),
        cfg.StrOpt("git_keyholder_key"),
    ]

    cfg.CONF.register_group(cfgGroup)
    cfg.CONF.register_opts(opts, group=cfgGroup)

    cfg.CONF(default_config_files=["/etc/puppet-enc-api/config.ini"])


class Database:
    def __init__(self, **kwargs):
        self.connection = pymysql.connect(
            **kwargs,
            charset="utf8",
            cursorclass=pymysql.cursors.DictCursor,
        )

    def query_one(self, sql: str, params=None):
        with self.connection.cursor() as cursor:
            cursor.execute(sql, params)
            return cursor.fetchone()

    def query_all(self, sql: str, params=None):
        with self.connection.cursor() as cursor:
            cursor.execute(sql, params)
            return cursor.fetchall()

    def update(self, sql: str, params=None):
        with self.connection.cursor() as cursor:
            cursor.execute(sql, params)
        self.connection.commit()


def get_author(keystone, user_id: str) -> git.Actor:
    user = keystone.users.get(user_id)
    return git.Actor(
        user.id,
        user.email if user.email else "unknown@example.org",
    )


def main():
    configure_logger()
    configure_options()

    database = Database(
        host=cfg.CONF.enc.mysql_host,
        db=cfg.CONF.enc.mysql_db,
        user=cfg.CONF.enc.mysql_username,
        passwd=cfg.CONF.enc.mysql_password,
    )

    clients = mwopenstackclients.clients(oscloud="novaobserver")

    git_env = {
        "SSH_AUTH_SOCK": "/run/keyholder/proxy.sock",
        "GIT_SSH_COMMAND": (
            f"/usr/bin/ssh -i /etc/keyholder.d/{cfg.CONF.enc.git_keyholder_key}"
            + ' -o "StrictHostKeyChecking=no"'
        ),
    }

    repo_root = Path(cfg.CONF.enc.git_repository_path)
    if (repo_root / ".git").exists():
        logger.info("Found existing Git repository in %s", repo_root)
        repo = git.Repo(repo_root)
    else:
        logger.info(
            "Cloning the Git repository from %s to %s", cfg.CONF.enc.git_repository_url, repo_root
        )
        repo = git.Repo.clone_from(
            url=cfg.CONF.enc.git_repository_url,
            to_path=repo_root,
            env=git_env,
        )

    repo.git.update_environment(**git_env)

    while True:
        next_commit = database.query_one(
            """
            SELECT guqc_id, guqc_date, guqc_author_user, guqc_commit_message
            FROM git_update_queue_commit
            """
        )

        if not next_commit:
            logger.debug("No commits available, sleeping for 10 seconds..")
            time.sleep(10)
            continue

        commit_id = next_commit["guqc_id"]
        logger.info("Found commit %s", commit_id)

        # TODO: check for uncommitted changes

        repo.remotes.origin.pull(rebase=True)

        files = database.query_all(
            """
            SELECT guqf_id, guqf_commit, guqf_file_path, guqf_new_content
            FROM git_update_queue_file
            WHERE guqf_commit = %s
            """,
            [commit_id],
        )

        for file in files:
            file_path = repo_root / file["guqf_file_path"]

            if file["guqf_new_content"] is not None:
                file_path.parent.mkdir(parents=True, exist_ok=True)

                with file_path.open("w") as f:
                    f.write(file["guqf_new_content"])
                repo.index.add([str(file_path)])
            elif file_path.exists():
                recursive_arg = {"r": True} if file_path.is_dir() else {}
                repo.index.remove([str(file_path)], **recursive_arg)

                if file_path.is_dir():
                    shutil.rmtree(file_path)
                else:
                    file_path.unlink()

        if repo.index.diff(repo.head.commit):
            keystone = clients.keystoneclient()
            author = get_author(keystone, next_commit["guqc_author_user"])
            committer = git.Actor("puppet-enc", "root@wmcloud.org")

            repo.index.commit(
                message=next_commit["guqc_commit_message"],
                author=author,
                committer=committer,
                author_date=next_commit["guqc_date"].replace(tzinfo=timezone.utc),
            )

            push_result = repo.remotes.origin.push()
            # TODO: when a newer python3-git version is available, just use
            # push_result.raise_if_error()
            # for now,
            for row in push_result:
                if row.flags & (PushInfo.REJECTED | PushInfo.ERROR):
                    raise Exception(f"Failed to push commit {commit_id}")

            logger.info("Commit %s pushed", commit_id)
        else:
            logger.info("Commit %s was empty", commit_id)

        database.update(
            """
            DELETE FROM git_update_queue_commit
            WHERE guqc_id = %s
            """,
            [commit_id],
        )


if __name__ == "__main__":
    main()
