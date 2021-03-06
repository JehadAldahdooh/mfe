% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/discriminant.R
\name{mf.discriminant}
\alias{mf.discriminant}
\alias{mf.discriminant.default}
\alias{mf.discriminant.formula}
\title{Discriminant meta-features}
\usage{
mf.discriminant(...)

\method{mf.discriminant}{default}(x, y, features = "all",
  transform.attr = TRUE, ...)

\method{mf.discriminant}{formula}(formula, data, features = "all",
  transform.attr = TRUE, ...)
}
\arguments{
\item{...}{Not used.}

\item{x}{A data.frame contained only the input attributes}

\item{y}{a factor response vector with one label for each row/component of x.}

\item{features}{A list of features names or \code{"all"} to include all them.}

\item{transform.attr}{A logical value indicating if the categorical
attributes should be transformed to numerical.}

\item{formula}{A formula to define the class column.}

\item{data}{A data.frame dataset contained the input attributes and class
The details section describes the valid values for this group.}
}
\value{
A list named by the requested meta-features.
}
\description{
Discriminant meta-features are computed using the discriminant analysis. It
is computed using just the numerical attributes.
}
\details{
The following features are allowed for this method:
 \describe{
   \item{"cancor"}{Represents the first canonical discriminant correlations
      of the numeric attributes in the dataset.}
   \item{"center.of.gravity"}{Represents the distance between minority and
      majority classes in the dataset.}
   \item{"discfct"}{Represents the number of discriminant functions
      normalized by the number of classes"}
   \item{"cancor.fract"}{Represents a measure of collinearity of the class
      means. It is computed using the squares of the canonical correlations
      instead of the eigenvalues.}
   \item{"eigen.fract"}{Represents the relative importance of the largest
      eigenvalue of the attribute covariance matrix computed from the
      numeric attributes in the dataset.}
   \item{"sdratio"}{Represents the test statistic for homogeneity of
      covariances. It uses the Box's M test and it is is strictly greater
      than unity if the covariances differ, and is equal to unity if and only
      if the M-statistic is zero.}
 }

 The categorical attributes is replaced by binaries attributes.
}
\examples{
## Extract all metafeatures
mf.discriminant(Species ~ ., iris)

## Extract some metafeatures
mf.discriminant(iris[1:4], iris[5], c("cancor", "cancor.fract"))
}
\references{
Michie, E. D., Spiegelhalter, D. J., & Taylor, C. C. (1994).
   Machine Learning , Neural and Statistical Classification.
   Technometrics, 37(4), 459.

 Castiello, C., Castellano, G., & Fanelli, A. M. (2005). Meta-data:
   Characterization of Input Features for Meta-learning. In Proceedings of
   the 2nd International Conference on Modeling Decisions for Artificial
   Intelligence (Vol. 3558, pp. 457-468).

 Lindner, G., & Studer, R. (1999). AST: Support for Algorithm Selection with
   a CBR Approach. Principles of Data Mining and Knowledge Discovery,
   1704, 418-423.

 Ali, S., & Smith, K. a. (2006). On learning algorithm selection for
   classification. Applied Soft Computing, 6(2), 119-138.
}
\seealso{
Other meta.features: \code{\link{mf.general}},
  \code{\link{mf.infotheo}}, \code{\link{mf.landmarking}},
  \code{\link{mf.model.based}},
  \code{\link{mf.statistical}}
}

