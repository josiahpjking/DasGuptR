#' Das Gupta extract adjusted rates from the output of dgnpop.
#' This is useful for when the standardisation is conducted on subpopulations like age/sex combinations (or "vector factors" as DG uses).
#' @param df DG output
#' @export
#' @examples
#' # The case of 3 vector factors (2 populations)
#' eg4.5 <- data.frame(
#'   agegroup = rep(1:7, 2),
#'   pop = rep(c(1970, 1960), e = 7),
#'   bm = c(488, 452, 338, 156, 63, 22, 3,
#'          393, 407, 369, 274, 184, 90, 16),
#'   mw = c(.082, .527, .866, .941, .942, .923, .876,
#'          .122, .622, .903, .930, .916, .873, .800),
#'   wp = c(.056, .038, .032, .030, .026, .023, .019,
#'          .043, .041, .036, .032, .026, .020, .018)
#' )
#' dgnpop(eg4.5, pop=pop, bm, mw, wp, id_vars=c("agegroup"))
#' dgout <- dgnpop(eg4.5, pop=pop, bm, mw, wp, id_vars=c("agegroup"))
#' dg_rates(dgout)
dg_rates<-function(df){
  df %>%
    group_by(factor) %>%
    summarise_at(vars(starts_with("pop")),sum) %>%
    gather(population,rate,starts_with("pop")) %>%
    mutate(population=gsub("pop|pop_","",population))
}
