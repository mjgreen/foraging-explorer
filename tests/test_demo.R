source("R/benchmark.R")
if (!file.exists("data/human-curves.csv")) {
  benchmark <- load_benchmark()
  stopifnot(!benchmark$recorded, nrow(benchmark$curves) == 200L * 36L,
            all(startsWith(benchmark$curves$trajectory, "synthetic-")))
  app <- new.env(parent = globalenv())
  source("app.R", local = app)
  rendered <- as.character(app$ui)
  stopifnot(grepl("Synthetic comparison", rendered, fixed = TRUE),
            !grepl("407 dispersed", rendered, fixed = TRUE),
            !grepl("42 participants", rendered, fixed = TRUE),
            grepl("not human observations", rendered, fixed = TRUE))
  plot <- comparison_plot(simulate_models(2, 17), benchmark$curves,
                          benchmark_labels = benchmark$labels,
                          benchmark_units = benchmark$units)
  built <- ggplot2::ggplot_build(plot)
  stopifnot(nrow(built$layout$layout) == 4L,
            identical(names(benchmark$labels), c("reference_a", "reference_b")))
  cat("Synthetic-only distribution, visible labelling and four-panel plot checks passed\n")
}
