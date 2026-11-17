# Two global-choice rules, expressed through the original simecol iteration engine.
stopifnot(requireNamespace("simecol", quietly = TRUE))
if (!methods::isClass("foragingExplorerModel")) {
  methods::setClass("foragingExplorerModel", representation(parms = "list", init = "list"), contains = "simObj")
}

historical_forest <- function() matrix(c(
  2,0,1,0,2,0,1,0,2,0,1,0,1,0,2,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,1,0,2,0,1,0,2,0,1,0,0,2,0,0,1,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,2,0,0,0,0,0,0,0,2,0,0,0,1,0,0,
  0,0,0,0,1,0,0,0,0,0,0,2,0,0,0,2,
  0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,
  0,2,0,1,0,2,0,0,0,1,0,1,0,2,0,1,
  0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0
), nrow = 9, ncol = 16, byrow = TRUE)

with_simulation_seed <- function(seed, expr) {
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) previous <- get(".Random.seed", envir = .GlobalEnv)
  on.exit(if (had_seed) assign(".Random.seed", previous, envir = .GlobalEnv)
          else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
            rm(".Random.seed", envir = .GlobalEnv))
  set.seed(seed)
  force(expr)
}

make_forager <- function(rule, forest, moves, target) {
  methods::new("foragingExplorerModel",
    main = function(time, init, parms) {
      init$time <- time
      init$choice <- NA_integer_
      init$revisit <- FALSE
      if (init$finished) return(init)
      eligible <- which(init$forest > 0 & (!parms$memory | !init$visited))
      if (!length(eligible)) { init$finished <- TRUE; return(init) }
      # sample.int also handles a singleton eligible set without sample(x)'s shortcut.
      choice <- eligible[sample.int(length(eligible), 1L)]
      init$choice <- choice
      init$revisit <- init$visited[choice]
      init$visited[choice] <- TRUE
      if (init$forest[choice] == 2L) {
        init$tally <- init$tally + 1L
        init$forest[choice] <- 3L
      }
      init$finished <- init$tally >= parms$target
      init
    },
    times = c(from = 0, to = moves, by = 1),
    parms = list(memory = identical(rule, "memory"), target = target),
    init = list(forest = forest, visited = matrix(FALSE, nrow(forest), ncol(forest)),
                tally = 0L, time = 0L, choice = NA_integer_, revisit = FALSE, finished = FALSE),
    solver = "iteration")
}

simulate_run <- function(rule = "memory", seed = 1L, moves = 35L, target = 10L,
                         forest = historical_forest()) {
  stopifnot(rule %in% c("random", "memory"), length(seed) == 1L, is.finite(seed),
            seed >= 0, seed <= .Machine$integer.max, moves >= 1, moves == as.integer(moves),
            target >= 1, target == as.integer(target), is.matrix(forest),
            all(forest %in% 0:2), sum(forest == 2L) >= target)
  states <- with_simulation_seed(seed, simecol::out(simecol::sim(make_forager(rule, forest, moves, target))))
  data.frame(move = as.integer(unlist(states$time)), tally = as.integer(unlist(states$tally)),
             choice = as.integer(unlist(states$choice)), revisit = as.logical(unlist(states$revisit)))
}

simulate_models <- function(n = 420L, seed = 20260919L, moves = 35L) {
  stopifnot(length(n) == 1L, is.finite(n), n >= 1, n <= 1000, n == as.integer(n),
            length(seed) == 1L, is.finite(seed), seed >= 0, seed <= .Machine$integer.max)
  rows <- lapply(c("random", "memory"), function(rule) {
    do.call(rbind, lapply(seq_len(n), function(i) {
      run_seed <- as.integer((seed + i * 104729 + if (rule == "memory") 1000003 else 0) %% 2147483646 + 1)
      curve <- simulate_run(rule, run_seed, moves)
      data.frame(model = rule, trajectory = paste(rule, i, sep = "-"), curve)
    }))
  })
  do.call(rbind, rows)
}
