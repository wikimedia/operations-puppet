# Roles for WDCM dashboards

## Roles

- **WDCM Dashboards** (these require Ubuntu)
    - `dashboards`: sets up the dashboards using the "master" versions
    - `beta_dashboards`: sets up the dashboards using the "develop" versions

**Notes**: WDCM Dashboards require Ubuntu because that's the only OS we
have Shiny Server available for. There is a ticket to build that package for
Debian: [T168967](https://phabricator.wikimedia.org/T168967). The computing
roles require Debian because the R that comes with Trusty is too outdated.
