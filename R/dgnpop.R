#' Standardisation and decomposition of rates over P rate-factors and N populations.
#' Outputs a ? object
#' @param df dataframe or tibble object, with columns specifying 1) population, 2) each rate-factor to be considered, and (optionally) 3) variables indicating underlying subpopulations
#' @param pop name (character string) of variable indicating population
#' @param factors names (character vector) of variables indicating compositional factors
#' @param id_vars character vector of variables indicating sub-populations
#' @param ratefunction user defined character string in R syntax that when evaluated specifies the function defining the rate as a function of factors. if NULL then will assume rate is the product of all factors.
#' @param baseline baseline population to standardise against. if NULL then will do Das Gupta's full N-population standardisation.
#' @param quietly logical indicating whether interim messages should be outputted indicating progress through the P factors and N populations
#' @export
#' @examples
#'
dgnpop<-function(df,pop,factors,id_vars=NULL,ratefunction=NULL,baseline=NULL,quietly = TRUE){

  tmpdf = as.data.frame(df)
  tmpdf[[pop]] = factor(tmpdf[[pop]])

  allpops = unique(tmpdf[[pop]])
  nfact = length(factors)

  # Create rate function if not specified
  if(is.null(ratefunction)){
    ratefunction=paste(factors,collapse="*")
  }

  # Check ratefunction when id_vars given
  if(!is.null(id_vars)){
    if(length(eval(parse(text = ratefunction), envir = as.list(tmpdf)))>1){
      stop("when id_vars are specified, the ratefunction must be appropriate for a vector-factor.\ni.e. it must summarise to a single value such as sum(A*B*C)")
    }
  }



  ##########
  #THE DAS GUPTA METHOD
  ##########
  .makepopdf <- function(x){
    popdf = tmpdf[tmpdf[[pop]] %in% x, ]
    popdf[[pop]] = factor(popdf[[pop]], levels = x, ordered =T)
    popdf
  }

  pairwise_pops = combn(as.character(allpops), 2)

  pairwise_est = apply(pairwise_pops, 2, \(x) .makepopdf(x))

  if(length(allpops)<=2){
    # ONLY 2 populations, use dg2pop directly.
    DG_OUT = dg2pop(pairwise_est[[1]],
                    pop=pop,factors=factors,id_vars=id_vars,
                    ratefunction=ratefunction, quietly=quietly)
    DG_OUT = do.call(rbind, DG_OUT)

  } else {
    ##### N population standardisation
    if(!quietly){print("Standardising and decomposing for all pairwise comparisons...")}

    if(!is.null(baseline)){
      pairwise_est = pairwise_est[ sapply(pairwise_est, \(x) baseline %in% x[[pop]]) ]
    }


    dgNp_res = lapply(pairwise_est, \(x)
                      dg2pop(x,
                             pop=pop,factors=factors,id_vars=id_vars,
                             ratefunction=ratefunction, quietly=quietly))
    dgNp_res = lapply(dgNp_res, \(x) do.call(rbind,x))
    dgNp_res = do.call(rbind, dgNp_res)
    row.names(dgNp_res) <- NULL

    DG_OUT = list()

    for(f in factors){

      dgNp_rates = dgNp_res[dgNp_res$factor == f, ]
      if(!is.null(baseline)){
        standardized_rates = dgNp_rates[dgNp_rates$adj.set == baseline, ]
        difference_effects = data.frame()
      } else {

        #std_rates
        if(!quietly){print(paste0("Standardizing P-",f," across N pops..."))}

        #these are the standardized rate for factor f in each year, stnadardixed over all Ys.
        standardized_rates = lapply(allpops, \(x) dg611(dgNp_rates, allpops, x, f))
        standardized_rates = do.call(rbind, standardized_rates)

        if(!quietly){print(paste0("Getting decomposition effects for P-",f," standardised rates..."))}

        pairwise_pops = combn(allpops, 2, simplify = F)
        difference_effects = lapply(pairwise_pops, \(x) dg612(dgNp_rates, allpops, x, f))

      }
      DG_OUT[[f]]=bind_rows(standardized_rates,difference_effects)
    }
    DG_OUT = do.call(rbind, DG_OUT)
  }
  dgo=DG_OUT

  row.names(dgo) = NULL
  return(dgo)
}
