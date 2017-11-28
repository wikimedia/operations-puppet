# Source: https://bioconductor.org/biocLite.R
options("repos" = c(CRAN = "https://cloud.r-project.org"))

## Mirrors: uncomment the following and change to your favorite Bioconductor
## mirror, if you don't want to use the default (bioconductor.org)
# options("BioC_mirror" = "https://bioconductor.org")

local({

    vers <- getRversion()
    biocVers <- tryCatch({
        BiocInstaller::biocVersion() # recent BiocInstaller
    }, error=function(...) {         # no / older BiocInstaller
        BioC_version_associated_with_R_version <-
            get(".BioC_version_associated_with_R_version",
                envir=asNamespace("tools"), inherits=FALSE)
        if (is.function(BioC_version_associated_with_R_version))
            BioC_version_associated_with_R_version()
        else                            # numeric_version
            BioC_version_associated_with_R_version
    })

    if (vers < "3.0") {
        ## legacy; no need to change "3.0" ever
        ## coordinate this message with .onAttach
        txt <- strwrap("A new version of Bioconductor is available
            after installing the most recent version of R; see
            http://bioconductor.org/install", exdent=2)
        message(paste(txt, collapse="\n"))
    } else if ("package:BiocInstaller" %in% search()) {
        ## messages even if already attached
        tryCatch(BiocInstaller:::.onAttach(), error=function(...) NULL)
    }

    if (vers > "2.13" && biocVers > "2.8") {

        if (exists("biocLite", .GlobalEnv, inherits=FALSE)) {
            txt <- strwrap("There is an outdated biocLite() function in the
                global environment; run 'rm(biocLite)' and try again.")
            stop("\n", paste(txt, collapse="\n"))
        }

        if (!suppressWarnings(require("BiocInstaller", quietly=TRUE))) {
            a <- NULL
            p <- file.path(Sys.getenv("HOME"), ".R", "repositories")
            if (file.exists(p)) {
                a <- tools:::.read_repositories(p)
                if (!"BioCsoft" %in% rownames(a)) 
                    a <- NULL
            }
            if (is.null(a)) {
                p <- file.path(R.home("etc"), "repositories")
                a <- tools:::.read_repositories(p)
            }
            if (!"package:utils" %in% search()) {
                path <- "//bioconductor.org/biocLite.R"
                txt <- sprintf("use 'source(\"https:%s\")' or
                    'source(\"http:%s\")' to update 'BiocInstaller' after
                    library(\"utils\")", path, path)
                message(paste(strwrap(txt), collapse="\n  "))
            } else {
                ## add a conditional for Bioc releases occuring WITHIN
                ## a single R minor version. This is so that a user with a
                ## version of R (whose etc/repositories file references the
                ## no-longer-latest URL) and without BiocInstaller
                ## will be pointed to the most recent repository suitable
                ## for their version of R
                if (vers >= "3.2.2" && vers < "3.3.0") {
                    ## transitioning to https support; check availability
                    con <- file(fl <- tempfile(), "w")
                    sink(con, type="message")
                    tryCatch({
                        xx <- close(file("https://bioconductor.org"))
                    }, error=function(e) {
                        message(conditionMessage(e))
                    })
                    sink(type="message")
                    close(con)
                    if (!length(readLines(fl)))
                        a["BioCsoft", "URL"] <-
                            sub("^http:", "https:", a["BioCsoft", "URL"])
                }
                if (vers >= "3.4") {
                    a["BioCsoft", "URL"] <- sub(as.character(biocVers), "3.5",
                      a["BioCsoft", "URL"]) 
                } else if (vers >= "3.3.0") {
                    a["BioCsoft", "URL"] <- sub(as.character(biocVers), "3.4",
                      a["BioCsoft", "URL"]) 
                } else if (vers >= "3.2") {
                    a["BioCsoft", "URL"] <- sub(as.character(biocVers), "3.2",
                      a["BioCsoft", "URL"])
                } else if (vers == "3.1.1") {
                    ## R-3.1.1's etc/repositories file at the time of the release 
                    ## of Bioc 3.0 pointed to the 2.14 repository, but we want 
                    ## new installations to access the 3.0 repository
                    a["BioCsoft", "URL"] <- sub(as.character(biocVers), "3.0",
                      a["BioCsoft", "URL"])
                } else if (vers == "3.1.0") {
                    ## R-devel points to 2.14 repository
                    a["BioCsoft", "URL"] <- sub(as.character(biocVers), "2.14",
                      a["BioCsoft", "URL"])
                } else if (vers >= "2.15" && vers < "2.16") {
                    a["BioCsoft", "URL"] <- sub(as.character(biocVers), "2.11",
                      a["BioCsoft", "URL"])
                    biocVers <- numeric_version("2.11")
                }
                install.packages("BiocInstaller", repos=a["BioCsoft", "URL"])
                if (!suppressWarnings(require("BiocInstaller",
                                              quietly=TRUE))) {
                    path0 <- "//bioconductor.org/packages"
                    path <- sprintf("%s/%s/bioc", path0, as.character(biocVers))
                    txt0 <- "'biocLite.R' failed to install 'BiocInstaller',
                        use 'install.packages(\"BiocInstaller\",
                        repos=\"https:%s\")' or
                        'install.packages(\"BiocInstaller\", repos=\"http:%s\")'"
                    txt <- sprintf(txt0, path, path)
                    message(paste(strwrap(txt), collapse="\n  "))
                }
            }
        } else {
             ## BiocInstaller version 1.16.0-1.18.1 do not
             ## automatically update when type=="source"; notify users
             ## when they have updated R over their old libraries
             installerVersion <- utils::packageVersion("BiocInstaller")
             test0 <- (vers > "3.1.2") &&
                 !identical(getOption("pkgType"), "source") &&
                     (installerVersion >= "1.16.0") &&
                         (installerVersion <= "1.16.4")
             if (test0) {
                 if (installerVersion < "1.16.4") {
                     txt <- "Update BiocInstaller with
                         oldPkgType=options(pkgType=\"source\");
                         biocLite(\"BiocInstaller\"); options(oldPkgType)"
                     message(paste(strwrap(txt, exdent=2), collapse="\n"))
                 }
                 if (vers >= "3.2") {
                     path <- "//bioconductor.org/biocLite.R"
                     txt <- sprintf("BiocInstaller version %s is too old for
                         R version %s; remove.packages(\"BiocInstaller\"),
                         re-start R, then source(\"https:%s\") or
                         source(\"http:%s\")", biocVers, vers, path, path)
                     warning(paste(strwrap(txt, exdent=2), collapse="\n"))
                 }
             }
         }
    } else {
        tryCatch({
            source("https://bioconductor.org/getBioC.R")
        }, error=function(e) {
            warning("https: failed (", conditionMessage(e), "), trying http",
                    immediate.=TRUE)
            source("http://bioconductor.org/getBioC.R")
        })
        biocLite <<-
            function(pkgs, groupName="lite", ...)
            {
                if (missing(pkgs))
                    biocinstall(groupName=groupName, ...)
                else
                    biocinstall(pkgs=pkgs, groupName=groupName, ...)
            }
    }
})
