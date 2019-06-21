#' Very messy logic for DasGuptas equation 6.12
#' Outputs a vector
#' @param df dataframe or tibble object, with each columns specifying the factor-effect for all pairwise comparisons of populations.
#' @param y1 numeric or character vector indicating population 1 of factor-effect A between y1-y2
#' @param y2 numeric or character vector indicating population 2 of factor-effect A between y1-y2
#' @param y3 numeric or character vector indicating population j of the DG:6.12 equation (intention is to loop this function taking all other populations as j, thereby standardising y1-y2 factor effect across other populations)
#' @export 
#' @examples
#' ......
DG612numerator<-function(df,y1,y2,yj){
  a12=df[,grepl(y1,names(df)) & grepl(y2,names(df))]
  a2j=df[,grepl(y2,names(df)) & !grepl(paste0("vs",y2),names(df)) & grepl(yj,names(df))]
  a2jn=-df[,grepl(paste0("vs",y2),names(df)) & grepl(yj,names(df))]
  a1j=-df[,grepl(y1,names(df)) & !grepl(paste0("vs",y1),names(df)) & grepl(yj,names(df))]
  a1jn=df[,grepl(paste0("vs",y1),names(df)) & grepl(yj,names(df))]
  tibble(
    a12=a12[[1]],
    a2j=ifelse(length(a2j!=0),a2j,a2jn) %>% unlist,
    a1j=ifelse(length(a1j!=0),a1j,a1jn) %>% unlist
  ) %>% rowSums()
}
