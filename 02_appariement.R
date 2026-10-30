# Appariement Mahalanobis, avec remise et exact pays x NACE2
# Entrée requise : financials_match_filtre2 (préparation intermédiaire non fournie)
# Sorties : financials_match_filtre3, pre_match, ids_complets, pool_matching, m

library(MatchIt)
library(cobalt)

bvdid_post_phase1 <- c(
  "00257660720",
  "00734630155",
  "01402740060",
  "01660360601",
  "4150006965",
  "4250002471",
  "8190549720",
  "A28854727",
  "A35091719",
  "A58352311",
  "B16232415",
  "B35782580",
  "F14014245",
  "F15016124",
  "00184610657",
  "00170370654",
  "00170540652",
  "00185570652",
  "00282900653",
  "01057390658",
  "01857170656",
  "01983720655",
  "02126240650",
  "02512930658",
  "02638240651",
  "7330329496",
  "00139620405",
  "01752970580",
  "02168860399",
  "03269160960",
  "A08435547",
  "A12030821",
  "A12091575",
  "A15011018",
  "A28101020",
  "A28225266",
  "A28885614",
  "A31001738",
  "A39289632",
  "A50122480",
  "A81047375",
  "B12305520",
  "B61714184",
  "F31600240",
  "A30006142",
  "317803443",
  "8190548479",
  "B12479259"
)

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

summary(m)   # regarde le nombre de traités appariés

library(dplyr)

