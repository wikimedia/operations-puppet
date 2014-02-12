# Quick and dirty script to print hot_threads once then again every minute if
# the load average is more than half the number of CPUs.  It scans for 5
# minutes then exits.  Cron it to run every five minutes and you'll get
# periodic snapshots of the hot_threads with more frequent ones under load.

from os import getloadavg
from multiprocessing import cpu_count
from time import gmtime, sleep, strftime, time
from sys import stdout
from urllib import urlopen


def print_hot_threads():
    print(strftime("%Y-%m-%d %H:%M:%S", gmtime()))
    hot_threads = urlopen('http://localhost:9200/_nodes/_local/hot_threads')
    try:
        for line in hot_threads.readlines():
            stdout.write(line)
            stdout.flush()
    finally:
        hot_threads.close()


print_hot_threads()
end = time() + 5 * 60
max_load = cpu_count() / 2.0
while time() < end:
    one_minute_load = getloadavg()[0]
    if one_minute_load > max_load:
        print("Load average:  %s" % one_minute_load)
        print_hot_threads()
        sleep(50)
    sleep(10)
