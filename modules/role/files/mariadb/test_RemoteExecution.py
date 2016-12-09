#!/usr/bin/python3

import time

from SSHExecution import SSHExecution

e = SSHExecution()
e.user = 'pi'
e.host_keys = '.ssh/known_hosts'
result = e.run('192.168.1.143', ['ls', '-la'])
print(result.stdout)
job = e.start_job('192.168.1.143', ['/bin/sleep', '5'])
time.sleep(1)
result = e.monitor_job('192.168.1.143', job)
print(result.returncode)
time.sleep(6)
result = e.monitor_job('192.168.1.143', job)
print(result.returncode)
result = e.start_job('192.168.1.143', ['/bin/sleep', '5'])
time.sleep(1)
e.kill_job('192.168.1.143', job)
