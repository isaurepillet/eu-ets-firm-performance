# EU ETS et performances économiques des entreprises européennes

Code R associé à un rapport de stage étudiant les évolutions du chiffre d'affaires, des actifs et de l'emploi des entreprises exposées à l'EU ETS, avec une analyse particulière des entreprises de taille intermédiaire (ETI).

**Périmètre :** Allemagne, Espagne, France et Italie ; 2002–2014.

## Approche

- Rapprochement des données d'entreprises et des identifiants EU ETS.
- Appariement sur moyennes des logarithmes prétraitement (2002–2004), par plus proche voisin avec distance de Mahalanobis, remise, appariement exact pays × secteur NACE2 et calipers.
- Estimations en différences-de-différences avec effets fixes entreprise, pays × année et secteur × année, erreurs standards regroupées par entreprise.
- Études d'événement et analyse de l'hétérogénéité selon la taille.

## Organisation

| Fichier | Objet |
| --- | --- |
| `R/01_preparation_jrc.R` | Rapprochement JRC et première préparation des données |
| `R/02_appariement.R` | Sélection prétraitement et appariement |
| `R/03_diagnostics_appariement.R` | Diagnostics et figures d'appariement |
| `R/04_event_study.R` | Études d'événement et tests de pré-tendances |
| `R/05_did.R` | Estimations principales et par pays |
| `R/06_heterogeneite_eti.R` | Classification ETI et estimations par taille |

## Données et limites de reproductibilité

Les données financières Orbis sont soumises à des restrictions d'accès et **ne sont pas diffusées dans ce dépôt**. Les scripts reposent sur des objets R préparés en amont, notamment `financials_clean_info`, `financials_match_filtre2` et la table JRC `JRC_EU_ETS_FIRMS_V2_012022_public`. Le code de construction des deux premiers objets n'est pas disponible dans les scripts archivés.

**Ce dépôt documente la démarche empirique ; il ne constitue pas un pipeline autonome permettant de reproduire les résultats sans les données et étapes de préparation manquantes.** Les résultats n'ont pas été réexécutés ni validés dans cette version.

## Exécution (dans un environnement de recherche autorisé)

Les scripts doivent être lancés dans l'ordre numérique, après chargement des objets nécessaires. Ils utilisent notamment les packages R `dplyr`, `data.table`, `MatchIt`, `cobalt`, `fixest`, `ggplot2`, `patchwork`, `broom`, `stringr` et `tidyr`.

Avant toute publication publique : vérifier l'autorisation de l'encadrant et examiner le code à la recherche d'identifiants, chemins locaux ou éléments confidentiels. Ne jamais ajouter de données sous licence au dépôt.

## Notes de maintenance

- Les p-values affichées dans la figure d'event study sont maintenant récupérées depuis les tests calculés plutôt que recopiées manuellement.
- Un export CSV de données financières a été désactivé.
- Les spécifications économétriques ont été conservées telles qu'elles apparaissaient dans les scripts transmis.
- Les exclusions d'identifiants dans `02_appariement.R` doivent être documentées et validées avant diffusion.
