library(shiny)
library(ggplot2)
library(simecol)
source("R/simulation.R")
source("R/plotting.R")
source("R/benchmark.R")
benchmark <- load_benchmark()
human_curves <- benchmark$curves

ui <- fluidPage(title = "Foraging explorer | Matt Green",
  tags$head(tags$link(rel = "stylesheet", href = "explorer.css")),
  tags$div(class = "explorer-shell",
    tags$header(class = "page-header-custom",
      tags$a(class = "home-link", href = Sys.getenv("EXPLORER_HOME_URL", "https://mjgreen.uk/"), "← Matt Green"),
      tags$p(class = "eyebrow", "Simple rules · emergent behaviour"),
      tags$h1("Foraging explorer"),
      tags$p(class = "intro", if (benchmark$recorded) "Does avoiding revisits bring simulated search closer to human performance than random selection does?" else "Compare random selection with memory, alongside two clearly labelled synthetic reference patterns.")),
    tags$main(class = "explorer-grid",
      tags$aside(class = "foraging-controls panel", `aria-label` = "Agent settings",
        tags$div(class = "panel-heading", tags$span(class = "section-number", "01"), tags$h2("Choose a rule")),
        radioButtons("view", NULL, choices = c("Compare both" = "both", "Random selection" = "random", "Avoid revisits with memory" = "memory"), selected = "both"),
        tags$div(class = "rule-explanation", textOutput("rule_description")),
        tags$div(class = "forest-facts",
          tags$span(tags$strong("30"), "trees"), tags$span(tags$strong("15"), "fruit"), tags$span(tags$strong("10"), "to find")),
        tags$p(class = "control-note", "Both agents can choose any tree. A fruit can only be collected once."),
        tags$div(class = "run-controls",
          numericInput("runs", "Simulations per agent", value = 420, min = 20, max = 1000, step = 20),
          tags$details(class = "seed-settings", tags$summary("Reproducible settings"),
            numericInput("seed", "Random seed", value = 20260919, min = 0, max = 2147483646, step = 1),
            tags$p(class = "control-note", "The same settings and seed reproduce the same runs.")),
          actionButton("run", "Run simulations", class = "resample-button"),
          actionButton("new_runs", "New simulations", class = "secondary-button"),
          tags$p(class = "control-note", "Changing the view reuses the existing results. New simulations changes the random seed.")),
        tags$div(class = "benchmark-note", tags$h3(if (benchmark$recorded) "A fixed human comparison" else "Synthetic comparison"),
          tags$p(if (benchmark$recorded) "The human panels use recorded trials from the visual-foraging experiment. They stay the same as you explore the agents." else "The reference panels contain generated illustrations, not human observations. They stay fixed as you explore the agents."))),
      tags$section(class = "results", `aria-label` = if (benchmark$recorded) "Agent and human comparison" else "Agent and synthetic reference comparison",
        tags$div(class = "panel foraging-plot-panel",
          tags$div(class = "panel-heading", tags$span(class = "section-number", "02"), tags$h2("Compare the search")),
          tags$p(class = "plot-intro", "Each line is one search. A rise means another fruit was found; a flat section means no gain."),
          tags$div(class = "run-status", `aria-live` = "polite", textOutput("run_status")),
          plotOutput("comparison", height = "870px"),
          tags$p(class = "plot-caption", "Darker sections are shared by more searches. Searches stay at 10 after completion. Move number is a search index, not elapsed time.")),
        tags$section(class = "panel sample-panel", tags$h2("What can these rules capture?"),
          tags$p(if (benchmark$recorded) "Compare how quickly the lines rise and how widely they spread. Does avoiding revisits look closer to the dispersed human condition? Does either rule capture the variation in the patchy condition?" else "Compare how quickly the lines rise and how widely they spread. The synthetic reference patterns illustrate different search timings; resemblance to them is not a model fit or a result about people."),
          tags$p("These agents use no information about distance or patches. With the same numbers of trees and fruit, spatial rearrangement does not change their expected performance. Similar curves alone do not establish that humans use the same rule.")),
        tags$details(class = "panel detail-panel", tags$summary(if (benchmark$recorded) "About the models and human data" else "About the models and synthetic references"),
          tags$div(class = "detail-content",
            tags$h3("The rules"),
            tags$p("Random selection chooses uniformly among all trees, including ones already visited. Perfect memory remembers every visited tree for the entire search, including fruitless trees, and chooses uniformly from those not yet visited. Each simulation starts with a fresh forest and memory. Both stop collecting at 10 fruit; the display continues to move 35."),
            tags$h3("What a move means"),
            tags$p(if (benchmark$recorded) "An agent move is one tree choice, including an immediate revisit. Human moves are tree visits reconstructed from gaze records: consecutive samples on the same tree are collapsed. This follows the original comparison but is an operational difference to bear in mind when interpreting similarity." else "An agent move is one tree choice, including an immediate revisit. Synthetic reference moves are illustrative indices generated without eye-tracking data or elapsed times."),
            tags$h3(if (benchmark$recorded) "The human benchmark" else "The synthetic references"),
            tags$p(if (benchmark$recorded) "The benchmark contains 407 dispersed and 410 patchy trials from 42 participants. The existing analysis retains trials with 10 recorded fruit-collection events; 23 of the 840 recorded trials do not meet that criterion. Records are sorted by timestamp before visits are reconstructed. Only anonymous trajectory identifiers, condition, move and fruit tally are included here." else "Each reference contains 100 generated searches. Ten collection moves are selected by a deterministic hash ordering: reference A draws from moves 1–24 and reference B from moves 1–35. These arbitrary illustrative patterns were not derived from participant observations or fitted to the simulation."),
            tags$p(if (benchmark$recorded) "All retained trials finish within 35 visits. Their known final tally is carried forward to 35 for comparison. The agents use the historical abstract forest with the same 30-tree/15-fruit counts; they are not fitted individually to each human trial." else "Every reference reaches ten fruit, then keeps its final tally through move 35. The private human comparison used by the hosted app is not included in this public distribution."),
            tags$h3("From the original demonstration"),
            tags$p("This app develops Matt Green’s R/simecol demonstration. It uses uniform tree selection, corrects the forest’s row orientation, stops explicitly at 10 fruit and plots cumulative values without jitter. The exploratory simulations are distinct from the published human experiments."),
            tags$a(href = "https://doi.org/10.1007/s10339-025-01261-0", "Read the visual-foraging paper ↗"))))),
    tags$footer("Made by Matt Green · R / Shiny / simecol")))

server <- function(input, output, session) {
  # Results change only on an explicit simulation action. Display choices are cheap redraws.
  results <- reactiveVal(NULL)
  run_models <- function(n, seed) {
    if (length(n) != 1L || !is.finite(n) || n < 20 || n > 1000 || n != floor(n)) {
      showNotification("Choose a whole number from 20 to 1,000 simulations.", type = "error")
      return(invisible(NULL))
    }
    if (length(seed) != 1L || !is.finite(seed) || seed < 0 || seed >= .Machine$integer.max || seed != floor(seed)) {
      showNotification("Use a whole-number seed between 0 and 2,147,483,646.", type = "error")
      return(invisible(NULL))
    }
    old <- results()
    if (!is.null(old) && identical(old$n, n) && identical(old$seed, seed)) return(invisible(NULL))
    withProgress(message = "Simulating searches", value = .2, {
      data <- simulate_models(n, seed)
      incProgress(.8)
      results(list(data = data, n = n, seed = seed))
    })
  }
  observeEvent(TRUE, { run_models(420, 20260919) }, once = TRUE)
  observeEvent(input$run, { req(input$runs, !is.null(input$seed)); run_models(input$runs, input$seed) }, ignoreInit = TRUE)
  observeEvent(input$new_runs, {
    req(input$runs, !is.null(input$seed))
    seed <- (input$seed + 1) %% 2147483647
    updateNumericInput(session, "seed", value = seed)
    run_models(input$runs, seed)
  }, ignoreInit = TRUE)
  output$rule_description <- renderText(switch(input$view,
    random = "Choose freely, even if you have been there before.",
    memory = "Remember every tree you visit. Choose only among unvisited trees.",
    "One difference: can the agent return to a tree it has already visited?"))
  output$run_status <- renderText({
    result <- req(results())
    pending <- !isTRUE(input$runs == result$n && input$seed == result$seed)
    paste0("Showing ", result$n, " simulations per agent · Seed ", result$seed,
           if(pending) " · Settings changed: run to apply." else "")
  })
  output$comparison <- renderPlot({
    result <- req(results())
    comparison_plot(result$data, human_curves, input$view,
                    narrow = isTRUE(session$clientData$output_comparison_width < 500),
                    benchmark_labels = benchmark$labels, benchmark_units = benchmark$units)
  }, res = 100, alt = if (benchmark$recorded) "Cumulative fruit collected against search moves, comparing random selection and perfect-memory agents with fixed human dispersed and patchy trials. Each translucent line is one search." else "Cumulative fruit collected against search moves, comparing random selection and perfect-memory agents with two synthetic reference patterns. No participant data are shown. Each translucent line is one search.")
}
shinyApp(ui, server)
