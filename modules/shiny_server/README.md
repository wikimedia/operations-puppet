<!-- SPDX-License-Identifier: Apache-2.0 -->
# Shiny Server

[Shiny Server](https://www.rstudio.com/products/shiny/shiny-server/) enables
users to host and manage Shiny applications on the Internet.
[Shiny](https://www.rstudio.com/products/shiny/) is an R package that uses a
reactive programming model to simplify the development of R-powered web
applications. [RStudio](https://www.rstudio.com/) also provides an
[administrator's guide](http://docs.rstudio.com/shiny-server/) for Shiny Server.

The module creates a service "shiny-server" that serves Shiny applications from
/srv/shiny-server through port 3838.

The `notify` metaparameter is used to trigger a restart of the Shiny Server
service.
