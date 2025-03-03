#' Prithwis Das Gupta's 1993 standardisation and decomposition of rates over P rate-factors and N populations.
#'
#' @description
#' Population rates are often composed of various different compositional factors. For example, Das Gupta 1992 expressed the birth rate as the product of the fertility rate, proportion of women who are of childbearing ages, and the proportion of women in the population. Comparisons of crude rates between populations can be misleading as different compositional factors may be contributing to different extents on any observed differences in the crude rate. Standardisation of rates ... TODO finish this description
#' @param x dataframe or tibble object, with columns specifying 1) population, 2) each rate-factor to be considered, and (optionally) 3) variables indicating underlying subpopulations
#' @param pop name (character string) of variable indicating population
#' @param factors names (character vector) of variables indicating compositional factors
#' @param id_vars character vector of variables indicating sub-populations
#' @param crossclassified character string of variable indicating size of sub-population. If specified, the proportion of each population in a given sub-population (e.g. each age-sex combination) is re-expressed as a product of symmetrical expressions representing the different variables (age, sex) constituting the sub-populations. These expressions are then used as compositional factors in the standardisation. If NULL, then providing a single variable as a compositional factor that represents the proportion of the population in each given sub-population will combine the contribution of all sub-population variables.
#' @param ratefunction user defined character string in R syntax that when evaluated specifies the function defining the rate as a function of factors. if NULL then will assume rate is the product of all factors. When sub-populations are provided, this should aggregate to a summary value (e.g., for the simple product rate this should be provided as `"sum(A*B*C*)"`.). User-defined functions can also be provided, as whatever string is given here will be parsed and evaluated as any other R code (see example eg4.4).
#' @param agg logical indicating whether, when cross-classified data is used, to output should be aggregated up to the population level
#' @param baseline baseline population to standardise against. if NULL then will do Das Gupta's full N-population standardisation.
#' @param quietly logical indicating whether interim messages should be outputted indicating progress through the P factors and N populations
#' @return
#' data.frame with P-p standardised rates for each population.
#' @export
#' @examples
#' ## 2 populations, R=ab
#' eg2.1 <- data.frame(
#'   pop = c("black","white"),
#'   avg_earnings = c(10930, 16591),
#'   earner_prop = c(.717892, .825974)
#' )
#'
#' dgnpop(eg2.1, pop = "pop", factors = c("avg_earnings", "earner_prop")) |>
#'   dg_table()
#'
#' ## 2 populations, R=abc
#' eg2.2 <- data.frame(
#'   pop = c("austria","chile"),
#'   birthsw1549 = c(51.78746, 84.90502),
#'   propw1549 = c(.45919, .75756),
#'   propw = c(.52638, .51065)
#' )
#'
#' dgnpop(eg2.2, pop = "pop", factors = c("birthsw1549", "propw1549", "propw")) |>
#'   dg_table()
#'
#' ## 2 populations, R=abcd
#' eg2.3 <- data.frame(
#'   pop = c(1971, 1979),
#'   birth_preg = c(25.3, 32.7),
#'   preg_actw = c(.214, .290),
#'   actw_prop = c(.279, .473),
#'   w_prop = c(.949, .986)
#' )
#'
#' dgnpop(eg2.3, pop = "pop",
#'        factors = c("birth_preg", "preg_actw", "actw_prop", "w_prop")) |>
#'   dg_table()
#'
#' ## 2 populations, R=abcde
#' eg2.4 <- data.frame(
#'   pop = c(1970, 1980),
#'   prop_m = c(.58, .72),
#'   noncontr = c(.76, .97),
#'   abort = c(.84, .97),
#'   lact = c(.66, .56),
#'   fecund = c(16.573, 16.158)
#' )
#'
#' dgnpop(eg2.4, pop = "pop",
#'        factors = c("prop_m", "noncontr", "abort", "lact", "fecund")) |>
#'   dg_table()
#'
#' ## 2 populations, vector factors, R=sum(abc)
#' eg4.3 <- data.frame(
#'   agegroup = rep(1:7, 2),
#'   pop = rep(c(1970, 1960), e = 7),
#'   bm = c(488, 452, 338, 156, 63, 22, 3,
#'          393, 407, 369, 274, 184, 90, 16),
#'   mw = c(.082, .527, .866, .941, .942, .923, .876,
#'          .122, .622, .903, .930, .916, .873, .800),
#'   wp = c(.058, .038, .032, .030, .026, .023, .019,
#'          .043, .041, .036, .032, .026, .020, .018)
#' )
#'
#' dgnpop(eg4.3, pop = "pop", factors = c("bm", "mw", "wp"),
#'        ratefunction = "sum(bm*mw*wp)") |>
#'   dg_table()
#'
#' ## 2 populations, R=f(ab)
#' eg3.1 <- data.frame(
#'   pop = c(1940,1960),
#'   crude_birth = c(19.4, 23.7),
#'   crude_death = c(10.8, 9.5)
#' )
#' dgnpop(eg3.1, pop = "pop",
#'        factors = c("crude_birth","crude_death"),
#'        ratefunction = "crude_birth-crude_death") |>
#'   dg_table()
#'
#' ## 2 populations, vector factors, R=f(abcd)
#' eg4.4 <- data.frame(
#'   pop = rep(c(1963,1983), e = 6),
#'   agegroup = c("15-19","20-24","25-29","30-34","35-39","40-44"),
#'   A = c(.200,.163,.146,.154,.168,.169,
#'         .169,.195,.190,.174,.150,.122),
#'   B = c(.866,.325,.119,.099,.099,.121,
#'         .931,.563,.311,.216,.199,.191),
#'   C = c(.007,.021,.023,.015,.008,.002,
#'         .018,.026,.023,.016,.008,.002),
#'   D = c(.454,.326,.195,.107,.051,.015,
#'         .380,.201,.149,.079,.025,.006)
#' )
#'
#' dgnpop(eg4.4, pop = "pop", factors = c("A","B","C","D"),
#'        id_vars = "agegroup",
#'        ratefunction = "sum(A*B*C) / (sum(A*B*C) + sum(A*(1-B)*D))") |>
#'   dg_table()
#'
#' ### alternatively:
#' myratef <- function(a,b,c,d){
#'   return( sum(a*b*c) / (sum(a*b*c) + sum(a*(1-b)*d))  )
#' }
#' dgnpop(eg4.4, pop = "pop", factors = c("A","B","C","D"),
#'        id_vars = "agegroup",
#'        ratefunction = "myratef(A,B,C,D)") |>
#'   dg_table()
#'
#' ## using crossclassified for relative size:
#' eg5.1 <- data.frame(
#'   age_group = rep(c("15-19","20-24","25-29","30-34","35-39",
#'                     "40-44","45-49","50-54","55-59","60-64",
#'                     "65-69","70-74","75+"), 2),
#'   pop = rep(c(1970,1985), e = 13),
#'   size = c(12.9,10.9,9.5,8.0,7.8,8.4,8.6,7.8,7.0,5.9,4.7,3.6,4.9,
#'            10.1,11.2,11.6,10.9,9.4,7.7,6.3,6.0,6.3,5.9,5.1,4.0,5.5),
#'   rate = c(1.9,25.8,45.7,49.6,51.2,51.6,51.8,54.9,58.7,60.4,62.8,66.6,66.8,
#'            2.2,24.3,45.8,52.5,56.1,55.6,56.0,57.4,57.2,61.2,63.9,68.6,72.2)
#' )
#' dgnpop(eg5.1, pop = "pop", factors = c("rate"),
#'        id_vars = "age_group",
#'        crossclassified = "size") |>
#'   dg_table()
#'
#' ## 2 cross-classified variables, 2 populations, R=sum(w*r)
#' eg5.3 <- data.frame(
#'   race = rep(rep(1:2, e = 11), 2),
#'   age = rep(rep(1:11,2), 2),
#'   pop = rep(c(1985,1970), e = 22),
#'   size = c(3041,11577,27450,32711,35480,27411,19555,19795,15254,8022,2472,
#'            707,2692,6473,6841,6547,4352,3034,2540,1749,804,236,
#'            2968,11484,34614,30992,21983,20314,20928,16897,11339,5720,1315,
#'            535,2162,6120,4781,3096,2718,2363,1767,1149,448,117),
#'   rate = c(9.163,0.462,0.248,0.929,1.084,1.810,4.715,12.187,27.728,64.068,157.570,
#'            17.208,0.738,0.328,1.103,2.045,3.724,8.052,17.812,34.128,68.276,125.161,
#'            18.469,0.751,0.391,1.146,1.287,2.672,6.636,15.691,34.723,79.763,176.837,
#'            36.993,1.352,0.541,2.040,3.523,6.746,12.967,24.471,45.091,74.902,123.205)
#' )
#'
#' dgnpop(eg5.3, pop = "pop", factors = c("rate"),
#'        id_vars = c("race","age"),
#'        crossclassified = "size") |>
#'   dg_table()
#'
#'
#' ## 5 populations, R = f(abcd)
#' eg6.5 <- data.frame(
#'   pop=rep(c(1963,1968,1973,1978,1983),e=6),
#'   agegroup=c("15-19","20-24","25-29","30-34","35-39","40-44"),
#'   A = c(.200,.163,.146,.154,.168,.169,
#'         .215,.191,.156,.137,.144,.157,
#'         .218,.203,.175,.144,.127,.133,
#'         .205,.200,.181,.162,.134,.118,
#'         .169,.195,.190,.174,.150,.122),
#'   B = c(.866,.325,.119,.099,.099,.121,
#'         .891,.373,.124,.100,.107,.127,
#'         .870,.396,.158,.125,.113,.129,
#'         .900,.484,.243,.176,.155,.168,
#'         .931,.563,.311,.216,.199,.191),
#'   C = c(.007,.021,.023,.015,.008,.002,
#'         .010,.023,.023,.015,.008,.002,
#'         .011,.016,.017,.011,.006,.002,
#'         .014,.019,.015,.010,.005,.001,
#'         .018,.026,.023,.016,.008,.002),
#'   D = c(.454,.326,.195,.107,.051,.015,
#'         .433,.249,.159,.079,.037,.011,
#'         .314,.181,.133,.063,.023,.006,
#'         .313,.191,.143,.069,.021,.004,
#'         .380,.201,.149,.079,.025,.006)
#' )
#'
#' dgnpop(eg6.5, pop = "pop", factors = c("A","B","C","D"),
#'        id_vars = "agegroup",
#'        ratefunction = "1000*sum(A*B*C) / (sum(A*B*C) + sum(A*(1-B)*D))")$rates |>
#'   dg_table()
#'
#' dgnpop(eg6.5, pop = "pop", factors = c("A","B","C","D"),
#'        id_vars = "agegroup",
#'        ratefunction = "1000*sum(A*B*C) / (sum(A*B*C) + sum(A*(1-B)*D))")$rates |>
#'   dg_plot()
dgnpop <- function(x, pop, factors, id_vars = NULL, crossclassified = NULL,
                   ratefunction = NULL, agg = TRUE, baseline = NULL, quietly = TRUE){

  tmpdf <- as.data.frame(x)

  ##########
  # Rate functions
  ##########
  user_RF <- TRUE
  if(is.null(ratefunction)){
    user_RF <- FALSE
    ratefunction <- paste(factors, collapse = "*")
  }
  if(!is.null(crossclassified)){
    ratefunction_crude <- paste0("sum(",crossclassified,"/sum(",crossclassified,")*",ratefunction,")")
  } else {
    ratefunction_crude <- ratefunction
  }

  ##########
  # CHECK
  ##########
  # stops if crossclassified
  output_agg <- TRUE
  if(!is.null(crossclassified)){
    if(length(eval(parse(text = ratefunction), envir = as.list(tmpdf)))==1){
      stop("when the size of cross-classified sub-populations is provided alongside a user defined rate function, the function should NOT summarise over the sub-populations into a single value. e.g., use 'rate' instead of 'sum(rate)'.")
    }
    if(crossclassified %in% factors){
      stop("for cross-classified data, the variable indicating size of sub-populations should be included in the 'crossclassified' argument OR as a compositional factor when crossclassified = NULL, not both")
    }
    output_agg <- agg
  }
  if(!is.null(id_vars) & is.null(crossclassified)){
    if(length(eval(parse(text = ratefunction), envir = as.list(tmpdf)))>1){
      message("ratefunction does not summarise over sub-populations into a single value (e.g., 'sum(A*B*C)'), and individual sub-population specific standardised rates are returned.")
      output_agg <- FALSE
    }
  }
  if(!agg & !is.null(crossclassified)){
    message("for cross-classified data, when agg = FALSE then individual sub-population specific standardised rates are returned.")
    output_agg <- FALSE
  }

  # population names mustn't be contained in factor names
  while( sapply(tmpdf[[pop]], \(x) grepl(x,factors)) |> any() |
    sapply(factors, \(x) grepl(x,tmpdf[[pop]])) |> any() ){
      tmpdf[[pop]] <- paste0("pop.",tmpdf[[pop]])
  }


  tmpdf[[pop]] <- factor(tmpdf[[pop]])

  allpops <- unique(tmpdf[[pop]])
  nfact <- length(factors)

  .makepopdf <- function(x){
    popdf = tmpdf[tmpdf[[pop]] %in% x, ]
    popdf[[pop]] = factor(popdf[[pop]], levels = x, ordered =T)
    popdf
  }


  ##########
  # CRUDE RATES
  ##########
  if(output_agg){
    cr_dat <- lapply(allpops, \(x) .makepopdf(x))
    crude <-
      data.frame(
        rate = sapply(cr_dat, \(x) eval(parse(text = ratefunction_crude), envir = as.list(x))),
        pop = allpops,
        std.set = NA,
        factor = "crude"
    )
  }


  ##########
  #THE DAS GUPTA METHOD
  ##########
  if(output_agg){message(
    paste0("\nDG decomposition being conducted with R = ",ratefunction,"\n")
  )}
  if(!output_agg){message(
    paste0("\nDG decomposition being conducted with R_i = ",ratefunction,"\n")
  )}


  pairwise_pops <- combn(as.character(allpops), 2)

  pairwise_est <- apply(pairwise_pops, 2, \(x) .makepopdf(x))


  if(length(allpops)<=2){
    # ONLY 2 populations, use dg2pop directly.
    if(!is.null(crossclassified)){
      ## XC
      DG_OUT <- ccwrap(pairwise_est[[1]], pop = pop, factors = factors,
                       id_vars = id_vars, crossclassified = crossclassified, agg = output_agg,
                       ratefunction = ratefunction, quietly = quietly)

      if(output_agg){
        DG_OUT <- DG_OUT[ ,c("rate","pop","std.set","factor")]
        DG_OUT <- rbind(crude,DG_OUT)
      } else {
        DG_OUT <- DG_OUT[ ,c("rate","pop","std.set","factor",id_vars)]
      }
    } else {
      ## NOT XC
      DG_OUT <- dg2pop(pairwise_est[[1]],
                      pop = pop, factors = factors, id_vars = id_vars,
                      ratefunction = ratefunction, quietly = quietly)
      DG_OUT <- do.call(rbind, DG_OUT)

      if(output_agg){
        # remove diff for 2-pop only, add crude if agg
        DG_OUT <- DG_OUT[ ,c("rate","pop","std.set","factor")]
        DG_OUT <- rbind(crude,DG_OUT)
      } else{
        DG_OUT <- DG_OUT[ ,c("rate","pop","std.set","factor",id_vars)]
      }
      row.names(DG_OUT) <- NULL
    }
    # final output
    dgo <- DG_OUT

  } else {
    ##### N population standardisation
    if(!quietly){print("Standardising and decomposing for all pairwise comparisons...")}

    if(!is.null(baseline)){
      pairwise_est <- pairwise_est[ sapply(pairwise_est, \(x) baseline %in% x[[pop]]) ]
    }

    if(!is.null(crossclassified)){
      ## XC
      dgNp_res <- lapply(pairwise_est, \(x)
                         ccwrap(x, pop = pop, factors = factors,
                                id_vars = id_vars, crossclassified = crossclassified,
                                agg = output_agg, ratefunction = ratefunction, quietly = quietly))
      dgNp_res <- do.call(rbind, dgNp_res)
      row.names(dgNp_res) <- NULL

    } else {
      ## NOT XC
      dgNp_res <- lapply(pairwise_est, \(x)
                        dg2pop(x,
                               pop=pop,factors=factors,id_vars=id_vars,
                               ratefunction=ratefunction, quietly=quietly))
      dgNp_res <- lapply(dgNp_res, \(x) do.call(rbind,x))
      dgNp_res <- do.call(rbind, dgNp_res)
      row.names(dgNp_res) <- NULL
    }

    DG_OUT.rates <- list()
    DG_OUT.diffs <- list()

    for(f in unique(dgNp_res[['factor']])){

      dgNp_rates = dgNp_res[dgNp_res$factor == f, ]
      if(!is.null(baseline)){
        standardized_rates <- dgNp_rates[dgNp_rates$std.set == baseline,
                                        c("rate","pop","std.set","factor")]

        # NOT NEEDED
        # difference_effects = dgNp_rates[dgNp_rates$std.set == baseline,
        #            c("diff","pop","diff.calc","factor")]

      } else {

        #std_rates
        if(!quietly){print(paste0("Standardizing P-",f," across N pops..."))}

        #these are the standardized rate for factor f in each year, stnadardixed over all Ys.
        standardized_rates <- lapply(allpops, \(x) dg611(dgNp_rates, allpops, x, f))
        standardized_rates <- do.call(rbind, standardized_rates)

        if(!quietly){print(paste0("Getting decomposition effects for P-",f," standardised rates..."))}

        pairwise_pops <- combn(allpops, 2, simplify = F)

        difference_effects <- lapply(pairwise_pops, \(x) dg612(dgNp_rates, allpops, x, f))
        difference_effects <- do.call(rbind, difference_effects)

      }
      DG_OUT.rates[[f]] <- standardized_rates
      DG_OUT.diffs[[f]] <- difference_effects
    }

    # tidy rates and add crude
    DG_OUT.rates <- do.call(rbind, DG_OUT.rates)
    DG_OUT.rates <- rbind(crude, DG_OUT.rates)
    row.names(DG_OUT.rates) <- NULL
    # tidy diffs
    DG_OUT.diffs <- do.call(rbind, DG_OUT.diffs)
    row.names(DG_OUT.diffs) <- NULL

    # final output
    dgo <- list(rates = DG_OUT.rates, diffs = DG_OUT.diffs)

  }
  return(dgo)
}
