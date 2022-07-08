<!-- SPDX-License-Identifier: Apache-2.0 -->
Testing IRC notification format
===============================

When making changes to the `msg_format` IRC notification template it is useful to be able to iterate on the format and preview results.

The recommended way is to use `gomplate` (installed via `go get github.com/hairyhenderson/gomplate/v3/cmd/gomplate`) from the command line with the template in a file (e.g. `tmpl`) and a test alert as received by Alertmanager's webhooks (`testalert.yaml` in this directory: on the wire the format is JSON but converted here to YAML for ease of use).

With both files in the same directory then you can preview the notification with:

```
gomplate -c .=./testalert.yaml < tmpl
```

Note `alertmanager-irc-relay` includes template functions for path/URL escaping not included in gomplate.
