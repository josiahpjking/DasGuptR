#' Das Gupta extract adjusted rates
#' @param df DG output
#' @export
#' @examples
#' ......
DasGupt_rates<-function(df){
  df %>%
    group_by(factor) %>%
    summarise_at(vars(starts_with("pop")),sum) %>%
    gather(population,rate,starts_with("pop")) %>%
    mutate(population=gsub("pop","",population))
}
