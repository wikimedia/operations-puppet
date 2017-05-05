#!/usr/bin/env Rscript

suppressPackageStartupMessages(library("optparse"))

option_list <- list(
  make_option(c("-p", "--package"), default = NA,
              action = "store", type = "character",
              help = "If missing, will update all packages installed from CRAN."),
  make_option("--mirror", default = "https://cloud.r-project.org",
              action = "store", type = "character",
              help = "The CRAN mirror to use [default %default].
                See https://cran.r-project.org/mirrors.html for more")
)

# Get command line options, if help option encountered print help and exit,
# otherwise if options not found on command line then set defaults:
opt <- parse_args(OptionParser(option_list = option_list))

if (is.na(opt$package)) {
  update.packages(ask = FALSE, checkBuilt = TRUE, repos = c(CRAN = opt$mirror))
  message("If any CRAN-installed packages were updated, restart shiny-server")
  message("To update all git-installed package, run devtools::update_packages()")
  message("Unfortunately, it must be run in interactive mode")
  q(save = "no", status = 0)
}

if (!opt$package %in% installed.packages()[, "Package"]) {
  message(args[1], " is not an installed package")
  q(save = "no", status = 3) # because package is not installed
}

# A helper function for extracting a parameter
# from an installed package's DESCRIPTION file
extract_param <- function(DESCRIPTION, param) {
  return(
    sub(paste0(param, ": "), "", DESCRIPTION[grepl(param, DESCRIPTION)], fixed = TRUE)
  )
}

# Read the installed version's DESCRIPTION file:
pkg_description <- readLines(file.path(find.package(opt$package), "DESCRIPTION"))

# Extract some metadata (e.g. where the package was installed from):
if (any(grepl("Repository: CRAN", pkg_description))) {
  pkg_source <- "cran"
  message(args[1], "is ")
} else if (any(grepl("RemoteType", pkg_description))) {
  pkg_source <- extract_param(pkg_description, "RemoteType")
  if (pkg_source == "github") {
    pkg_url <- paste(
      extract_param(pkg_description, "GithubUsername"),
      extract_param(pkg_description, "GithubRepo"),
      sep = "/"
    )
    pkg_sha <- extract_param(pkg_description, "GithubSHA1")
    remote_sha <- git2r::remote_ls(paste0("https://github.com/", pkg_url))["refs/heads/master"]
  } else if (pkg_source == "git") {
    pkg_url <- extract_param(pkg_description, "RemoteUrl")
    pkg_sha <- extract_param(pkg_description, "RemoteSha")
    remote_sha <- git2r::remote_ls(pkg_url)["refs/heads/master"]
  }
}

update_pkg <- FALSE
if (pkg_source %in% c("github", "git")) {
  if (pkg_sha != remote_sha) {
    message("Installed version's SHA differets from remote version's SHA")
    update_pkg <- TRUE
  }
}

if (pkg_source == "cran" || update_pkg) {
  update_output <- devtools::update_packages(opt$package, repos = c(CRAN = opt$mirror))
  if (length(update_output) == 0) {
    message("No update was necessary for ", opt$package)
    q(save = "no", status = 1)
  } else {
    if (update_output) {
      message("Successfully updated ", opt$package, ". Now run: sudo restart shiny-server")
      q(save = "no", status = 0)
    } else {
      message("Attempted to update ", opt$package, " but failed")
      q(save = "no", status = 2)
    }
  }
}
