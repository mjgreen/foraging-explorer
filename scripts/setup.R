# Project-local package installation; no global R configuration is changed.
stopifnot(file.exists("app.R"), file.exists("renv.lock"))
if (getRversion() != "4.5.1") warning("The locked and container-tested runtime is R 4.5.1; this R version is unverified.")
library_path <- normalizePath(".foraging-library", mustWork = FALSE)
dir.create(library_path, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(library_path, .libPaths()))
options(repos = c(CRAN = "https://cloud.r-project.org"), timeout = 600)
Sys.setenv(RENV_CONFIG_CACHE_ENABLED = "FALSE", RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
if (!requireNamespace("renv", quietly = TRUE) || packageVersion("renv") != "1.1.5") {
  install.packages("https://cloud.r-project.org/src/contrib/Archive/renv/renv_1.1.5.tar.gz",
                   repos = NULL, type = "source", lib = library_path)
}
renv::restore(project = ".", library = library_path, lockfile = "renv.lock", prompt = FALSE)
cat("Project library ready. Run Rscript --vanilla scripts/run.R\n")
