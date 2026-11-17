model_labels <- c(random = "Random selection", memory = "Avoid revisits · perfect memory",
                  dispersed = "Human · dispersed", patchy = "Human · patchy")
model_colours <- c(random = "#B16142", memory = "#42795A", dispersed = "#277E96", patchy = "#8562A8",
                   reference_a = "#277E96", reference_b = "#8562A8")

comparison_plot <- function(simulations, humans, view = "both", narrow = FALSE,
                            benchmark_labels = model_labels[c("dispersed", "patchy")],
                            benchmark_units = "trials") {
  keep <- if (view == "both") c("random", "memory") else view
  agent <- simulations[simulations$model %in% keep, c("model", "trajectory", "move", "tally")]
  human <- data.frame(model = humans$condition, humans[c("trajectory", "move", "tally")])
  data <- rbind(agent, human)
  order <- c(keep, names(benchmark_labels))
  labels_by_model <- c(model_labels[c("random", "memory")], benchmark_labels)
  counts <- vapply(order, function(m) length(unique(data$trajectory[data$model == m])), integer(1))
  data$opacity <- pmin(0.5, 30 / counts[match(data$model, order)])
  labels <- setNames(paste0(labels_by_model[order], if(narrow) "\n" else "  |  ", counts,
                            ifelse(order %in% c("random", "memory"), " simulations", paste0(" ", benchmark_units))), order)
  data$model <- factor(data$model, levels = order)
  ggplot2::ggplot(data, ggplot2::aes(move, tally, group = trajectory, colour = model)) +
    ggplot2::geom_line(ggplot2::aes(alpha = opacity), linewidth = 0.3) +
    ggplot2::scale_alpha_identity() +
    ggplot2::facet_wrap(~model, ncol = 1, labeller = ggplot2::as_labeller(labels)) +
    ggplot2::scale_colour_manual(values = model_colours) +
    ggplot2::scale_x_continuous(breaks = c(0, 10, 20, 30, 35), limits = c(0, 35), expand = ggplot2::expansion(mult = c(.01,.015))) +
    ggplot2::scale_y_continuous(breaks = c(0, 5, 10), limits = c(0,10), expand = ggplot2::expansion(mult = c(.025,.04))) +
    ggplot2::labs(x = "Search moves", y = "Fruit collected") +
    ggplot2::theme_minimal(base_size = if(narrow) 10 else 12) +
    ggplot2::theme(legend.position = "none", panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = "#E9EDE9", linewidth = .35),
      strip.text = ggplot2::element_text(hjust = 0, face = "bold", colour = "#173D34", size = if(narrow) 9 else 11),
      strip.background = ggplot2::element_rect(fill = "#F3F6EE", colour = NA),
      panel.spacing = grid::unit(16, "pt"), axis.text = ggplot2::element_text(colour = "#43574F"),
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = 10)),
      plot.margin = ggplot2::margin(6, 8, 6, 4),
      plot.background = ggplot2::element_rect(fill = "white", colour = NA))
}
