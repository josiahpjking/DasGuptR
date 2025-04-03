#' Creates a plot of Das Gupta standardised rates across the set of populations
#' @param dgo output from `dgnpop()`
#' @param legend.position legend position, passed to `graphics::legend` - choose from "bottomright", "bottom", "bottomleft", "left", "topleft", "top", "topright", "right" and "center", or provide xy.coords
#' @return A plot of each of the set of K-a standardised rates across populations
#' @export
dg_plot <- function(dgo, legend.position = "topright") {
  pops <- as.numeric(factor(dgo[["pop"]]))
  ps_labs <- as.character(dgo[["pop"]])
  rates <- dgo[["rate"]]

  fs <- unique(dgo[["factor"]])
  fs_lab <- ifelse(tolower(fs) == "crude",
    "crude",
    paste0("K-", tolower(fs), " adjusted")
  )

  fcols <- rainbow(length(fs))

  plot(pops, rates, type = "n", xlab = "population", ylab = "rate", xaxt = "n")
  axis(1, at = pops, labels = ps_labs)
  for (f in seq_along(fs)) {
    points(
      x = dgo[dgo$factor == fs[f], "pop"],
      y = dgo[dgo$factor == fs[f], "rate"],
      col = fcols[f]
    )
    lines(
      x = dgo[dgo$factor == fs[f], "pop"],
      y = dgo[dgo$factor == fs[f], "rate"],
      col = fcols[f], lwd = 2, lty = 2
    )
  }
  legend(legend.position, legend = fs_lab, col = fcols, lwd = 2)
}
