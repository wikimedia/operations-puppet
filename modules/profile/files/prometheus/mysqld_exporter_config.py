#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

"""
This script generates the prometheus-mysqld-exporter targets from the
zarcillo database so it doesn't have to be maintained
manually on different places
"""
import difflib
import yaml
import argparse
import logging
import sys
import pymysql
from dataclasses import dataclass
from wmflib.config import load_yaml_config
from pathlib import Path
from wmflib.constants import ALL_DATACENTERS


TLS_TRUSTED_CA = "/etc/ssl/certs/wmf-ca-certificates.crt"
DB_CONFIG_FILE = Path("/etc/prometheus/zarcillo.cnf")
logger = logging.getLogger("mysqld_exporter_config")


def get_socket(instance):
    """
    Returns the prometheus listening socket address from the instance string.
    E.g. db1068 returns db1068:9104; db1098:3311 returns db1098:13311
    REMEMBER to change role::prometheus::mysqld_exporter,
    profile::mariadb::*multiinstance if you change this.
    """
    if ":" not in instance:
        return f"{instance}:9104"
    host, port = instance.rsplit(":", 1)
    return f"{host}:{int(port) + 10000}"


def get_args():
    """
    Return an object with the datacenter to be monitored and the path of the prometheus job
    configuration as read from the command line arguments
    """
    parser = argparse.ArgumentParser(
        description="Generate mysql prometheus exporter targets."
    )
    parser.add_argument(
        "--db-config-file",
        dest="db_config_file",
        default=DB_CONFIG_FILE,
        help="MySQL Config file to read from to connect to Zarcillo's database",
        type=Path,
    )
    parser.add_argument(
        "--dc",
        "-d",
        dest="dc",
        choices=ALL_DATACENTERS,
        help="Datacenter to generate files for.",
        type=str,
    )
    parser.add_argument(
        "-C",
        "--config-path",
        dest="config_path",
        help="Absolute path of the location of prometheus job configuration.",
        type=Path,
        nargs="?",
    )
    parser.add_argument(
        "-G",
        "--generator-config",
        dest="generator_config",
        help="Overrides default path of this generator's configuration file",
        default=Path("/etc/mysqld-exporter-config.yaml"),
        type=Path,
        nargs="?",
    )
    parser.add_argument(
        "-D",
        "--dry-run",
        dest="dry_run",
        help="Will only print diff between generated and existing config file.",
        default=False,
        action="store_true",
    )
    options = parser.parse_args()
    return options


def get_data(dc, args):
    """
    Connect to the database, query all needed data, do basic checks (e.g. no empty results)
    and return it as is.
    """
    logger = logging.getLogger("prometheus")
    try:
        db = pymysql.connect(
            read_default_file=args.db_config_file,

        )
    except pymysql.err.OperationalError:
        logger.error("We could not connect to the database reading %s to store the stats" %
                     str(args.db_config_file), exc_info=True)
        sys.exit(4)

    # query instances and its sections, groups and if they are masters or not
    query = """SELECT instances.name AS name, instances.group AS `group`, sections.name AS section,
               IF(sections.standalone, 'standalone',
               IF (isnull(masters.instance), 'slave', 'master')) AS role
               FROM section_instances
               LEFT JOIN sections ON sections.name=section_instances.section
               JOIN instances ON section_instances.instance = instances.name
               LEFT JOIN masters ON section_instances.instance = masters.instance
               WHERE instances.server like %s
               ORDER BY name, section, role"""

    # expected results: name | group | section | role
    #                   db1  | core  | s1      | slave
    #                   db2  | misc  | s3      | master
    #                   db3  | labs  | m4      | standalone
    with db.cursor(pymysql.cursors.DictCursor) as cursor:
        try:
            cursor.execute(query, ("%." + dc + ".wmnet",))
        except (pymysql.err.ProgrammingError, pymysql.err.InternalError):
            logger.exception("A MySQL error occurred while quering the instances")
            sys.exit(5)
        data = cursor.fetchall()
        # Check we have a number of reasonable results depending on the dc
        if ((len(data) < 10 or len(data) > 1000) and dc in ["eqiad", "codfw"]) or (
            len(data) > 0 and dc not in ["eqiad", "codfw"]
        ):
            logger.error("The number of obtained results is different than expected")
            sys.exit(6)
    db.close()
    return data


def transform_data_to_prometheus(data):
    """
    Transforms the data as received in the database format to the one
    expected by the prometheus job configuration
    """
    # convert database format to dictionary. Eg.:
    # core:                <-- group
    #   s1:                <-- section (shard)
    #     master:          <-- role
    #       - db1163:9104  <-- list of sockets
    #     slave:
    #       - db1169:11311
    #       - db1187:9104
    logger = logging.getLogger('prometheus')
    instances = dict()
    for instance in data:
        name = get_socket(instance["name"])
        group = instance["group"]
        section = instance["section"]
        role = instance["role"]
        if role not in [
            "master",
            "slave",
            "standalone",
        ]:  # Some es* hosts are special ones
            logger.error("A role other than master, replica or standalone was found")
            sys.exit(7)
        if group not in instances:
            instances[group] = dict()
        if section not in instances[group]:
            instances[group][section] = dict()
        if role not in instances[group][section]:
            instances[group][section][role] = list()
        instances[group][section][role].append(name)

    # transform to prometheus yaml schema. E.g.:
    # core:
    # - labels:
    #     shard: s1
    #     role: master
    #   targets:
    #     - db1163:9104
    # - labels:
    #     shard: s1
    #     role: slave
    #   targets:
    #     - db1169:11311
    #     - db1187:9104
    prometheus = dict()
    for group, sections in sorted(instances.items()):
        prometheus[group] = list()
        try:
            for section, roles in sorted(sections.items()):
                for role, targets in sorted(roles.items()):
                    labels = dict()
                    labels["shard"] = section
                    labels["role"] = role
                    item = dict()
                    item["labels"] = labels
                    item["targets"] = targets
                    prometheus[group].append(item)
        except TypeError:
            logger.error("The query returned instances with NULL sections, aborting.")
            logger.error("Check the instances, section_instances or sections tables.")
            sys.exit(8)
    return prometheus


def check_and_write_to_disk(prometheus, dc, config_path, args):
    """
    Compares existing and new content about to be written, and if it is different, it
    overwrites it
    """
    logger = logging.getLogger("prometheus")
    for group, sections in sorted(prometheus.items()):
        filename = f"mysql-{group}_{dc}.yaml"
        path = Path(config_path) / Path(filename)
        try:
            previous_config = path.read_text()
        except FileNotFoundError:
            logger.debug("Prometheus file not found")
            previous_config = None
        except IOError:
            logger.exception("Error while reading original file")
            sys.exit(8)
        new_config = yaml.dump(sections, default_flow_style=False)
        if previous_config == new_config:
            logger.debug(
                "%s is identical to the generated one. Sskipping overwrite.", filename
            )
            print(
                filename, "is identical to the generated one. Skipping overwrite.",
            )
        else:
            if not args.dry_run:
                print("Writing", filename)
                try:
                    with open(path, "w") as outfile:
                        yaml.dump(sections, outfile, default_flow_style=False)
                except IOError:
                    logger.exception("Error updating file %s", filename)
                    sys.exit(9)
                logger.info("%s was modified", filename)
            else:
                print("Diffing only.")
                diff = difflib.Differ()
                comp = list(diff.compare(str(previous_config).splitlines(
                    False), str(new_config).splitlines(False)))
                for line in comp:
                    print(line)


def get_config_from_file(conf_file):
    """
    Read from a local file and return the generator configuration parameters
    """

    return Generatorconfig(**load_yaml_config(conf_file))


def main():
    """
    Reads the instance configuration from the database and, if it changed,
    overwrite the prometheus mysqld exporter job scheduling config.
    """
    generator_config: Generatorconfig
    # get datacenter and prometheus config path from command line
    logger = logging.getLogger("prometheus")
    args = get_args()
    if not args.config_path or not args.dc:
        logger.info("Default mode, will read from %s", args.generator_config)
        generator_config = get_config_from_file(args.generator_config)
    elif args.config_path and args.dc:
        print("Custom mode, will use %s", str(args))
        generator_config = Generatorconfig(args.dc, args.config_path)
    else:
        raise SyntaxError

    # Connect to the database and gather data
    data = get_data(generator_config.dc, args)
    # transform data to the prometheus format
    prometheus = transform_data_to_prometheus(data)
    # write yaml to disk
    check_and_write_to_disk(
        prometheus, generator_config.dc, generator_config.config_path, args
    )


@dataclass
class Generatorconfig:
    dc: str
    config_path: str


if __name__ == "__main__":
    main()
