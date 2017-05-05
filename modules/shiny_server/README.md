# Shiny Server

[Shiny Server](https://www.rstudio.com/products/shiny/shiny-server/) enables
users to host and manage Shiny applications on the Internet.
[Shiny](https://www.rstudio.com/products/shiny/) is an R package that uses a
reactive programming model to simplify the development of R-powered web
applications. [RStudio](https://www.rstudio.com/) also provides an
[administrator's guide](http://docs.rstudio.com/shiny-server/) for Shiny Server.

The module creates a service "shiny-server" that serves Shiny applications from
/srv/shiny-server through port 3838.

## Resources

The following resources and parameters are available:

- **shiny_server::cran_pkg**
    - the resource ID should be name of the package to be installed
    - *timeout*: default 300 (seconds)
    - *ensure*: default 'present', but also supports 'absent'
    - *mirror*: default 'https://cloud.r-project.org' which provides automatic
      redirection to servers worldwide, sponsored by Rstudio. In practice, the
      module uses [UC Berkeley mirror](https://cran.cnr.berkeley.edu/). For a
      list of CRAN mirrors, see https://cran.r-project.org/mirrors.html
- **shiny_server::git_pkg**
    - the resource ID should be name of the package to be installed
    - *url* is forwarded to `devtools::install_git()`
      e.g. 'https://gerrit.wikimedia.org/r/wikimedia/discovery/polloi'
    - *ensure*: default 'present', but also supports 'absent'
- **shiny_server::github_pkg**
    - the resource ID should be name of the package to be installed
    - *repo* is forwarded to `devtools::install_github()`
      e.g. 'wikimedia/wikimedia-discovery-polloi'
    - *ensure*: default 'present', but also supports 'absent'

The `notify` metaparameter is used to trigger a restart of the Shiny Server
service if the dashboard's source code has been updated.

## Updating installed R packages

There is a utility script - [update-library.R](files/update-library.R) - that is saved
to /etc/R/update-library.R and has the following options:

- `-p PACKAGE, --package=PACKAGE` for updating a specific package. If missing,
  all packages installed from CRAN will be updated.
- `--mirror=MIRROR` for specifying the CRAN mirror URL. The default is
  'https://cloud.r-project.org'. For a list of CRAN mirrors, see
  https://cran.r-project.org/mirrors.html

Non-CRAN packages such as [polloi](https://phabricator.wikimedia.org/diffusion/WDPL/)
are updated only if specified as an option:

```bash
Rscript /etc/R/update-library.R -p polloi
```

or if the user runs `devtools::update_packages()` interactively in R (as sudo).
