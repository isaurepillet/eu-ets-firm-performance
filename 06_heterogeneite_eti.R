# Requiert panel_did, pre_match et ids_complets
# Attention : la classification ETI est recalculée pour deux analyses.

taille_pre <- pre_match |>
  filter(bvdid %in% ids_complets) |>
  group_by(bvdid) |>
  summarise(
    emp_pre = mean(number_of_employees),
    ca_pre = mean(operating_revenue_turnover),
    assets_pre = mean(total_assets),
    .groups = "drop"
  ) |>
  mutate(
    
    # PME : < 250 salariés ET
    # CA <= 50 M€ OU bilan <= 43 M€
    pme = emp_pre < 250 &
      (ca_pre <= 50e6 | assets_pre <= 43e6),
    
    # ETI : pas PME, < 5000 salariés ET
    # CA <= 1,5 Md€ OU bilan <= 2 Md€
    eti = !pme &
      emp_pre < 5000 &
      (ca_pre <= 1.5e9 | assets_pre <= 2e9)
  )

panel_did <- panel_did |>
  left_join(
    taille_pre |> select(bvdid, eti),
    by = "bvdid"
  )

panel_did |>
  distinct(bvdid, ets, eti) |>
  count(eti, ets)


panel_did <- panel_did |>
  mutate(
    did_ETI = ets * post * eti,
    did_nonETI = ets * post * (!eti)
  )

did_size_turnover <- feols(
  log_turnover ~ did_ETI + did_nonETI |
    bvdid + country_code^annee + nace2^annee,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

summary(did_size_turnover)

did_size_assets <- feols(
  log_assets ~ did_ETI + did_nonETI |
    bvdid + country_code^annee + nace2^annee,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

summary(did_size_assets)

did_size_employment <- feols(
  log_employees ~ did_ETI + did_nonETI |
    bvdid + country_code^annee + nace2^annee,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

summary(did_size_employment)

etable(
  did_size_turnover,
  did_size_assets,
  did_size_employment,
  
  headers = c(
    "Chiffre d'affaires",
    "Actifs totaux",
    "Emploi"
  ),
  
  dict = c(
    did_ETI = "ETI × ETS × Post",
    did_nonETI = "Autres entreprises × ETS × Post"
  ),
  
  fitstat = ~ n + r2 + ar2
)


taille_pre <- pre_match |>
  filter(bvdid %in% ids_complets) |>
  group_by(bvdid) |>
  summarise(
    emp_pre = mean(number_of_employees),
    ca_pre = mean(operating_revenue_turnover),
    assets_pre = mean(total_assets),
    .groups = "drop"
  ) |>
  mutate(
    categorie = case_when(
      
      emp_pre < 250 &
        (ca_pre <= 50e6 | assets_pre <= 43e6) ~ "PME",
      
      emp_pre < 5000 &
        (ca_pre <= 1.5e9 | assets_pre <= 2e9) ~ "ETI",
      
      TRUE ~ "GE"
    )
  )

panel_did <- panel_did |>
  select(-any_of("categorie")) |>
  left_join(
    taille_pre |> select(bvdid, categorie),
    by = "bvdid"
  )

panel_did |>
  distinct(bvdid, ets, categorie) |>
  count(categorie, ets)

panel_did <- panel_did |>
  mutate(
    did_PME = ets * post * (categorie == "PME"),
    did_ETI = ets * post * (categorie == "ETI"),
    did_GE  = ets * post * (categorie == "GE")
  )

did_cat_turnover <- feols(
  log_turnover ~ did_PME + did_ETI + did_GE |
    bvdid + country_code^annee + nace2^annee,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

did_cat_assets <- feols(
  log_assets ~ did_PME + did_ETI + did_GE |
    bvdid + country_code^annee + nace2^annee,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

did_cat_employment <- feols(
  log_employees ~ did_PME + did_ETI + did_GE |
    bvdid + country_code^annee + nace2^annee,
  data = panel_did,
  weights = ~ weights,
  cluster = ~ bvdid
)

etable(
  did_cat_turnover,
  did_cat_assets,
  did_cat_employment,
  
  headers = c(
    "Chiffre d'affaires",
    "Actifs totaux",
    "Emploi"
  ),
  
  dict = c(
    did_PME = "PME × ETS × Post",
    did_ETI = "ETI × ETS × Post",
    did_GE  = "GE × ETS × Post"
  ),
  
  fitstat = ~ n + r2 + ar2
)