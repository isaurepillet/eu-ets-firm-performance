# Préparation JRC / Orbis (extrait partiel)
# Entrée requise : financials_clean_info et JRC_EU_ETS_FIRMS_V2_012022_public
# Sortie : financials_match_filtre (étape intermédiaire)

#match avec ets 
library(dplyr)

table(JRC_EU_ETS_FIRMS_V2_012022_public$EUTL_NATIONAL_REGISTRY_CODE)
colnames(JRC_EU_ETS_FIRMS_V2_012022_public)

jrc_ets <- JRC_EU_ETS_FIRMS_V2_012022_public |> 
  filter(EUTL_NATIONAL_REGISTRY_CODE %in% c("DE", "FR", "IT", "ES"))

jrc_ets <- jrc_ets |> 
  mutate(ets=1)

table(jrc_ets$JRC_IS_VALIDATED)

jrc_ets_validated <- jrc_ets |> 
  filter(JRC_IS_VALIDATED=="TRUE")

jrc_ets_validated |> 
  group_by(EUTL_NATIONAL_REGISTRY_CODE) |> 
  summarize(n=n_distinct(JRC_REGID_STD))


jrc_ets_validated <- jrc_ets_validated |> 
  mutate(bvdid = if_else(EUTL_NATIONAL_REGISTRY_CODE=="DE", substr(ORBIS_BVD_ID,3,nchar(ORBIS_BVD_ID)), JRC_REGID_STD))

jrc_ets_validated <- jrc_ets_validated |> 
  mutate(bvdid = if_else(substr(ORBIS_BVD_ID,1,2)=="IT", substr(ORBIS_BVD_ID,3, nchar(ORBIS_BVD_ID)), bvdid))


jrc_ets_match <- jrc_ets_validated |> 
  select(bvdid, ets) |> 
  distinct()
#match

financials_match <- financials_clean_info |> 
  left_join(jrc_ets_match,
            by=c("bvdid"))

financials_match <- financials_match |> 
  mutate(ets=if_else(is.na(ets),0,ets))
         
financials_match |> 
  group_by(country_code, ets) |> 
  summarize(n=n_distinct(bvdid))

financials_match <- financials_match |> 
  mutate(annee=substr(closing_date, 1,4))
 
table(financials_match$annee)

financials_match <- financials_match |>
  group_by(bvdid) |>
  filter(any(annee < 2005)) |>
  ungroup()

financials_match <- financials_match |>
  distinct()

financials_match |>
  count(consolidation_code, sort = TRUE)


financials_match <- financials_match |>
  mutate(
    priority_conso = case_when(
      consolidation_code == "U1" ~ 1,
      consolidation_code == "U2" ~ 2,
      consolidation_code == "C1" ~ 3,
      consolidation_code == "C2" ~ 4,
      consolidation_code == "LF" ~ 5,
      TRUE ~ 6
    )
  ) |>
  group_by(bvdid, annee) |>
  filter(priority_conso == min(priority_conso)) |>
  ungroup()

financials_match <- financials_match |> 
  filter(annee>=2000)
financials_match <- financials_match |> 
  filter (annee <=2014)

financials_match <- financials_match |>
  group_by(bvdid, annee) |>
  

  filter(closing_date == max(closing_date, na.rm = TRUE)) |>
  ungroup()

# Export désactivé : ne pas diffuser les données financières sous licence.
# write.csv(financials_match, "data/financials_match.csv")

financials_match <- financials_match |> 
  mutate(nace_3_digits=substr(nace_rev_2_core_code_4_digits, 1,3))

liste_nace_ets <- financials_match |> 
  filter(ets == 1) |> 
  group_by(nace_3_digits) |> 
  summarize(n = n_distinct(bvdid)) |> 
  arrange(desc(n)) |> 
  pull(nace_3_digits)

financials_match_filtre <- financials_match |> 
  filter(nace_3_digits %in% liste_nace_ets )

financials_match_filtre |> 
  group_by(country_code, ets) |> 
  summarize(n=n_distinct(bvdid))

library(data.table)

financials_match_filtre <- financials_match_filtre |>
  arrange(bvdid, annee)

setDT(financials_match_filtre)
setorder(financials_match_filtre, bvdid, annee)
# Année sous forme entière
an <- as.integer(as.character(financials_match_filtre$annee))

# Vérifie qu'on a bien la même entreprise en t-1 et t+1
meme_avant <- financials_match_filtre$bvdid == shift(financials_match_filtre$bvdid)
meme_apres <- financials_match_filtre$bvdid == shift(
  financials_match_filtre$bvdid,
  type = "lead"
)

# Vérifie que les trois observations correspondent à trois années consécutives
trois_ans <- meme_avant & meme_apres &
  an == shift(an) + 1 &
  shift(an, type = "lead") == an + 1

# Valeurs de sales en t-1 et t+1
avant <- shift(financials_match_filtre$sales)
apres <- shift(financials_match_filtre$sales, type = "lead")

# Détection des pics / creux isolés x5
flag_sales <- trois_ans &
  financials_match_filtre$sales > 0 &
  avant > 0 &
  apres > 0 &
  (
    (
      financials_match_filtre$sales >= 5 * avant &
        financials_match_filtre$sales >= 5 * apres
    ) |
      (
        avant >= 5 * financials_match_filtre$sales &
          apres >= 5 * financials_match_filtre$sales
      )
  )

# Combien de valeurs seront corrigées ?
sum(flag_sales, na.rm = TRUE)

financials_match_filtre[
  which(flag_sales),
  sales := NA_real_
]

# Vérification
sum(flag_sales, na.rm = TRUE)
sum(is.na(financials_match_filtre$sales))

# Valeurs des effectifs en t-1 et t+1
 
