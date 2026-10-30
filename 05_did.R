# Requiert panel_es, créé dans 04_event_study.R

panel_did <- panel_es |>
  mutate(
    post = as.integer(annee >= 2005)
  )

library(dplyr)
library(fixest)

# 1. Modèles sans effets fixes et avec effets fixes entreprise + année
did_turnover_noFE <- feols(
  log_turnover ~ ets * post,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

# Avec effets fixes firme + année
did_turnover_FE <- feols(
  log_turnover ~ ets:post | bvdid + annee,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

did_assets_noFE <- feols(
  log_assets ~ ets * post,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

did_assets_FE <- feols(
  log_assets ~ ets:post | bvdid + annee,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

did_employment_noFE <- feols(
  log_employees ~ ets * post,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

did_employment_FE <- feols(
  log_employees ~ ets:post | bvdid + annee,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

summary(did_turnover_noFE)
summary(did_turnover_FE)

summary(did_assets_noFE)
summary(did_assets_FE)

summary(did_employment_noFE)
summary(did_employment_FE)

etable(
  did_turnover_noFE,
  did_turnover_FE,
  did_assets_noFE,
  did_assets_FE,
  did_employment_noFE,
  did_employment_FE,

  headers = c(
    "CA - sans EF",
    "CA - avec EF",
    "Actifs - sans EF",
    "Actifs - avec EF",
    "Emploi - sans EF",
    "Emploi - avec EF"
  ),

  keep = "ets:post|ets x post",

  fitstat = ~ n + r2 + ar2
)

# 2. Modèles avec effets fixes entreprise, pays × année et secteur × année

# Chiffre d'affaires
did_turnover_fullFE <- feols(
  log_turnover ~ ets:post |
    bvdid + country_code^annee + nace2^annee,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

# Actifs totaux
did_assets_fullFE <- feols(
  log_assets ~ ets:post |
    bvdid + country_code^annee + nace2^annee,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

# Emploi
did_employment_fullFE <- feols(
  log_employees ~ ets:post |
    bvdid + country_code^annee + nace2^annee,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

summary(did_turnover_fullFE)
summary(did_assets_fullFE)
summary(did_employment_fullFE)

etable(
  did_turnover_noFE,
  did_turnover_FE,
  did_turnover_fullFE,

  did_assets_noFE,
  did_assets_FE,
  did_assets_fullFE,

  did_employment_noFE,
  did_employment_FE,
  did_employment_fullFE,

  headers = c(
    "CA - sans EF",
    "CA - firme + année",
    "CA - EF renforcés",

    "Actifs - sans EF",
    "Actifs - firme + année",
    "Actifs - EF renforcés",

    "Emploi - sans EF",
    "Emploi - firme + année",
    "Emploi - EF renforcés"
  ),

  keep = "ets:post|ets x post",

  fitstat = ~ n + r2 + ar2
)

# 3. Hétérogénéité par pays
panel_did <- panel_did |>
  mutate(
    did_DE = ets * post * (country_code == "DE"),
    did_ES = ets * post * (country_code == "ES"),
    did_FR = ets * post * (country_code == "FR"),
    did_IT = ets * post * (country_code == "IT")
  )

did_country_turnover <- feols(
  log_turnover ~ did_DE + did_ES + did_FR + did_IT |
    bvdid + country_code^annee + nace2^annee,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

summary(did_country_turnover)

did_country_assets <- feols(
  log_assets ~ did_DE + did_ES + did_FR + did_IT |
    bvdid + country_code^annee + nace2^annee,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

summary(did_country_assets)

did_country_employment <- feols(
  log_employees ~ did_DE + did_ES + did_FR + did_IT |
    bvdid + country_code^annee + nace2^annee,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

summary(did_country_employment)

etable(
  did_country_turnover,
  did_country_assets,
  did_country_employment,

  headers = c(
    "Chiffre d'affaires",
    "Actifs totaux",
    "Emploi"
  ),

  dict = c(
    did_DE = "Allemagne × ETS × Post",
    did_ES = "Espagne × ETS × Post",
    did_FR = "France × ETS × Post",
    did_IT = "Italie × ETS × Post"
  ),

  fitstat = ~ n + r2 + ar2
)
