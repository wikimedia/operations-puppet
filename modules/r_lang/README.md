# R: Statistical Software and Programming Language

[R](https://www.r-project.org/) is a free software environment for statistical
computing and graphics. This module facilitates setting up R in the computing
evironment.

Installs `r-base`, `r-base-dev`, `r-recommended` and Optimized BLAS (linear
algebra) library, and makes the following resources available for installing
R packages from various sources:

- **r_lang::cran** for installing from Comprehensive R Archive Network
    - the resource ID should be name of the package to be installed
    - *timeout*: default 300 (seconds)
    - *ensure*: default 'present', but also supports 'absent'
    - *mirror*: default 'https://cloud.r-project.org' which provides automatic
      redirection to servers worldwide, sponsored by Rstudio. In practice, the
      module uses [UC Berkeley mirror](https://cran.cnr.berkeley.edu/). For a
      list of CRAN mirrors, see https://cran.r-project.org/mirrors.html
- **r_lang::git** for installing from any Git repository
    - the resource ID should be name of the package to be installed
    - *url* is forwarded to `devtools::install_git()`
      e.g. 'https://gerrit.wikimedia.org/r/wikimedia/discovery/polloi'
    - *ensure*: default 'present', but also supports 'absent'
    - **Notice**: this is only available if the `devtools` parameter is set to
      `true`. Refer to [Disclaimer](#disclaimer) section below for details.
- **r_lang::github** for installing from a GitHub-hosted repository
    - the resource ID should be name of the package to be installed
    - *repo* is forwarded to `devtools::install_github()`
      e.g. 'wikimedia/wikimedia-discovery-polloi'
    - *ensure*: default 'present', but also supports 'absent'
    - **Notice**: this is only available if the `devtools` parameter is set to
      `true`. Refer to [Disclaimer](#disclaimer) section below for details.
- **r_lang::bioc** for installing from [Bioconductor](https://bioconductor.org/)
    - the resource ID should be name of the package to be installed
    - *timeout*: default 300 (seconds)
    - *ensure*: default 'present', but also supports 'absent'

The `notify` metaparameter is used to trigger a restart of the Shiny Server
service.

## Disclaimer

By default, the *devtools* R package (and its dependencies) are not installed,
which means that **r_lang::git** and **r_lang::github** will not work without specifying
`devtools => true` when using this module. This is because we do not yet allow
installing R packages via Puppet in Production until we have some kind of our
own, trusted CRAN mirror to install from. The work and discussion for setting
up a Wikimedia-hosted mirror of CRAN is tracked in Phabricator ticket
[T170995](https://phabricator.wikimedia.org/T170995).

In **_Production_** (e.g. in **statistics::packages**), use

```Puppet
include ::r_lang
```

This will _not_ install any packages from CRAN except for the ones in the
[`r-recommended`](https://cran.r-project.org/bin/linux/debian/#supported-packages)
Debian/Ubuntu package. Any additional R packages will then need to be installed
manually by users.

On **_Labs_**, use

```Puppet
class { 'r_lang':
    devtools => true,
}
```

This will allow you to install from Git/GitHub by installing the necessary
dependencies.

## Updating installed R packages

There is a utility script - [update-library.R](files/update-library.R) - that
is saved to /etc/R/update-library.R and has the following options:

- `-p PACKAGE, --package=PACKAGE` for updating a specific package. If missing,
  all packages installed from CRAN will be updated.
- `--mirror=MIRROR` for specifying the CRAN mirror URL. The default is
  'https://cloud.r-project.org'. For a list of CRAN mirrors, see
  https://cran.r-project.org/mirrors.html
- `-l LIBRARY, --library=LIBRARY` for updating packages in a specific library
  location. If missing, uses `.libPaths()` just like `update.packages()` does.

Non-CRAN packages such as [polloi](https://phabricator.wikimedia.org/diffusion/WDPL/)
are updated only if specified as an option. For example:

```bash
Rscript /etc/R/update-library.R -p polloi
```

or if the user runs `devtools::update_packages()` interactively in R (as sudo).

Again, unless `devtools` parameter is set to `true` when using this module, you
will not be able to install or update R packages from Git/GitHub.
