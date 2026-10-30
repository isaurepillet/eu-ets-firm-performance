# Appariement Mahalanobis, avec remise et exact pays x NACE2
# Entrée requise : financials_match_filtre2 (préparation intermédiaire non fournie)
# Sorties : financials_match_filtre3, pre_match, ids_complets, pool_matching, m

library(dplyr)
library(MatchIt)
library(cobalt)

# Liste privée : conserver exactement les exclusions de l'analyse initiale.
# Fournir un fichier RDS contenant un vecteur de 48 identifiants (caractères).
exclusions_path <- Sys.getenv("EU_ETS_EXCLUSIONS_FILE")
if (!nzchar(exclusions_path) || !file.exists(exclusions_path)) {
  stop("Définir EU_ETS_EXCLUSIONS_FILE vers le fichier RDS privé des exclusions.")
}
bvdid_post_phase1 <- readRDS(exclusions_path)
if (!is.character(bvdid_post_phase1) ||
    length(bvdid_post_phase1) != 48L ||
    anyNA(bvdid_post_phase1) ||
    any(!nzchar(bvdid_post_phase1)) ||
    anyDuplicated(bvdid_post_phase1)) {
  stop("Le fichier privé doit contenir les 48 identifiants distincts d'origine.")
}

financials_match_filtre3 <- financials_match_filtre2 |>
  filter(
    !bvdid %in% bvdid_post_phase1,
    bvd_major_sector != "Transport"
  ) |>
  mutate(
    nace2 = substr(nace_3_digits, 1, 2)
  )

n_distinct(financials_match_filtre3$bvdid)

financials_match_filtre3 |>
  group_by(ets) |>
  summarise(n = n_distinct(bvdid))

pre_match <- financials_match_filtre3 |>
  filter(annee %in% 2002:2004)

ids_complets <- pre_match |>
  filter(
    !is.na(operating_revenue_turnover),
    !is.na(total_assets),
    !is.na(number_of_employees),
    operating_revenue_turnover > 0,
    total_assets > 0,
    number_of_employees > 0
  ) |>
  group_by(bvdid) |>
  summarise(
    n_annees = n_distinct(annee),
    .groups = "drop"
  ) |>
  filter(n_annees == 3) |>
  pull(bvdid)

pool_matching <- pre_match |>
  filter(bvdid %in% ids_complets) |>
  group_by(bvdid) |>
  summarise(
    ets = first(ets),
    country_code = first(country_code),
    nace2 = first(nace2),
    mean_log_turnover = mean(log(operating_revenue_turnover)),
    mean_log_assets = mean(log(total_assets)),
    mean_log_employees = mean(log(number_of_employees)),
    .groups = "drop"
  )

pool_matching |>
  group_by(ets) |>
  summarise(n = n_distinct(bvdid))
m <- matchit(
  ets ~ mean_log_turnover + mean_log_assets + mean_log_employees,
  data = pool_matching,
  method = "nearest",
  distance = "mahalanobis",
  exact = ~ country_code + nace2,
  estimand = "ATT",
  ratio = 1,
  replace = TRUE,
  caliper = c(mean_log_turnover = 0.3,
              mean_log_assets = 0.25,
              mean_log_employees = 0.3),
  std.caliper = TRUE
)

summary(m)   # Nombre de traités appariés

