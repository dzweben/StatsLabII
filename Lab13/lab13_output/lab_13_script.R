# Lab 13 script
# IMPORTANT: Set working directory to the Lab13 folder before running.
# Example:
# setwd("/Users/dannyzweben/Desktop/GradClass/Y1/S2/StatsII/StatsII-Labs/Lab13")

options(scipen = 100)
options(digits = 3)

library(ggplot2)
library(pastecs)

# local helper
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# Load Wilcox functions from local file when available.
if (file.exists("Rallfun-v45.txt")) {
  source("Rallfun-v45.txt")
} else {
  source("https://osf.io/download/98b7r/")
}

# Load state-level data.
load("stdata_v2.rda")

# Problem 6: variable labels (source labels from each column attribute).
var_labels <- data.frame(
  variable = names(stdata),
  label = vapply(stdata, function(x) attr(x, "label") %||% NA_character_, character(1)),
  stringsAsFactors = FALSE
)

# Problem 7: construct rates.
stdata$edspend_pp <- (stdata$edspend * 1000) / stdata$schpopco
stdata$execrate_10m <- (stdata$executco / stdata$popco) * 10000000
stdata$homrate_100k <- (stdata$murdco / stdata$popco) * 100000

# Problem 8: normality checks.
norm_edu_read <- stat.desc(stdata[c("edspend_pp", "read8th")], norm = TRUE)
norm_hom_exec <- stat.desc(stdata[c("homrate_100k", "execrate_10m")], norm = TRUE)

# Problem 9: histograms.
hist_edspend <- ggplot(stdata, aes(x = edspend_pp)) +
  geom_histogram(
    breaks = seq(3000, 10200, by = 500),
    aes(y = (..count..) * 100 / sum(..count..)),
    fill = "grey70",
    color = "black"
  ) +
  ggtitle("Distribution of State Education Spending per Pupil") +
  xlab("Education Spending per Pupil (US dollars)") +
  ylab("Percent of States")

hist_read <- ggplot(stdata, aes(x = read8th)) +
  geom_histogram(
    breaks = seq(236, 276, by = 2),
    aes(y = (..count..) * 100 / sum(..count..)),
    fill = "grey70",
    color = "black"
  ) +
  ggtitle("Distribution of 8th Grade Reading Scores") +
  xlab("8th Grade Reading Score (NAEP points)") +
  ylab("Percent of States")

hist_hom <- ggplot(stdata, aes(x = homrate_100k)) +
  geom_histogram(
    breaks = seq(0, 36, by = 2),
    aes(y = (..count..) * 100 / sum(..count..)),
    fill = "grey70",
    color = "black"
  ) +
  ggtitle("Distribution of Homicide Rate") +
  xlab("Homicides per 100,000 residents") +
  ylab("Percent of States")

hist_exec <- ggplot(stdata, aes(x = execrate_10m)) +
  geom_histogram(
    breaks = seq(0, 12, by = 0.75),
    aes(y = (..count..) * 100 / sum(..count..)),
    fill = "grey70",
    color = "black"
  ) +
  ggtitle("Distribution of Execution Rate") +
  xlab("Executions per 10,000,000 residents") +
  ylab("Percent of States")

# Problem 10: scatterplots with loess lines.
scat_edu_read <- ggplot(stdata, aes(x = edspend_pp, y = read8th)) +
  geom_point(color = "black") +
  geom_smooth(method = "loess", se = FALSE, color = "dodgerblue4") +
  ggtitle("Education Spending per Pupil and Reading Scores") +
  xlab("Education Spending per Pupil (US dollars)") +
  ylab("8th Grade Reading Score (NAEP points)") +
  ylim(c(236, 276)) +
  xlim(c(3000, 10200))

scat_exec_hom <- ggplot(stdata, aes(x = execrate_10m, y = homrate_100k)) +
  geom_point(color = "black") +
  geom_smooth(method = "loess", se = FALSE, color = "dodgerblue4") +
  ggtitle("Execution Rates and Homicide Rates") +
  xlab("Executions per 10,000,000 residents") +
  ylab("Homicides per 100,000 residents") +
  ylim(c(0, 36)) +
  xlim(c(0, 12))

# Problem 12: Pearson and 20% Winsorized correlations.
pear_edu_read <- wincor(stdata$edspend_pp, stdata$read8th, tr = 0)
win_edu_read <- wincor(stdata$edspend_pp, stdata$read8th, tr = .2)
pear_hom_exec <- wincor(stdata$homrate_100k, stdata$execrate_10m, tr = 0)
win_hom_exec <- wincor(stdata$homrate_100k, stdata$execrate_10m, tr = .2)

# Save key artifacts.
if (!dir.exists("lab13_output")) dir.create("lab13_output", recursive = TRUE)

write.csv(var_labels, "lab13_output/variable_labels.csv", row.names = FALSE)
write.csv(norm_edu_read, "lab13_output/norm_edu_read.csv")
write.csv(norm_hom_exec, "lab13_output/norm_hom_exec.csv")

cor_out <- data.frame(
  pair = c("Education-Reading", "Education-Reading", "Homicide-Execution", "Homicide-Execution"),
  type = c("Pearson", "Winsorized_20pct", "Pearson", "Winsorized_20pct"),
  r = c(pear_edu_read$cor, win_edu_read$cor, pear_hom_exec$cor, win_hom_exec$cor),
  p = c(pear_edu_read$p.value, win_edu_read$p.value, pear_hom_exec$p.value, win_hom_exec$p.value)
)
write.csv(cor_out, "lab13_output/correlations.csv", row.names = FALSE)

ggsave("lab13_output/fig_hist_edspend_pp.png", hist_edspend, width = 8, height = 5, dpi = 160)
ggsave("lab13_output/fig_hist_read8th.png", hist_read, width = 8, height = 5, dpi = 160)
ggsave("lab13_output/fig_hist_homrate.png", hist_hom, width = 8, height = 5, dpi = 160)
ggsave("lab13_output/fig_hist_execrate.png", hist_exec, width = 8, height = 5, dpi = 160)
ggsave("lab13_output/fig_scatter_edu_read.png", scat_edu_read, width = 8, height = 5, dpi = 160)
ggsave("lab13_output/fig_scatter_exec_hom.png", scat_exec_hom, width = 8, height = 5, dpi = 160)

# Snippet preview (avoid printing full data frame).
head(stdata[c("abbr", "edspend_pp", "read8th", "homrate_100k", "execrate_10m")])

# Preferred (winsorized) publication-style lines.
cat(
  sprintf(
    "Winsorized correlation: education spending per pupil and reading scores, r_w = %.3f, p = %.3f.\n",
    win_edu_read$cor, win_edu_read$p.value
  )
)
cat(
  sprintf(
    "Winsorized correlation: homicide and execution rates, r_w = %.3f, p = %.3f.\n",
    win_hom_exec$cor, win_hom_exec$p.value
  )
)
