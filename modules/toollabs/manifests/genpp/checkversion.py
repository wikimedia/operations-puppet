#!/usr/bin/env python3
import genpp
import argparse
import fnmatch

parser = argparse.ArgumentParser(
    description='Report package version in supported OS releases'
)
parser.add_argument(
    'name',
    help='The name of the package. Shell-style wildcards are supported.'
)

if __name__ == "__main__":
    args = parser.parse_args()
    print("Searching for {name} in {releases}".format(
        name=args.name,
        releases=list(genpp.releases.keys())
    ))
    for release in genpp.releases:
        packages = genpp.load_release(release)
        matches = fnmatch.filter(packages.keys(), args.name)
        if not matches:
            print("{release}: (no matches)".format(release=release))
        else:
            for match in matches:
                print("{release}: {match} ({version})".format(
                    release=release,
                    match=match,
                    version=packages[match]
                ))
