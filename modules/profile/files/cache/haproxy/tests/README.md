# HAProxy tests

SPDX-License-Identifier: Apache-2.0

You can use the [docker_run.sh](docker_run.sh) script in this folder to run tests on HAProxy configuration. Similarly to what's already done for varnishtests, you need to pass 2 mandatory arguments: an (existing) host to fetch PCC data from and a gerrit change_id.

Also, your are required to export your Jenkins credentials, if not already done, that will be used to fetch the data and run PCC.

Currently the script only checks for HAProxy configuration files validity, will be expanded later to include proper functional testing.

# Requirements

- Working ``docker`` installation
- Exported Jenkins credentials (eg. in your ~/.bashrc file):
```bash
export JENKINS_USERNAME=<YOUR_JENKINS_USERNAME>
export JENKINS_API_TOKEN=<YOUR_JENKINS_API_TOKEN>
```

# Running the script

You can run the script like ``./docker_run.sh HOST CHANGE_ID``.

The command above will build a test image, if it does not already exist, then it starts a container in which the haproxy tests will be run. The output is printed on your screen

You can customize the log level which the script will be run editing the ``docker_run.sh`` script and setting it to DEBUG (for example) to print the content of all configuration file, other than extra information on the check status.

## Script workflow (overview)

- A docker image is built with all dependencies to run HAProxy and relevant files are copied into it
- The ``run.py`` script along with the ``HOST`` and ``CHANGE_ID`` arguments is run inside the container
- The script uses the PCC URL (or builds one from the ``CHANGE_ID``) to downlad the specified files (HAProxy configuration files + extra needed files)
- Some replacements are made in the configuration files to allow running in a non-production environment
- The configuration check is run and eventual errors are printed on the console.

# Examples
```
./docker_run.sh cp4022.ulsfo.wmnet 506868
```
