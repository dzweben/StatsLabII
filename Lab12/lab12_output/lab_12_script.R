# Lab 12 script
# IMPORTANT: set your working directory to the Lab12 folder before running.
# Example:
# setwd("/Users/dannyzweben/Desktop/GradClass/Y1/S2/StatsII/StatsII-Labs/Lab12")

# Packages
library(afex)
library(emmeans)
library(haven)
library(tidyverse)

# Data
load("relax.rda")

# Wide to long
long <- pivot_longer(r, cols = c(sept, nov, april, june, july),
                     names_to = "month",
                     values_to = "siga")
long <- as.data.frame(long)

# Factors
long$month <- factor(long$month, levels = c("sept", "nov", "april", "june", "july"))
long$treatmentf <- factor(long$treatmentf)

# Omnibus split-plot ANOVA
model <- aov_car(siga ~ month * treatmentf + Error(ID/month), data = long)
summary(model)

# Emmeans
em_month <- emmeans(model, ~ month)
em_treat <- emmeans(model, ~ treatmentf)
em_cell  <- emmeans(model, ~ month * treatmentf)

# Cell dataframe
cell_df <- as.data.frame(em_cell)

# Excel-style table
cell_wide <- cell_df %>%
  select(treatmentf, month, emmean) %>%
  pivot_wider(names_from = month, values_from = emmean)
month_means <- as.data.frame(em_month)
month_means <- month_means[match(c("sept", "nov", "april", "june", "july"), month_means$month), ]
cell_wide$Mean <- as.data.frame(em_treat)$emmean
mean_row <- data.frame(
  treatmentf = "Month Mean",
  sept = month_means$emmean[1],
  nov = month_means$emmean[2],
  april = month_means$emmean[3],
  june = month_means$emmean[4],
  july = month_means$emmean[5],
  Mean = mean(month_means$emmean)
)

# Plot factor labels
cell_df$month_f <- factor(cell_df$month,
                          levels = c("sept", "nov", "april", "june", "july"),
                          labels = c("September", "November", "April", "June", "July"))

# Plot
plot_obj <- ggplot(data = cell_df, aes(x = month_f, y = emmean, color = treatmentf, group = treatmentf)) +
  geom_line() +
  geom_point() +
  labs(title = "s-IgA Over Time by Treatment",
       x = "Month",
       y = "s-IgA (mg/min)",
       color = "Treatment") +
  theme_minimal()

# Pooled SD for d_av
long$fakeid <- seq(1, nrow(long))
model2 <- aov_car(siga ~ month * treatmentf + Error(fakeid), data = long)
anova_tab2 <- as.data.frame(model2$anova_table)
pooled_sd <- sqrt(anova_tab2$MSE[1])

# Contrast weights
low_high <- c(0.5, -1/3, -1/3, -1/3, 0.5)

# Contrast (overall)
contrast(em_month, list(low_vs_high = low_high))

# Simple effects by treatment
contrast(em_cell, list(low_vs_high = low_high), by = "treatmentf")

# Interaction contrast (difference in differences)
em_full <- emmeans(model, ~ month * treatmentf)
w_control <- c(-0.5, 1/3, 1/3, 1/3, -0.5)
w_treat <- c(0.5, -1/3, -1/3, -1/3, 0.5)
w_diff <- c(w_control, w_treat)
contrast(em_full, list(diff_of_diff = w_diff))
