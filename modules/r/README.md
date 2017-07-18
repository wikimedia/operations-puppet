# R: Statistical Software and Programming Language

[R](https://www.r-project.org/) is a free software environment for statistical
computing and graphics. This module facilitates setting up R in the computing
evironment.

Installs `r-base`, `r-base-dev`, `r-recommended` and Optimized BLAS (linear
algebra) library, and makes the following resources available for installing
R packages from various sources:

- **r::cran** for installing from Comprehensive R Archive Network
    - the resource ID should be name of the package to be installed
    - *timeout*: default 300 (seconds)
    - *ensure*: default 'present', but also supports 'absent'
    - *mirror*: default 'https://cloud.r-project.org' which provides automatic
      redirection to servers worldwide, sponsored by Rstudio. In practice, the
      module uses [UC Berkeley mirror](https://cran.cnr.berkeley.edu/). For a
      list of CRAN mirrors, see https://cran.r-project.org/mirrors.html
- **r::git** for installing from any Git repository
    - the resource ID should be name of the package to be installed
    - *url* is forwarded to `devtools::install_git()`
      e.g. 'https://gerrit.wikimedia.org/r/wikimedia/discovery/polloi'
    - *ensure*: default 'present', but also supports 'absent'
- **r::github** for installing from a GitHub-hosted repository
    - the resource ID should be name of the package to be installed
    - *repo* is forwarded to `devtools::install_github()`
      e.g. 'wikimedia/wikimedia-discovery-polloi'
    - *ensure*: default 'present', but also supports 'absent'

The `notify` metaparameter is used to trigger a restart of the Shiny Server
service.

## Updating installed R packages

There is a utility script - [update-library.R](files/update-library.R) - that is
saved to /etc/R/update-library.R and has the following options:

- `-p PACKAGE, --package=PACKAGE` for updating a specific package. If missing,
  all packages installed from CRAN will be updated.
- `--mirror=MIRROR` for specifying the CRAN mirror URL. The default is
  'https://cloud.r-project.org'. For a list of CRAN mirrors, see
  https://cran.r-project.org/mirrors.html
- `-l LIBRARY, --library=LIBRARY` for updating packages in a specific library location.
  If missing, uses `.libPaths()` just like `update.packages()` does.

Non-CRAN packages such as [polloi](https://phabricator.wikimedia.org/diffusion/WDPL/)
are updated only if specified as an option. For example:

```bash
Rscript /etc/R/update-library.R -p polloi
```

or if the user runs `devtools::update_packages()` interactively in R (as sudo).
