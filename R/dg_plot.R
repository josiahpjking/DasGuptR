#' Creates a plot of Das Gupta adjusted rates across the set of populations
#' @param dgo DG output
#' @export
dg_plot<-function(dgo){
  pops = as.numeric(factor(dgo[['pop']]))
  ps_labs = as.character(dgo[['pop']])
  rates = dgo[['rate']]

  fs = unique(dgo[['factor']])
  fs_lab = ifelse(tolower(fs)=="crude",
                  "crude",
                  paste0("P-",tolower(fs)," adjusted"))

  fcols <- rainbow(length(fs))

  plot(pops,rates,type='n',xlab="population",ylab="rate",xaxt='n')
  axis(1, at=pops, labels=ps_labs)
  for(f in seq_along(fs)){
    points(
      x = dgo[dgo$factor == fs[f],'pop'],
      y = dgo[dgo$factor == fs[f],'rate'],
      col = fcols[f]
    )
    lines(x = dgo[dgo$factor == fs[f],'pop'],
          y = dgo[dgo$factor == fs[f],'rate'],
          col = fcols[f], lwd = 2, lty = 2)
  }
  legend("topright", legend = fs_lab, col = fcols, lwd = 2)
}
