% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ccwrap.R
\name{ccwrap}
\alias{ccwrap}
\title{Wrapper for cross-classified data that standardises rates across a pair of populations.}
\usage{
ccwrap(
  pw,
  pop,
  factors,
  id_vars,
  crossclassified,
  agg,
  ratefunction = NULL,
  quietly = TRUE
)
}
\arguments{
\item{pw}{dataframe containing two populations worth of factor data, with columns specifying 1) population and 2) each rate-factor to be considered. must have column named "pop" indicating the population ID.}

\item{pop}{name (character string) of variable indicating population}

\item{factors}{names (character vector) of variables indicating compositional factors}

\item{id_vars}{character vector of variables indicating sub-populations}

\item{crossclassified}{character string of variable indicating size of sub-population. If specified, the proportion of each population in a given sub-population (e.g. each age-sex combination) is re-expressed as a product of symmetrical expressions representing the different variables (age, sex) constituting the sub-populations.}

\item{agg}{logical indicating whether, when cross-classified data is used, to output should be aggregated up to the population level}

\item{ratefunction}{user defined character string in R syntax that when evaluated specifies the function defining the rate as a function of factors. if NULL then will assume rate is the product of all factors.}

\item{quietly}{logical indicating whether interim messages should be outputted indicating progress through the P factors}
}
\description{
Wrapper for cross-classified data that standardises rates across a pair of populations.
}
