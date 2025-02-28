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
#' data.frame with TODO finish this
#' @export
#' @examples
#' dgnpop()
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
