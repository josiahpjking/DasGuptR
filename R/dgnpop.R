#' Standardisation and decomposition of rates over P rate-factors and N populations.
#' Outputs a ? object
#' @param df dataframe or tibble object, with columns specifying 1) population and 2) each rate-factor to be considered
#' @param pop tidyselect variable indicating population ID
#' @param ... tidyselect variables indicating rate-factors
#' @param id_vars character vector of variable names in dataframe to attach back to output (useful if analysing sub-population specific rates)
#' @param baseline baseline population to standardise against. if NULL then will do Das Gupta's full N-population standardisation.
#' @param ratefunction allows user to define rate as a specific function F of factors. This should be a character string of the r syntax, with the factor names. Defaults to the product (e.g., "a*b").
#' @export
#' @examples
#'
#' # The case of 2 factors (2 populations)
#' eg2.1 <- data.frame(
#'   pop = c("black","white"),
#'   avg_earnings = c(10930, 16591),
#'   earner_prop = c(.717892, .825974)
#' )
#' dgnpop(eg2.1, pop="pop", factors=c("avg_earnings", "earner_prop"))
#'
#' # The case of 3 factors (2 populations)
#' eg2.3 <- data.frame(
#'   pop = c("austria","chile"),
#'   birthsw1549 = c(51.78746, 84.90502),
#'   propw1549 = c(.45919, .75756),
#'   propw = c(.52638, .51065)
#' )
#' dgnpop(eg2.3, pop="pop", factors=c("birthsw1549", "propw1549", "propw"))
#'
#' # The case of 4 factors (2 populations)
#' eg2.5 <- data.frame(
#'   pop = c(1971, 1979),
#'   birth_preg = c(25.3, 32.7),
#'   preg_actw = c(.214, .290),
#'   actw_prop = c(.279, .473),
#'   w_prop = c(.949, .986)
#' )
#' dgnpop(eg2.5, pop="pop", factors=c("birth_preg", "preg_actw", "actw_prop", "w_prop"))
#'
#' # The case of 5 factors (2 populations)
#' eg2.7 <- data.frame(
#'   pop = c(1970, 1980),
#'   prop_m = c(.58, .72),
#'   noncontr = c(.76, .97),
#'   abort = c(.84, .97),
#'   lact = c(.66, .56),
#'   fecund = c(16.573, 16.158)
#' )
#'
#' dgnpop(eg2.7, pop="pop", factors=c("prop_m", "noncontr", "abort", "lact", "fecund"))
#'
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
#' dgout <- dgnpop(eg4.5, pop="pop", factors=c("bm", "mw", "wp"), id_vars=c("agegroup"))
#' dg_rates(dgout)

dgnpop<-function(df,pop,factors,baseline=NULL,id_vars=NULL,ratefunction=NULL, quietly = TRUE){


  tmpdf = as.data.frame(df)
  tmpdf[[pop]] = factor(tmpdf[[pop]])

  allpops = unique(tmpdf[[pop]])
  nfact = length(factors)

  ##########
  #THE DAS GUPTA METHOD
  ##########
  if(!is.null(id_vars)){
    subpop = interaction(tmpdf[,id_vars])
  } else {
    subpop = rep(1,nrow(tmpdf))
  }

  dgo = list()

  for(g in unique(subpop)){
    #g = unique(subpop)[1]
    tmpdf2 = tmpdf[subpop==g, ]

    .makepopdf <- function(x){
      popdf = tmpdf2[tmpdf2[[pop]] %in% x, ]
      popdf[[pop]] = factor(popdf[[pop]], levels = x, ordered =T)
      popdf
    }

    pairwise_pops = combn(as.character(allpops), 2)

    pairwise_est = apply(pairwise_pops, 2, \(x) .makepopdf(x))


    if(length(allpops)<=2){
      # ONLY 2 populations, use dg2pop directly.
      DG_OUT = dg2pop(pairwise_est[[1]],
                      pop=pop,factors=factors,
                      ratefunction=ratefunction, quietly=quietly)
      DG_OUT = do.call(rbind, DG_OUT)
      if(!is.null(id_vars)){
        DG_OUT = merge(DG_OUT, unique(tmpdf[subpop==g, id_vars, drop = FALSE]))
      }
    } else {
      ##### N population standardisation
      if(!quietly){print("Standardising and decomposing for all pairwise comparisons...")}

      if(!is.null(baseline)){
        pairwise_est = pairwise_est[ sapply(pairwise_est, \(x) baseline %in% x[[pop]]) ]
      }


      dg2p_res = lapply(pairwise_est, \(x)
                         dg2pop(x, pop, factors,
                                ratefunction, quietly=quietly))

      dg2p_res = lapply(dg2p_res, \(x) do.call(rbind,x))
      dg2p_res = do.call(rbind, dg2p_res)
      row.names(dg2p_res) <- NULL

      DG_OUT = list()

      for(f in factors){

        dg2p_rates = dg2p_res[dg2p_res$factor == f, ]

        if(!is.null(baseline)){
            standardized_rates = dg2p_rates[dg2p_rates$adj.set == baseline, ]
            difference_effects = data.frame()
        } else {
          #std_rates
          if(!quietly){print(paste0("Standardizing P-",f," across N pops..."))}
          #these are the standardized rate for factor f in each year, stnadardixed over all Ys.
          standardized_rates = lapply(allpops, \(x) dg611(dg2p_rates, allpops, x, f))
          standardized_rates = do.call(rbind, standardized_rates)

          if(!quietly){print(paste0("Getting decomposition effects for P-",f," standardised rates..."))}
          pairwise_pops = combn(allpops, 2, simplify = F)
          difference_effects = lapply(pairwise_pops, \(x) dg612(dg2p_rates, allpops, x, f))

        }
        DG_OUT[[f]]=bind_rows(standardized_rates,difference_effects)
      }

      DG_OUT = lapply(DG_OUT, \(x) merge(x, unique(tmpdf[subpop==g, id_vars, drop = FALSE])))
      DG_OUT = do.call(rbind, DG_OUT)
    }
    dgo[[g]]=DG_OUT
  }

  # # tidy output
  # if(is.null(id_vars)){
  #   dgo = enframe(unlist(dgo,recursive = F)) %>% unnest(value, names_repair = "universal")
  #   names(dgo)[1] = "factor"
  # }else{
  #   # dgo = do.call(rbind, dgo)
  #   dgo = enframe(unlist(dgo,recursive = F)) %>% unnest(value, names_repair = "unique") %>%
  #     separate(1, into=c("subpop","factor"),"\\.",fill = "right")
  # }
  # if("name...2" %in% names(dgo)){
  #   dgo =
  #     dgo %>%
  #     separate(name...2, into=c("ff","pop","ff2"), "\\.") %>%
  #     select(-ff,-ff2) %>%
  #     pivot_wider(names_from="pop",values_from="value") %>%
  #     arrange(factor)
  # }
  # #dgo = merge(fctname_map, dgo)
  # dgo = dgo[,-which(names(dgo)=="factor")]
  # names(dgo)[which(names(dgo)=="fct_name")] <- "factor"
  # tidy
  dgo = do.call(rbind, dgo)
  row.names(dgo) = NULL
  return(dgo)
}







