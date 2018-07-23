#!/usr/bin/env python3

# Quick and dirty script to print hot_threads once then again every minute if
# the load average is more than half the number of CPUs.  It scans for 5
# minutes then exits.  Cron it to run every five minutes and you'll get
# periodic snapshots of the hot_threads with more frequent ones under load.

from glob import glob
from os import getloadavg
from multiprocessing import cpu_count, Pool
from time import gmtime, sleep, strftime, time
from sys import stdout
from urllib.request import urlopen
import yaml


def print_hot_threads(port, out=stdout):
    out.write(strftime("%Y-%m-%d %H:%M:%S\n", gmtime()))
    hot_threads = urlopen('http://localhost:{}/_nodes/_local/hot_threads'.format(port))
    try:
        for line in hot_threads.readlines():
            out.write(line.decode('utf8'))
            out.flush()
    finally:
        hot_threads.close()


def main(config_path):
    try:
        with open(config_path, 'r') as f:
            conf = yaml.safe_load(f)
        with open(conf['output'], 'a') as f:
            print_hot_threads(port=conf['port'], out=f)
            end = time() + 5 * 60
            max_load = cpu_count() / 2.0
            while time() < end:
                one_minute_load = getloadavg()[0]
                if one_minute_load > max_load:
                    f.write("Load average: {}\n".format(one_minute_load))
                    print_hot_threads(port=conf['port'], out=f)
                    sleep(50)
                sleep(10)
    except Exception as e:
        # Don't let a single failing config fail the rest
        print(e)


if __name__ == "__main__":
    pool = Pool(5)
    pool.map(main, glob('/etc/elasticsearch_hot_threads.d/*.yml'))
