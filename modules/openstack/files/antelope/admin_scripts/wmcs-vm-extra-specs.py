#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0


# This script will connect to the Nova database and update the extra specs on
# existing virtual machine instances.
#
# To view or confirm changes made by this script you should use the Nova built-in command
# `nova server show <uuid>` and confirm the extra specs field.

import argparse
import logging
import os
import sys

from oslo_serialization import jsonutils
from sqlalchemy import MetaData, Table, create_engine
from sqlalchemy.exc import DBAPIError, SQLAlchemyError
from sqlalchemy.orm import Session
from sqlalchemy.orm.exc import MultipleResultsFound, NoResultFound

logging.basicConfig(level=logging.INFO)

SUPPORTED_SPECS = (
    "quota:disk_read_bytes_sec",
    "quota:disk_read_iops_sec",
    "quota:disk_total_bytes_sec",
    "quota:disk_total_iops_sec",
    "quota:disk_write_bytes_sec",
    "quota:disk_write_iops_sec",
)


def bail(msg):
    """ Log error and exit """
    logging.error(msg)
    sys.exit(1)


class Instance:
    def __init__(self, session, engine, uuid):
        self.session = session
        self.table = Table("instance_extra", MetaData(), autoload=True, autoload_with=engine)
        self.uuid = uuid

        try:
            results = (
                self.session.query(self.table.c.flavor)
                .filter(self.table.c.instance_uuid == self.uuid)
                .one()
            )
        except MultipleResultsFound:
            bail("Multiple instances found matching UUID!")
        except NoResultFound:
            bail("Instance UUID not found!")

        self.flavor = jsonutils.loads(results.flavor)

    def set_extra_spec(self, k, v):
        """
        Set an extra spec on an existing virtual machine instance

        returns True if extra spec value has changed
        returns False if the extra spec matches the requested value
        """
        changed = False
        if self.flavor["cur"]["nova_object.data"]["extra_specs"].get(k) != v:
            self.flavor["cur"]["nova_object.data"]["extra_specs"][k] = v
            query = (
                self.session.query(self.table)
                .filter(self.table.c.instance_uuid == self.uuid)
                .update(
                    {self.table.c.flavor: jsonutils.dumps(self.flavor)}, synchronize_session=False
                )
            )
            # Rollback if multiple rows were targeted for updated
            # This should never happen! There should only ever be one row per instance UUID
            if query != 1:
                self.session.rollback()
                self.session.close()
                bail("Multiple rows would have been updated with UUID {}!".format(self.uuid))

            try:
                self.session.commit()
                logging.info("Set: extra_spec %s to %s", k, v)
                changed = True
            except (SQLAlchemyError, DBAPIError) as e:
                self.session.rollback()
                self.session.close()
                bail(e)
        else:
            logging.info("Unchanged: extra_spec %s matches %s", k, v)

        self.session.close()
        return changed


if __name__ == "__main__":
    argparser = argparse.ArgumentParser(
        "wmcs-vm-extra-specs", description="Manage virtual machine extra specs"
    )
    argparser.add_argument(
        "--nova-db-server",
        help="nova database server (FQDNs). Default is openstack.eqiad1.wikimediacloud.org",
        default="openstack.eqiad1.wikimediacloud.org",
    )
    argparser.add_argument(
        "--nova-db", help="nova database name. Default is nova_eqiad1", default="nova_eqiad1"
    )
    argparser.add_argument(
        "--mysql-password",
        help="mysql password for nova db",
        default=os.environ.get("NOVA_MYSQL_PASS", None),
    )
    argparser.add_argument("uuid", help="instance UUID")
    argparser.add_argument("spec_name", choices=SUPPORTED_SPECS, help="instance spec name")
    argparser.add_argument("spec_value", help="instance spec value")

    args = argparser.parse_args()

    engine = create_engine(
        "mysql+mysqlconnector://nova:{}@{}:3306/{}".format(
            args.mysql_password, args.nova_db_server, args.nova_db
        )
    )

    session = Session(bind=engine)
    instance = Instance(session, engine, args.uuid)

    logging.debug("Before: %s", instance.flavor["cur"]["nova_object.data"]["extra_specs"])
    if instance.set_extra_spec(args.spec_name, args.spec_value):
        logging.info("%s must be rebooted to pickup the new extra spec", args.uuid)
    logging.debug(" After: %s", instance.flavor["cur"]["nova_object.data"]["extra_specs"])
