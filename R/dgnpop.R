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
#' dgnpop(eg2.1, pop=pop, avg_earnings, earner_prop)
#'
#' # The case of 3 factors (2 populations)
#' eg2.3 <- data.frame(
#'   pop = c("austria","chile"),
#'   birthsw1549 = c(51.78746, 84.90502),
#'   propw1549 = c(.45919, .75756),
#'   propw = c(.52638, .51065)
#' )
#' dgnpop(eg2.3, pop=pop, birthsw1549, propw1549, propw)
#'
#' # The case of 4 factors (2 populations)
#' eg2.5 <- data.frame(
#'   pop = c(1971, 1979),
#'   birth_preg = c(25.3, 32.7),
#'   preg_actw = c(.214, .290),
#'   actw_prop = c(.279, .473),
#'   w_prop = c(.949, .986)
#' )
#' dgnpop(eg2.5, pop=pop, birth_preg, preg_actw, actw_prop, w_prop)
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
#' dgnpop(eg2.7, pop=pop, prop_m, noncontr, abort, lact, fecund)
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
#' dgnpop(eg4.5, pop=pop, bm, mw, wp, id_vars=c("agegroup"))
#' dgout <- dgnpop(eg4.5, pop=pop, bm, mw, wp, id_vars=c("agegroup"))
#' dg_rates(dgout)
dgnpop<-function(df,pop,...,baseline=NULL,id_vars=NULL,ratefunction=NULL, quietly = TRUE){

  factrs_names = map_chr(enquos(...),quo_name)
  nfact = length(factrs_names)
  tmpdf = df
  tmpdf$pop = factor(tmpdf %>% pull({{pop}}))
  tmpdf = tmpdf %>% dplyr::arrange(pop, vars(id_vars))

  fctname_map = data.frame(fct_name = names(tmpdf)[names(tmpdf) %in% factrs_names], factor = paste0("fact",letters[1:nfact]))
  if(!is.null(ratefunction)){
    for(i in 1:nfact){
      ratefunction = gsub(sort(factrs_names)[i], paste0("fact",letters[i]), ratefunction)
    }
  }
  names(tmpdf)[names(tmpdf) %in% factrs_names] <-
    paste0("fact",letters[1:nfact])


  factrs = paste0("fact",letters[1:nfact])
  allpops = unique(tmpdf$pop)

  ##########
  #THE DAS GUPTA METHOD
  ##########
  tmpdf$subpop = gsub(" ","",apply(as.data.frame(tmpdf[,id_vars]), 1, function(x) paste0(x, collapse="")))
  dgo = list()

  for(g in unique(tmpdf$subpop)){
    tmpdf2 = tmpdf[tmpdf$subpop==g, ]

    if(length(allpops)<=2){
        # ONLY 2 populations, use dg2pop directly.
        pairwise_pops = combn(as.character(allpops), 2)

        pairwise_est = apply(pairwise_pops, 2, function(x)
          dplyr::filter(tmpdf2, pop %in% x) %>%
            mutate(pop = factor(pop, levels=x, ordered=T)))

        DG_OUT = dg2pop(pairwise_est[[1]], factrs, ratefunction, quietly=quietly)

    } else {
      ##### N population standardisation
      if(!quietly){print("Standardising and decomposing for all pairwise comparisons...")}

      pairwise_pops = combn(as.character(allpops), 2)

      pairwise_est = apply(pairwise_pops, 2, function(x)
          dplyr::filter(tmpdf2, pop %in% x) %>%
            mutate(pop = factor(pop, levels=x,ordered=T)))

      dg2p_res2 = lapply(pairwise_est, function(x) dg2pop(x, factrs, ratefunction, quietly=quietly))
      dg2p_res2 = lapply(dg2p_res2, function(x) unlist(x, recursive = F))
      dg2p_res2 = enframe(unlist(dg2p_res2))

      DG_OUT = list()

      for(f in factrs){
        dg2p_rates2 = dg2p_res2[grepl(f,dg2p_res2$name) & !grepl(".diff_",dg2p_res2$name), ]
        dg2p_rates2 = dg2p_rates2[!duplicated(dg2p_rates2),]
        dg2p_facteffs2 = dg2p_res2[grepl(paste0(f,".diff"),dg2p_res2$name), ]

        if(!is.null(baseline)){
            standardized_rates2 = dg2p_rates2[grepl(paste0(".adj",baseline), dg2p_rates2$name),]
            difference_effects2 = dg2p_facteffs2[grepl(paste0(".diff_",baseline), dg2p_facteffs2$name),]
        } else {
          #std_rates
          if(!quietly){print(paste0("Standardizing P-",f," across N pops..."))}
          #these are the standardized rate for factor f in each year, stnadardixed over all Ys.
          standardized_rates = lapply(allpops, function(x) dg611(dg2p_rates2, allpops, as.character(x),f))
          standardized_rates = enframe(unlist(standardized_rates))

          if(!quietly){print(paste0("Getting decomposition effects for P-",f," standardised rates..."))}
          pairwise_pops = combn(allpops, 2, simplify = F)
          difference_effects = lapply(pairwise_pops, function(x) dg612(dg2p_facteffs2, allpops, x, f))
          difference_effects = enframe(unlist(difference_effects))
        }
        DG_OUT[[f]]=bind_rows(standardized_rates,difference_effects)
      }
    }
    dgo[[g]]=DG_OUT
  }

  # tidy output
  if(is.null(id_vars)){
    dgo = enframe(unlist(dgo,recursive = F)) %>% unnest(value, names_repair = "universal")
    names(dgo)[1] = "factor"
  }else{
    dgo = enframe(unlist(dgo,recursive = F)) %>% unnest(value, names_repair = "unique") %>%
      separate(1, into=c("subpop","factor"),"\\.",fill = "right")
  }
  if("name...2" %in% names(dgo)){
    dgo =
      dgo %>%
      separate(name...2, into=c("ff","pop","ff2"), "\\.") %>%
      select(-ff,-ff2) %>%
      pivot_wider(names_from="pop",values_from="value") %>%
      arrange(factor)
  }
  dgo = merge(fctname_map, dgo)
  dgo = dgo[,-which(names(dgo)=="factor")]
  names(dgo)[which(names(dgo)=="fct_name")] <- "factor"
  return(dgo)
}







