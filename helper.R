library(data.table)

# Create directory path name for results
get_results_dir <- function(base_path, network_name, pert_name, fraction, alg_name) {
  file.path(base_path, network_name, pert_name, as.character(fraction), alg_name)
}

# Save node metrics (moved)
save_node_metrics <- function(aggregated, dir_path, node_names = NULL) {
  dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
  
  if (is.null(aggregated$moved)) return(invisible(NULL))
  
  n_nodes <- length(aggregated$moved$mean)
  if (is.null(node_names)) node_names <- as.character(seq_len(n_nodes))
  
  dt <- data.frame(
    node = node_names,
    mean = aggregated$moved$mean,
    sd_total = sqrt(aggregated$moved$var.total),
    sd_between = sqrt(aggregated$moved$var.between),
    sd_within = sqrt(aggregated$moved$var.within),
    se = aggregated$moved$se
  )
  
  write.csv(dt, file.path(dir_path, "node_metrics.csv"), row.names = FALSE)
}

# Save scalar metrics (excluding moved)
save_scalar_metrics <- function(aggregated, dir_path) {
  dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
  
  # Exclude 'moved' metric
  scalar_metrics <- names(aggregated)[names(aggregated) != "moved"]
  
  rows <- lapply(scalar_metrics, function(m) {
    data.frame(
      metric = m,
      mean = aggregated[[m]]$mean,
      sd_total = sqrt(aggregated[[m]]$var.total),
      sd_between = sqrt(aggregated[[m]]$var.between),
      sd_within = sqrt(aggregated[[m]]$var.within),
      se = aggregated[[m]]$se
    )
  })
  
  dt <- do.call(rbind, rows)
  write.csv(dt, file.path(dir_path, "scalar_metrics.csv"), row.names = FALSE)
}

# Load scalar metrics
load_scalar_metrics <- function(dir_path) {
  fread(file.path(dir_path, "scalar_metrics.csv"))
}

# Load node metrics
load_node_metrics <- function(dir_path) {
  fread(file.path(dir_path, "node_metrics.csv"))
}