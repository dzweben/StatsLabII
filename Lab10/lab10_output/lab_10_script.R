# Lab 10 script
# IMPORTANT: set your working directory to the Lab10 folder before running.
# Example:
# setwd("/Users/dannyzweben/Desktop/GradClass/Y1/S2/StatsII/StatsII-Labs/Lab10")

# Packages
library(tidyverse)
library(afex)
library(pastecs)
library(emmeans)
source("baguley.txt")

# Problem 3: enter the wide data
wid <- data.frame(
  Subject = 1:8,
  L4 = c(21, 19, 21, 20, 17, 19, 22, 17),
  L5 = c(18, 17, 18, 17, 15, 14, 20, 16),
  L8 = c(14, 12, 13, 14, 9, 10, 16, 11),
  L9 = c(13, 11, 13, 12, 9, 7, 14, 9)
)

# Problem 4: wide to long
long <- pivot_longer(wid, cols = c("L4", "L5", "L8", "L9"),
                     names_to = "letters",
                     values_to = "solved")
long <- as.data.frame(long)

# Problem 5: factor condition
long$letters <- factor(long$letters)

# Problem 6: numeric condition
long$letters_num <- as.numeric(substr(as.character(long$letters), 2, 2))

# Problem 7: summary statistics
pastecs::stat.desc(wid[, c("L4", "L5", "L8", "L9")], norm = TRUE)

# Problem 8: within-subject ANOVA
model <- aov_car(solved ~ letters + Error(Subject/letters), data = long)
summary(model)

# Problem 10: subset wide dataframe
wid_sub <- subset(wid, select = c(L4, L5, L8, L9))

# Problem 11: CM confidence intervals
cm <- as.data.frame(cm.ci(data.frame = wid_sub, conf.level = .95, difference = FALSE))

# Problem 12: condition variable in CM dataframe
cm$letters <- rownames(cm)

# Problem 13: means dataframe
long <- group_by(long, letters_num, letters)
means <- summarize(long, mean_solved = mean(solved, na.rm = TRUE))

# Problem 14: merge for plotting
plot_df <- merge(means, cm, by = "letters")

# Problem 15: plot
plot_obj <- ggplot(data = plot_df, aes(x = letters_num, y = mean_solved, group = 1)) +
  geom_line() +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.1) +
  geom_point() +
  labs(title = "Puzzles Solved by Anagram Length",
       x = "Number of Letters",
       y = "Puzzles Solved (Mean)",
       caption = "Error bars are 95% Cousineau-Morey confidence intervals") +
  theme_minimal()

# Problem 16: GG-adjusted df
A <- 4
n <- 8
num_df <- A - 1
den_df <- (n - 1) * (A - 1)
# GG epsilon from the ANOVA output table
epsilon <- 0.78082
# To pull directly from the table (optional):
# sum_model <- summary(model)
# epsilon <- as.numeric(sum_model[["pval.adjustments"]]["letters", "GG eps"])
num_df_adj <- num_df * epsilon
den_df_adj <- den_df * epsilon

# Problem 18: emmeans
em <- emmeans(model, ~ letters)

# Problem 19: linear trend contrast
lin <- c(-2.5, -1.5, 1.5, 2.5)
lin_list <- list(lin)
contrast(em, lin_list)

# Problem 20: Scheffe t-critical
alpha <- 0.05
scheffe_t <- sqrt((A - 1) * qf(1 - alpha, (A - 1), (n - 1)))
