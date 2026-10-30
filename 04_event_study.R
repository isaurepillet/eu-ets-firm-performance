# Requiert m et financials_match_filtre3
# Les p-values affichées proviennent des tests de Wald calculés.

library(dplyr)
library(MatchIt)
library(fixest)
library(ggplot2)
library(broom)
library(stringr)
library(tidyr)

# ============================================================
# 1. PANEL APPARIÉ
# ============================================================

matched_firms <- match.data(m) |>
  select(bvdid, ets, weights)

panel_es <- financials_match_filtre3 |>
  filter(annee %in% 2002:2014) |>
  inner_join(
    matched_firms,
    by = c("bvdid", "ets")
  ) |>
  mutate(
    log_turnover = if_else(
      operating_revenue_turnover > 0,
      log(operating_revenue_turnover),
      NA_real_
    ),
    
    log_assets = if_else(
      total_assets > 0,
      log(total_assets),
      NA_real_
    ),
    
    log_employees = if_else(
      number_of_employees > 0,
      log(number_of_employees),
      NA_real_
    )
  )
# ============================================================
# 2. EVENT STUDIES — EF FIRME + PAYS×ANNÉE + SECTEUR×ANNÉE
# ============================================================

es_turnover_fullFE <- feols(
  log_turnover ~ i(annee, ets, ref = 2004) |
    bvdid + country_code^annee + nace2^annee,
  data = panel_es,
  weights = ~ weights,
  cluster = ~ bvdid
)

es_assets_fullFE <- feols(
  log_assets ~ i(annee, ets, ref = 2004) |
    bvdid + country_code^annee + nace2^annee,
  data = panel_es,
  weights = ~ weights,
  cluster = ~ bvdid
)

es_employment_fullFE <- feols(
  log_employees ~ i(annee, ets, ref = 2004) |
    bvdid + country_code^annee + nace2^annee,
  data = panel_es,
  weights = ~ weights,
  cluster = ~ bvdid
)
summary(es_turnover_fullFE)
summary(es_assets_fullFE)
summary(es_employment_fullFE)

# ============================================================
# 3. TESTS DE PRÉ-TENDANCE
# H0 : coefficients 2002 et 2003 = 0
# Référence = 2004
# ============================================================

wald_turnover <- wald(
  es_turnover_fullFE,
  keep = "annee::2002:ets|annee::2003:ets",
  print = FALSE
)

wald_assets <- wald(
  es_assets_fullFE,
  keep = "annee::2002:ets|annee::2003:ets",
  print = FALSE
)

wald_employment <- wald(
  es_employment_fullFE,
  keep = "annee::2002:ets|annee::2003:ets",
  print = FALSE
)

wald_turnover
wald_assets
wald_employment

# ============================================================
# 4. EXTRAIRE LES COEFFICIENTS
# ============================================================

prep_es <- function(model, variable) {
  
  broom::tidy(
    model,
    conf.int = TRUE,
    conf.level = 0.95
  ) |>
    filter(str_detect(term, "^annee::")) |>
    mutate(
      annee = as.numeric(
        str_extract(term, "(?<=annee::)\\d{4}")
      ),
      variable = variable
    ) |>
    select(
      variable,
      annee,
      estimate,
      conf.low,
      conf.high
    ) |>
    
    # Ajouter 2004 = année de référence
    bind_rows(
      tibble(
        variable = variable,
        annee = 2004,
        estimate = 0,
        conf.low = 0,
        conf.high = 0
      )
    ) |>
    arrange(annee)
}


es_data <- bind_rows(
  prep_es(
    es_turnover_fullFE,
    "Chiffre d'affaires"
  ),
  prep_es(
    es_assets_fullFE,
    "Actifs totaux"
  ),
  prep_es(
    es_employment_fullFE,
    "Emploi"
  )
)

# ============================================================
# 5. LABELS DES TESTS DE WALD
# ============================================================

p_turnover <- wald_turnover$p
p_assets <- wald_assets$p
p_employment <- wald_employment$p

wald_labels <- tibble(
  variable = c(
    "Chiffre d'affaires",
    "Actifs totaux",
    "Emploi"
  ),
  label = c(
    paste0(
      "Wald pré-tendance : p = ",
      formatC(p_turnover, format = "f", digits = 2)
    ),
    paste0(
      "Wald pré-tendance : p = ",
      formatC(p_assets, format = "f", digits = 2)
    ),
    paste0(
      "Wald pré-tendance : p = ",
      formatC(p_employment, format = "f", digits = 2)
    )
  )
)

# ============================================================
# 6. FIGURE EVENT STUDY
# ============================================================

# ordre des panneaux
es_data <- es_data |>
  mutate(
    variable = factor(
      variable,
      levels = c(
        "Chiffre d'affaires",
        "Actifs totaux",
        "Emploi"
      )
    )
  )

# positions des labels : un peu au-dessus du max dans chaque panneau
label_pos <- es_data |>
  group_by(variable) |>
  summarise(
    x = 2011.8,
    y = max(conf.high, na.rm = TRUE) + 0.08,
    .groups = "drop"
  )

# Utiliser les p-values calculées, sans valeurs saisies manuellement.
wald_labels <- wald_labels |>
  mutate(variable = factor(variable, levels = levels(es_data$variable))) |>
  left_join(label_pos, by = "variable")

# graphique
event_plot_fullFE <- ggplot(es_data, aes(x = annee, y = estimate)) +
  geom_hline(yintercept = 0, colour = "black", linewidth = 0.6) +
  geom_vline(xintercept = 2004.5, linetype = "dashed", linewidth = 0.5) +
  geom_errorbar(
    aes(ymin = conf.low, ymax = conf.high),
    width = 0.12,
    colour = "#3E7C62",
    linewidth = 0.6
  ) +
  geom_point(
    colour = "#3E7C62",
    size = 2.8
  ) +
  geom_label(
    data = wald_labels,
    aes(
      x = x,
      y = y,
      label = label
    ),
    inherit.aes = FALSE,
    hjust = 0,
    vjust = 1.1,
    size = 3.0,
    linewidth = 0.2,
    fill = "white",
    label.padding = grid::unit(0.12, "lines")
  )+
  facet_wrap(~ variable, ncol = 1, scales = "free_y") +
  scale_x_continuous(breaks = seq(2002, 2014, 2)) +
  labs(
    x = "Année",
    y = "Effet estimé de l'ETS (réf. 2004)"
  ) +
  theme_classic(base_size = 12) +
  theme(
    strip.background = element_blank(),
    strip.text = element_text(face = "bold", size = 12, hjust = 0),
    axis.line = element_line(colour = "black", linewidth = 0.7),
    axis.ticks = element_line(colour = "black", linewidth = 0.5),
    axis.text = element_text(colour = "black"),
    axis.title = element_text(colour = "black"),
    panel.grid.major.y = element_line(colour = "grey82", linewidth = 0.35),
    panel.grid.minor.y = element_line(colour = "grey90", linewidth = 0.25),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    strip.placement = "outside",
    plot.margin = margin(10, 25, 10, 10)
  )

event_plot_fullFE

 