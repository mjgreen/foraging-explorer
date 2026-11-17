library(simecol)
source("R/simulation.R")
forest <- historical_forest()
stopifnot(sum(forest > 0) == 30, sum(forest == 2) == 15)
set.seed(7); before <- .Random.seed
memory <- simulate_run("memory", 123)
random <- simulate_run("random", 123)
stopifnot(identical(before, .Random.seed),
          identical(memory, simulate_run("memory", 123)),
          !anyDuplicated(na.omit(memory$choice)), !any(memory$revisit), any(random$revisit),
          identical(memory$move, 0:35), memory$tally[1] == 0L, tail(memory$tally,1) == 10L)
for (d in list(memory, random)) {
  stopifnot(all(diff(d$tally) %in% 0:1), all(d$tally %in% 0:10))
  chosen_fruit <- unique(d$choice[!is.na(d$choice) & forest[d$choice] == 2])
  stopifnot(tail(d$tally,1) == length(chosen_fruit))
}
one <- simulate_run("memory", 5, forest = matrix(c(0,2),1), target = 1)
stopifnot(identical(one$tally, c(0L, rep(1L,35))), sum(!is.na(one$choice)) == 1)
a <- simulate_models(2, 8); b <- simulate_models(3, 8)
stopifnot(identical(a$trajectory, b$trajectory[b$trajectory %in% a$trajectory]),
          identical(a$tally, b$tally[b$trajectory %in% a$trajectory]),
          !identical(a$tally, simulate_models(2, 9)$tally))
source("R/benchmark.R")
benchmark <- load_benchmark()
expected <- if (benchmark$recorded) 817L else 200L
stopifnot(nrow(benchmark$curves) == expected * 36L,
          length(unique(benchmark$curves$trajectory)) == expected)
cat("Foraging rules, seed isolation, completion, nested runs and comparison structure passed\n")
