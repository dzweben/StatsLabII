# Lab 8 script

# packages
.libPaths(c("rlib", .libPaths()))
library(tidyverse)
library(haven)
library(emmeans)
library(afex)
library(pastecs)
library(car)
source("Rallfun-v45.txt")

# read data
ws <- read_sav("wordsum v2.sav")

# factor variables
attr(ws$sized, "labels")
attr(ws$regions, "labels")

ws$sized_f <- factor(ws$sized,
                     levels = c(0, 1),
                     labels = c("Non-City", "City"))

ws$regions_f <- factor(ws$regions,
                       levels = c(1, 2, 3, 4),
                       labels = c("Midwest", "Northeast", "South", "West"))

# confirm factor construction

table(ws$sized, ws$sized_f, exclude = NULL)

table(ws$regions, ws$regions_f, exclude = NULL)

# superfactor
ws <- group_by(ws, sized_f, regions_f)
ws <- mutate(ws, regionsize_new = cur_group_id())
ws <- ungroup(ws)

ws$regionsize_new_f <- factor(ws$regionsize_new,
                              levels = 1:8,
                              labels = c("Midwest Non-City", "Northeast Non-City",
                                         "South Non-City", "West Non-City",
                                         "Midwest City", "Northeast City",
                                         "South City", "West City"))

# cross-tabs

table(ws$regionsize_new_f, ws$sized_f, exclude = NULL)

table(ws$regionsize_new_f, ws$regions_f, exclude = NULL)

# histograms

ggplot(data = ws, aes(x = ws)) +
  geom_histogram() +
  facet_grid(regions_f ~ sized_f)

# skewness + Shapiro-Wilk

tapply(ws$ws, ws$regionsize_new_f, pastecs::stat.desc, norm = TRUE)

# Levene

car::leveneTest(ws ~ regionsize_new_f, data = ws, center = mean)

# outliers (MAD-Median)

o <- tapply(ws$ws, ws$regionsize_new_f, outpro)
o
# ws$ws[ws$regionsize_new_f=="GROUP NAME"][o[["GROUP NAME"]]$out.id]

# ID
ws$id <- rownames(ws)

# ANOVA
ws_anova <- aov_car(ws ~ sized_f * regions_f + Error(id), data = ws)
summary(ws_anova)
ws_anova$Anova

# omega partial
an <- as.data.frame(ws_anova$Anova)
ss <- an$`Sum Sq`
df <- an$Df
names(ss) <- row.names(an)
names(df) <- row.names(an)
ss_error <- ss["Residuals"]
df_error <- df["Residuals"]
mse <- ss_error / df_error
effects <- setdiff(row.names(an), c("(Intercept)", "Residuals"))
ss_effect <- ss[effects]
df_effect <- df[effects]
omega_p <- (ss_effect - df_effect * mse) / (ss_effect + ss_error + mse)
omega_table <- data.frame(
  effect = effects,
  df = df_effect,
  SS = ss_effect,
  SS_error = ss_error,
  MSE = mse,
  omega_p = omega_p
)
omega_table

# cell means
emmeans(ws_anova, ~ sized_f * regions_f)

# marginal means
emmeans(ws_anova, ~ sized_f)
emmeans(ws_anova, ~ regions_f)
