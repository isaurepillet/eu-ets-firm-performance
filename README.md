# EU ETS et performances économiques des entreprises européennes

Code R associé à un rapport de stage sur le chiffre d'affaires, les actifs totaux et l'emploi des entreprises exposées à l'EU ETS, avec une analyse des entreprises de taille intermédiaire (ETI).

**Champ d'estimation :** Allemagne, Espagne, France et Italie, 2002–2014. L'extrait de préparation sélectionne initialement 2000–2014.

## Stratégie empirique

- Appariement sur les moyennes des logarithmes du chiffre d'affaires, des actifs et de l'emploi en 2002–2004 ; trois années renseignées et strictement positives.
- Plus proche voisin, distance de Mahalanobis, ATT, ratio 1:1, avec remise ; appariement exact pays × NACE2. Calipers standardisés : 0,30 (CA), 0,25 (actifs), 0,30 (emploi).
- Différences-de-différences : traitement à partir de 2005 ; modèles sans effets fixes, avec effets fixes entreprise + année, puis entreprise + pays × année + NACE2 × année.
- Études d'événement : année de référence 2004 ; test de Wald conjoint sur 2002 et 2003.
- Poids issus de MatchIt et erreurs standards regroupées par entreprise ; hétérogénéité par pays et par taille.

Le nettoyage conserve les formules, pondérations, erreurs standards, fenêtres temporelles, règles de sélection et seuils de taille des scripts initiaux. Il ne constitue pas une validation de l'identification causale.

## Organisation et dépendances

Les scripts sont à la racine du dépôt.

| Script | Entrées principales | Objet / sortie |
| --- | --- | --- |
| [01_preparation_jrc.R](01_preparation_jrc.R) | `financials_clean_info`, `JRC_EU_ETS_FIRMS_V2_012022_public` | `financials_match_filtre` ; extrait partiel |
| [02_appariement.R](02_appariement.R) | `financials_match_filtre2`, fichier privé d'exclusions | `financials_match_filtre3`, `pre_match`, `ids_complets`, `pool_matching`, `m` |
| [03_diagnostics_appariement.R](03_diagnostics_appariement.R) | Objets du script 02 | Diagnostics et figures dans `outputs/` |
| [04_event_study.R](04_event_study.R) | `m`, `financials_match_filtre3` | `panel_es`, modèles, tests et graphique |
| [05_did.R](05_did.R) | `panel_es` | `panel_did`, modèles DiD et par pays |
| [06_heterogeneite_eti.R](06_heterogeneite_eti.R) | `panel_did`, `pre_match`, `ids_complets` | Modèles ETI/non-ETI et PME/ETI/GE |

## Exécution dans un environnement autorisé

R >= 4.1 est requis pour le pipe natif ; dplyr >= 1.1.1 pour `relationship` dans les jointures. Packages utilisés :

```r
install.packages(c(
  "dplyr", "data.table", "MatchIt", "cobalt", "fixest",
  "ggplot2", "patchwork", "broom", "stringr", "tidyr"
))
```

Depuis la racine du dépôt, charger les données autorisées et les objets intermédiaires requis. Exécuter 01, puis fournir **séparément** `financials_match_filtre2` avant 02 ; exécuter ensuite 02 à 06 dans l'ordre, dans la même session.

**Le dépôt n'est pas un pipeline autonome.** La construction de `financials_clean_info` et le passage de `financials_match_filtre` à `financials_match_filtre2` manquent. Aucun résultat n'a été réestimé dans cette révision.

### Exclusions privées

Le script 02 attend `EU_ETS_EXCLUSIONS_FILE`, chemin vers un RDS contenant le vecteur caractère des **48 identifiants distincts d'origine**, avec leurs zéros initiaux. Ce fichier doit rester dans un espace privé autorisé. Sa longueur est contrôlée ; son contenu exact doit être vérifié par la personne qui le fournit.

```r
Sys.setenv(EU_ETS_EXCLUSIONS_FILE = "/chemin/prive/exclusions.rds")
source("02_appariement.R")
```

Le script s'arrête si ce fichier manque : aucune exclusion n'est supprimée silencieusement. Le motif précis de ces exclusions reste à documenter ; leur nom initial ne suffit pas à le justifier.

## Données et confidentialité

Les données Orbis sous licence ne sont pas distribuées. Ne pas publier de données d'entreprise, tables d'appariement, listes d'identifiants ou sessions R. Les graphiques de diagnostic utilisent les microdonnées et doivent faire l'objet d'un examen distinct avant diffusion.

Le `.gitignore` exclut données, sorties, configuration privée et sessions R. Il ne protège pas les fichiers déjà suivis ni les ajouts forcés. Consulter [l'examen de confidentialité](CONFIDENTIALITY.md) pour le périmètre vérifié et la limite liée à l'historique.

## Points méthodologiques à vérifier avant une réplication

- Les seuils monétaires de taille sont appliqués comme dans les scripts, en euros : vérifier les unités des données sources.
- Les moyennes et le traitement des valeurs manquantes sont inchangés ; les deux classifications de taille sont conservées séparément.
- Les règles de rapprochement des identifiants, de consolidation et de correction des pics restent celles de l'extrait initial.
