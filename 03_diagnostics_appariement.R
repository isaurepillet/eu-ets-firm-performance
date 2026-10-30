library(dplyr)
library(ggplot2)
library(patchwork)
library(tidyr)

# Requiert les objets m, pool_matching, pre_match et financials_match_filtre3
# 1. Paires traité / contrôle
mm <- m$match.matrix
pairs <- data.frame(
  t_row = match(rownames(mm), rownames(pool_matching)),
  c_row = match(mm[, 1],      rownames(pool_matching))
) |>
  filter(!is.na(c_row)) |>
  mutate(t_bvd = pool_matching$bvdid[t_row],
         c_bvd = pool_matching$bvdid[c_row])

# 2. Niveaux moyens 2002-2004 (comme la table 11 de l'article)
niveaux <- pre_match |>
  filter(bvdid %in% pool_matching$bvdid) |>
  group_by(bvdid) |>
  summarise(turnover  = mean(operating_revenue_turnover),
            assets    = mean(total_assets),
            employees = mean(number_of_employees),
            .groups = "drop")
# ajoute l'EBIT si tu l'as : ebit = mean(ebit, na.rm = TRUE)

pt <- pairs |>
  left_join(niveaux, by = c("t_bvd" = "bvdid")) |>
  left_join(niveaux, by = c("c_bvd" = "bvdid"), suffix = c("_t", "_c"))

# 3. Tests appariés, niveaux et logs
tester <- function(x_t, x_c, nom) {
  tt <- t.test(x_t, x_c, paired = TRUE)
  tibble(Variable = nom, Mean_ETS = mean(x_t), Mean_Control = mean(x_c),
         Difference = mean(x_t - x_c), p_value = tt$p.value)
}

bind_rows(
  tester(pt$turnover_t,  pt$turnover_c,  "Revenue (niveau)"),
  tester(pt$assets_t,    pt$assets_c,    "Assets (niveau)"),
  tester(pt$employees_t, pt$employees_c, "Employees (niveau)"),
  tester(log(pt$turnover_t),  log(pt$turnover_c),  "Log revenue"),
  tester(log(pt$assets_t),    log(pt$assets_c),    "Log assets"),
  tester(log(pt$employees_t), log(pt$employees_c), "Log employees")
)

library(dplyr)
library(ggplot2)
library(patchwork)

qq_plot <- function(x_t, x_c, titre, xlab, ylab) {
  
  x_t <- log(x_t)
  x_c <- log(x_c)
  
  d <- tibble(
    t = sort(x_t[is.finite(x_t)]),
    c = sort(x_c[is.finite(x_c)])
  )
  
  lims <- range(c(d$t, d$c), na.rm = TRUE)
  
  ggplot(d, aes(x = c, y = t)) +
    geom_point(size = 1.15, alpha = 0.55) +
    geom_abline(
      slope = 1,
      intercept = 0,
      linetype = "dashed",
      linewidth = 0.6
    ) +
    coord_equal(
      xlim = lims,
      ylim = lims
    ) +
    labs(
      title = titre,
      x = xlab,
      y = ylab
    ) +
    theme_classic(base_size = 11) +
    theme(
      plot.title = element_text(
        face = "bold",
        size = 11,
        hjust = 0
      ),
      axis.title = element_text(size = 10),
      axis.text = element_text(size = 9),
      axis.line = element_line(linewidth = 0.4),
      plot.margin = margin(8, 10, 8, 8)
    )
}
p_a <- qq_plot(
  pt$turnover_t,
  pt$turnover_c,
  "(a) Chiffre d'affaires",
  "Entreprises non-ETS (log chiffre d'affaires)",
  "Entreprises ETS (log chiffre d'affaires)"
)

p_b <- qq_plot(
  pt$employees_t,
  pt$employees_c,
  "(b) Emploi",
  "Entreprises non-ETS (log emploi)",
  "Entreprises ETS (log emploi)"
)

p_c <- qq_plot(
  pt$assets_t,
  pt$assets_c,
  "(c) Actifs totaux",
  "Entreprises non-ETS (log actifs totaux)",
  "Entreprises ETS (log actifs totaux)"
)

fig12 <- (p_a | p_b) / (plot_spacer() | p_c | plot_spacer()) +
  plot_layout(
    heights = c(1, 1),
    widths = c(0.5, 1, 0.5)
  )
fig12

#FIGURE 13
# Panel : une ligne par paire x groupe x année
long <- bind_rows(
  pairs |> transmute(pair_id = row_number(), group = "ETS",     bvdid = t_bvd),
  pairs |> transmute(pair_id = row_number(), group = "Non-ETS", bvdid = c_bvd)
) |>
  inner_join(
    financials_match_filtre3 |> filter(annee %in% 2002:2014),
    by = "bvdid", relationship = "many-to-many"
  )

fig13_data <- long |>
  group_by(group, annee) |>
  summarise(
    `Revenue (M€)`     = mean(operating_revenue_turnover, na.rm = TRUE) / 1e6,
    `Employees`        = mean(number_of_employees,        na.rm = TRUE),
    `Fixed assets (M€)`= mean(total_assets,               na.rm = TRUE) / 1e6,
    .groups = "drop"
  ) |>
  tidyr::pivot_longer(-c(group, annee), names_to = "var", values_to = "value") |>
  mutate(var = factor(var, levels = c("Revenue (M€)", "Employees",
                                      "Fixed assets (M€)")))

fig13 <- ggplot(fig13_data, aes(annee, value, colour = group)) +
  geom_line(linewidth = 0.7) +
  geom_vline(xintercept = 2004.5, linetype = "dashed") +   # introduction de l'ETS
  facet_wrap(~ var, scales = "free_y", ncol = 2) +
  scale_colour_manual(values = c("ETS" = "#1f4e79", "Non-ETS" = "#b03a48"), name = NULL) +
  scale_x_continuous(breaks = seq(2002, 2014, 2)) +
  labs(x = "Year", y = NULL) +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom")
fig13

ggsave("outputs/figure13.png", fig13, width = 9, height = 7, dpi = 300)
ggsave("outputs/figure12.png", fig12, width = 9, height = 8, dpi = 300)