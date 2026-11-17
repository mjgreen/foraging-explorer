stopifnot(file.exists("app.R"), dir.exists(".foraging-library"))
.libPaths(c(normalizePath(".foraging-library"), .libPaths()))
options(shiny.useragg = FALSE, shiny.usecairo = FALSE)
args <- commandArgs(trailingOnly = TRUE)
if (length(args) && !all(grepl("^--(host|port)=", args))) stop("Use --host=ADDRESS and/or --port=NUMBER")
value <- function(name, default) {
  matches <- args[startsWith(args, paste0("--", name, "="))]
  if (length(matches) > 1L) stop("Duplicate option: ", name)
  if (length(matches)) sub(paste0("^--", name, "="), "", matches) else default
}
host <- value("host", "127.0.0.1")
port <- suppressWarnings(as.integer(value("port", "3842")))
stopifnot(length(port) == 1L, !is.na(port), port >= 1024L, port <= 65535L)
shiny::runApp(".", host = host, port = port, launch.browser = FALSE)
