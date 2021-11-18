#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Do very basic validation on Cassandra grant statements

Try to catch statements that shouldn't be in grant statements - this is not a
substitute for real and diligent code review but just another check to ensure
that we don't include things that shouldn't be present in our automatic CQL
grants.
"""

import sys

ALLOWED_STARTS = ["GRANT", "CREATE USER"]


def main():

    if len(sys.argv) != 2:
        sys.stderr.write("Usage: {} grantsfile.cql\n".format(sys.argv[0]))
        sys.exit(2)

    failed = []

    with open(sys.argv[1]) as config_f:
        config = config_f.read()

    for statement in config.split(";"):
        statement = statement.strip()
        if not statement:
            continue
        statement_ok = False
        for allowed_start in ALLOWED_STARTS:
            if statement.upper().startswith(allowed_start):
                statement_ok = True

        if not statement_ok:
            failed.append(statement)
    if failed:
        for fail in failed:
            print("Statement '{}' did not pass validation".format(fail))
        print("All statements must start with one of:")
        for allowed_start in ALLOWED_STARTS:
            print(" -", allowed_start)

    sys.exit(0 if not failed else 1)


if __name__ == "__main__":
    main()
