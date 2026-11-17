# Keep the private, recorded comparison separate from the distributable demo.
load_benchmark <- function(human_path = "data/human-curves.csv",
                           demo_path = "data/synthetic-curves.csv") {
  recorded <- file.exists(human_path)
  path <- if (recorded) human_path else demo_path
  if (!file.exists(path)) stop("No comparison data found. Use the complete distribution, including data/.")
  curves <- read.csv(path, stringsAsFactors = FALSE)
  stopifnot(identical(names(curves), c("trajectory", "condition", "move", "tally")),
            nrow(curves) > 0L, !anyNA(curves), all(curves$tally %in% 0:10))
  labels <- if (recorded) c(dispersed = "Human · dispersed", patchy = "Human · patchy") else
    c(reference_a = "Synthetic reference A", reference_b = "Synthetic reference B")
  stopifnot(setequal(unique(curves$condition), names(labels)))
  for (trajectory in split(curves, curves$trajectory)) {
    stopifnot(length(unique(trajectory$condition)) == 1L,
              identical(trajectory$move, 0:35), trajectory$tally[1] == 0L,
              all(diff(trajectory$tally) %in% 0:1), tail(trajectory$tally, 1) == 10L)
  }
  list(curves = curves, labels = labels, recorded = recorded,
       units = if (recorded) "trials" else "generated searches")
}
