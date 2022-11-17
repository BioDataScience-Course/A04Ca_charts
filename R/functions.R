# Functions to calculate scores based on pixel to pixel correlation
# Copyright (c) 2021 Ph. Grosjean (phgrosjean@sciviews.org)

repository <- sub("\\.git$", "", basename(usethis::git_remotes()$origin))
svMisc::assign_temp("scores", numeric(20L), replace.existing = TRUE)
reference_dir <- here::here("docs", "figures")
output_dir <- here::here("docs", "challenge_graphiques_files", 'figure-html')
results_dir <- here::here("results")
unlink(dir(output_dir, pattern = "\\.png$"))

#' Calculate the score for one chart
#'
#' @param chart The number from 1 to 20 of the chart
#' @param ref_dir The directory containing the reference image
#' @param out_dir The directory containing the produced chart
#'
#' @return A score from 0 to 1
#' @export
#'
#' @examples
#' score_one(1) # Get score for first chart
score_chart <- function(chart, ref_dir = reference_dir, out_dir = output_dir) {
  chart <- as.integer(chart)[1]
  if (chart < 1 | chart > 20)
    stop("argument chart = must be an integer between 1 and 20")
  # Get vector of scores
  scores <- svMisc::get_temp("scores", default = NULL)
  if (is.null(scores))
    stop("scores not found")
  # Filename
  chartfile <- sprintf("chart%02.0f-1.png", chart)
  # Read reference chart
  reffile <- file.path(ref_dir, chartfile)
  if (!file.exists(reffile))
    stop("The reference image for chart ", chart, " is not found")
  ref <- png::readPNG(reffile)[, , 1:3] # Do not use alpha channel
  # Is a chart produced?
  outfile <- file.path(out_dir, chartfile)
  if (file.exists(outfile)) {
    out <- png::readPNG(outfile)[, , 1:3] # Do not use alpha channel
    score <- try(cor(ref, out), silent = TRUE)
    if (inherits(score, "try-error"))
      score <- 0
  } else {
    score <- 0
  }
  # Record the score and return it
  scores[chart] <- score
  svMisc::assign_temp("scores", scores, replace.existing = TRUE)
  score
}


#' Calculate the global score for all charts
#'
#' @param res_dir The directory where to place the results
#' @param repos The current GitHub repository
#'
#' @return
#' @export
#'
#' @examples
score_all_charts <- function(res_dir = results_dir, repos = repository) {
  scores <- svMisc::get_temp("scores", default = NULL)
  if (is.null(scores))
    stop("scores not found")
  # Get an id and file name, according to current files in results
  all_res <- dir(res_dir, full.names = FALSE,
    pattern = paste0("^", repos, "__[0-9]{3}\\.rds$"))
  if (!length(all_res)) {
    id <- "001"
  } else {
    last_res <- sort(all_res, decreasing = TRUE)[1]
    last_id <-
      sub("^.+__([0-9]{3})\\.rds$", "\\1", last_res)
    id <- sprintf("%03.0f", as.integer(last_id) + 1)
  }
  file <- glue::glue("{repos}__{id}.rds")
  attr(scores, "id") <- id
  attr(scores, "file") <- file
  # Save the results file (only if score > 0)
  if (sum(scores) > 0) {
    resfile <- file.path(res_dir, file)
    write$rds(scores, file = resfile)
  }
  scores
}
