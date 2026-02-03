# Lab 9 script

.libPaths(c("rlib", .libPaths()))

# packages
library(tidyverse)
library(haven)
library(emmeans)
library(afex)
library(pastecs)
library(car)
source("Rallfun-v45.txt")

# read data
ws <- read_sav("wordsum v2.sav")

# factors + ID
ws$sized_f <- factor(ws$sized, levels = c(0, 1), labels = c("Non-City", "City"))
ws$regions_f <- factor(ws$regions, levels = c(1, 2, 3, 4), labels = c("Midwest", "Northeast", "South", "West"))
ws$id <- rownames(ws)

# confirm

table(ws$sized, ws$sized_f, exclude = NULL)

table(ws$regions, ws$regions_f, exclude = NULL)

# ANOVA + emmeans
ws_anova <- aov_car(ws ~ sized_f * regions_f + Error(id), data = ws)

em_cell <- emmeans(ws_anova, ~ sized_f * regions_f)
em_sized <- emmeans(ws_anova, ~ sized_f)
em_regions <- emmeans(ws_anova, ~ regions_f)

summary(ws_anova)
ws_anova$Anova

# pairwise
pairs(em_regions, adjust = "tukey")

# simple effects (city vs non-city within each region)
pairs(em_cell, simple = "sized_f", adjust = "none")

# simple effects (region within each city status)
pairs(em_cell, simple = "regions_f", adjust = "none")

# critical values
alpha <- 0.05
A <- 4
an <- as.data.frame(ws_anova$Anova)
df_error <- an$Df[5]

scheffe_main_region_t <- sqrt((A - 1) * qf(1 - alpha, A - 1, df_error))
crit_t_city_simple <- qtukey(1 - alpha/4, 2, df_error) / sqrt(2)
crit_t_region_simple <- qtukey(1 - alpha/2, A, df_error) / sqrt(2)

# Cohen's d
ss <- an$`Sum Sq`
names(ss) <- row.names(an)
ss_error <- ss["Residuals"]
MSE <- ss_error / df_error
sd_pooled <- sqrt(MSE)

sc_city <- as.data.frame(pairs(em_cell, simple = "sized_f", adjust = "none"))
sc_city$d <- sc_city$estimate / sd_pooled
sc_city$bonf_p <- p.adjust(sc_city$p.value, method = "bonferroni")

# complex contrasts
contrast_city <- c(0, -0.5, 0, 1, 0, 0, 0, -0.5)
contrast_noncity <- c(-0.5, 0, 1, 0, 0, 0, -0.5, 0)
contrast_interaction <- contrast_city - contrast_noncity

contrast_list <- list(
  city_NE_vs_MW_W = contrast_city,
  noncity_NE_vs_MW_W = contrast_noncity,
  interaction_NE_vs_MW_W = contrast_interaction
)

complex_contrasts <- contrast(em_cell, contrast_list, adjust = "none")
cc <- as.data.frame(complex_contrasts)
cc$d <- cc$estimate / sd_pooled

# critical values for complex contrasts
scheffe_simple_t <- sqrt((A - 1) * qf(1 - alpha, A - 1, df_error))
bonf_simple_t <- qtukey(1 - alpha/2, 2, df_error) / sqrt(2)
scheffe_interaction_t <- sqrt((A - 1) * (2 - 1) * qf(1 - alpha, (A - 1) * (2 - 1), df_error))
