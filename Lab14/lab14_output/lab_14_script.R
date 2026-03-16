# Lab 14 script
# IMPORTANT: Set working directory to Lab14 before running.
# Example:
# setwd("/Users/dannyzweben/Desktop/GradClass/Y1/S2/StatsII/StatsII-Labs/Lab14")

options(scipen = 100)
options(digits = 3)

library(haven)
library(ggplot2)
library(labelled)
library(psych)
library(stargazer)

# Load data
load("ecls.rda")

# Problem 3: variable labels
attributes(ecls)["variable.labels"]

# Problem 4: z-standardized variables
z_read <- as.numeric(scale(ecls$c2rtscor))
z_income <- as.numeric(scale(ecls$wkincome))
z_kids <- as.numeric(scale(ecls$p2less18))

ecls$z_read <- z_read
ecls$z_income <- z_income
ecls$z_kids <- z_kids

# Problem 5: income in $1,000s
ecls$income_k <- ecls$wkincome / 1000

# Problem 6: complete-case subset
sub_ecls <- subset(
  ecls,
  !is.na(childid) & !is.na(c2rtscor) & !is.na(z_read) &
    !is.na(income_k) & !is.na(z_income) & !is.na(p2less18) & !is.na(z_kids),
  select = c(childid, c2rtscor, z_read, income_k, z_income, p2less18, z_kids)
)

# Problem 7: case counts
n_original <- nrow(ecls)
n_subset <- nrow(sub_ecls)
n_dropped <- n_original - n_subset

# Problem 8: remove full frame
rm(ecls)

# Problem 9: histograms
hist_read <- ggplot(sub_ecls, aes(c2rtscor)) +
  geom_histogram(aes(y = (..count..) * 100 / sum(..count..)), fill = "grey70", color = "black") +
  ylab("Percent") +
  xlab("Spring Kindergarten Reading Score (points)") +
  ggtitle("Distribution of Spring Kindergarten Reading Scores")

hist_income <- ggplot(sub_ecls, aes(income_k)) +
  geom_histogram(aes(y = (..count..) * 100 / sum(..count..)), fill = "grey70", color = "black") +
  ylab("Percent") +
  xlab("Family Income ($1,000s)") +
  ggtitle("Distribution of Family Income")

hist_kids <- ggplot(sub_ecls, aes(p2less18)) +
  geom_histogram(aes(y = (..count..) * 100 / sum(..count..)), fill = "grey70", color = "black") +
  ylab("Percent") +
  xlab("Number of Household Members Aged <18") +
  ggtitle("Distribution of Number of Children (<18)")

# Problem 10: raw models
m_income <- lm(c2rtscor ~ income_k, data = sub_ecls)
m_kids <- lm(c2rtscor ~ p2less18, data = sub_ecls)

# Problem 15: z models
m_income_z <- lm(z_read ~ z_income, data = sub_ecls)
m_kids_z <- lm(z_read ~ z_kids, data = sub_ecls)

# Save artifacts
if (!dir.exists("lab14_output")) dir.create("lab14_output", recursive = TRUE)

ggsave("lab14_output/fig_hist_reading.png", hist_read, width = 8, height = 5, dpi = 160)
ggsave("lab14_output/fig_hist_income.png", hist_income, width = 8, height = 5, dpi = 160)
ggsave("lab14_output/fig_hist_kids.png", hist_kids, width = 8, height = 5, dpi = 160)

write.csv(data.frame(
  n_original = n_original,
  n_subset = n_subset,
  n_dropped = n_dropped
), "lab14_output/case_counts.csv", row.names = FALSE)

write.csv(as.data.frame(coef(summary(m_income))), "lab14_output/model_income_raw.csv")
write.csv(as.data.frame(coef(summary(m_kids))), "lab14_output/model_kids_raw.csv")
write.csv(as.data.frame(coef(summary(m_income_z))), "lab14_output/model_income_z.csv")
write.csv(as.data.frame(coef(summary(m_kids_z))), "lab14_output/model_kids_z.csv")

# Text tables
capture.output(
  stargazer(
    m_income, m_kids,
    type = "text",
    report = "vcs*",
    title = "Bivariate Regressions Predicting Spring Kindergarten Reading Scores",
    dep.var.caption = "Outcome",
    dep.var.labels = c("Reading (points)", "Reading (points)"),
    covariate.labels = c("Family Income ($1,000s)", "Number of Household Members Aged <18"),
    star.cutoffs = c(0.05, 0.01, 0.001),
    star.char = c("*", "**", "***"),
    notes = "Stars: * p<.05; ** p<.01; *** p<.001",
    notes.append = FALSE
  ),
  file = "lab14_output/stargazer_raw.txt"
)

capture.output(
  stargazer(
    m_income_z, m_kids_z,
    type = "text",
    report = "vcs*",
    title = "Bivariate Regressions Predicting Reading Scores (SD Units)",
    dep.var.caption = "Outcome",
    dep.var.labels = c("Reading (SD)", "Reading (SD)"),
    covariate.labels = c("Family Income (SD)", "Number of Household Members Aged <18 (SD)"),
    star.cutoffs = c(0.05, 0.01, 0.001),
    star.char = c("*", "**", "***"),
    notes = "Stars: * p<.05; ** p<.01; *** p<.001",
    notes.append = FALSE
  ),
  file = "lab14_output/stargazer_z.txt"
)

# Preview
head(sub_ecls)
