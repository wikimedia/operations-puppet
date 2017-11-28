## Usage
```
$ node warmup.js

Usage: node warmup.js FILE MODE [spread_target|clone_cluster] [clone_dc]
 - file          Path to a text file containing a newline-separated list of urls. Entries may use %server or %mobileServer.
 - mode          One of:
                  "spread": distribute urls via load-balancer
                  "clone": send each url to each server
                  "clone-debug": send urls to debug server

Examples:
 $ node warmup.js urls-cluster.txt spread appservers.svc.codfw.wmnet
 $ node warmup.js urls-server.txt clone-debug
 $ node warmup.js urls-server.txt clone appserver codfw
```

## Output
```
$ node warmup.js urls-server.txt clone-debug
...
[2017-03-01T18:26:57.262Z] Request https://bg.wikibooks.org/w/load.php?debug=false&modules=startup&only=scripts (debug)
[2017-03-01T18:26:57.347Z] Request https://tet.wikipedia.org/w/load.php?debug=false&modules=jquery%2Cmediawiki&only=scripts (debug)
[2017-03-01T18:26:57.459Z] Request https://zh.wikibooks.org/w/load.php?debug=false&modules=site%7Csite.styles (debug)
Statistics:
	- timing: min = 1.032268135s | max = 14.20442249s | avg = 7.403086658241668s | total = 15s
	- concurrency: min = 1 | max = 100 | avg = 59

Slowest 5:
 - 2.214s (debug) https://test.wikidata.org/w/load.php?debug=false&modules=startup&only=scripts
 - 2.213s (debug) https://test2.wikipedia.org/w/load.php?debug=false&modules=startup&only=scripts
 - 2.211s (debug) https://test.wikipedia.org/w/load.php?debug=false&modules=startup&only=scripts
 - 1.465s (debug) https://test.wikidata.org/w/load.php?debug=false&modules=jquery%2Cmediawiki&only=scripts
 - 1.417s (debug) https://test2.wikipedia.org/w/load.php?debug=false&modules=jquery%2Cmediawiki&only=scripts
Done!
```
