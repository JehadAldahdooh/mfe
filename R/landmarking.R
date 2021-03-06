#' Landmarking Meta-features
#'
#' Landmarking measures are simple and fast algorithms, from which performance
#' characteristics can be extracted. The measures use k-fold cross-validation
#' and the evaluation measure is accuracy. For multi-class classification
#' problems, a decomposition strategy is applied.
#'
#' @family meta-features
#' @param x A data.frame contained only the input attributes
#' @param y A factor response vector with one label for each row/component of x.
#' @param features A list of features names or \code{"all"} to include all them.
#' @param summary A list of methods to summarize the results as post-processing
#'  functions. See \link{post.processing} method to more information. (Default:
#'  \code{c("mean", "sd")})
#' @param map A list of decomposition strategies for multi-class classification
#'  problems. The options are: \code{"one.vs.all"} and \code{"one.vs.one"}
#'  strategy.
#' @param folds The number of k equal size subsamples in k-fold
#'  cross-validation.
#' @param ... Optional arguments to the summary methods.
#' @param formula A formula to define the class column.
#' @param data A data.frame dataset contained the input attributes and class.
#'  The details section describes the valid values for this group.
#' @param transform.attr A logical value indicating if the categorical
#'  attributes should be transformed to numerical.
#' @details
#'  The following features are allowed for this method:
#'  \describe{
#'    \item{"decision.stumps"}{Construct a single DT node model induced by the
#'      most informative attribute. The single split (parallel axis) in the data
#'      has the main goal of establish the linear separability.}
#'    \item{"elite.nearest.neighbor"}{Select the most informative attributes in
#'      the dataset using the information gain ratio to induce the 1-Nearest
#'      Neighbor. With the subset of informative attributes is expected that the
#'      models induced by 1-Nearest Neighbor should be noise tolerant.}
#'    \item{"linear.discriminant"}{Apply the Linear Discriminant classifier to
#'      construct a linear split (non parallel axis) in the data to establish
#'      the linear separability.}
#'    \item{"naive.bayes"}{Evaluate the performance of the Naive Bayes
#'      classifier. It assumes that the attributes are independent and each
#'      example belongs to a certain class based on the Bayes probability.}
#'    \item{"nearest.neighbor"}{This measure evaluate the performance of the
#'      1-Nearest Neighbor classifier. It uses the euclidean distance of the
#'      nearest neighbor to determine how noisy is the data.}
#'    \item{"worst.node"}{Construct a single DT node model induced by the
#'      less informative attribute. With the "decision.stumps" measure is
#'      possible to define a baseline value of linear separability for a
#'      dataset.}
#'  }
#' @return Each one of these meta-features generate multiple values (by fold
#'  and/or binary dataset) and then it is post processed by the summary methods.
#'  See the \link{post.processing} method for more details about it.
#'
#' @references
#'  Pfahringer, B., Bensusan, H., &  Giraud-Carrier, C. G. (2000). Meta-Learning
#'  by Landmarking Various Learning Algorithms. In Proceedings of the 17th
#'  International Conference on Machine Learning (pp. 743-750)
#'
#' @examples
#' ## Extract all meta-features using formula
#' mf.landmarking(Species ~ ., iris)
#'
#' ## Extract all meta-features using data.frame
#' mf.landmarking(iris[1:4], iris[5])
#'
#' ## Extract some meta-features
#' mf.landmarking(Species ~ ., iris, features=c("decision.stumps",
#' "nearest.neighbor", "linear.discriminant"))
#'
#' ## Extract all meta-features with different summary methods
#' mf.landmarking(Species ~ ., iris, summary=c("min", "median", "max"))
#'
#' ## Extract all meta-features one vs one decomposition strategy
#' mf.landmarking(Species ~ ., iris, map="one.vs.one")
#' @export
mf.landmarking <- function(...) {
  UseMethod("mf.landmarking")
}

#' @rdname mf.landmarking
#' @export
mf.landmarking.default <- function(x, y, features="all",
                                   summary=c("mean", "sd"),
                                   map=c("one.vs.all", "one.vs.one"), folds=10,
                                   transform.attr=TRUE, ...) {
  if(!is.data.frame(x)) {
    stop("data argument must be a data.frame")
  }

  if(is.data.frame(y)) {
    y <- y[, 1]
  }
  y <- as.factor(y)

  if(min(table(y)) < 2) {
    stop("number of examples in the minority class should be >= 2")
  }

  if(nrow(x) != length(y)) {
    stop("x and y must have same number of rows")
  }

  map <- match.arg(map)
  if(features[1] == "all") {
    features <- ls.landmarking()
  }
  features <- match.arg(features, ls.landmarking(), TRUE)

  data <- eval(call(map, x, y))
  split <- lapply(data, function(i) {
    createFolds(i[[2]], folds=folds)
  })

  sapply(features, function(f) {
    measure <- mapply(function(data, split) {
      eval(call(f, x=data[[1]], y=data[[2]], split=split,
                transform.attr=transform.attr))
    }, data=data, split=split)
    post.processing(measure, summary)
  }, simplify=FALSE)
}

#' @rdname mf.landmarking
#' @export
mf.landmarking.formula <- function(formula, data, features="all",
                                   summary=c("mean", "sd"),
                                   map=c("one.vs.all", "one.vs.one"), folds=10,
                                   transform.attr=TRUE, ...) {
  if(!inherits(formula, "formula")) {
    stop("method is only for formula datas")
  }

  if(!is.data.frame(data)) {
    stop("data argument must be a data.frame")
  }

  modFrame <- stats::model.frame(formula, data)
  attr(modFrame, "terms") <- NULL

  mf.landmarking.default(modFrame[, -1], modFrame[, 1], features, summary, map,
                         folds, transform.attr, ...)
}

#' List the Landmarking meta-features
#'
#' @return A list of Landmarking meta-features names.
#' @export
#'
#' @examples
#' ls.landmarking()
ls.landmarking <- function() {
  c("decision.stumps", "elite.nearest.neighbor", "linear.discriminant",
    "naive.bayes", "nearest.neighbor", "worst.node")
}

accuracy <- function(pred, class) {
  aux <- table(pred, class)
  sum(diag(aux)) / sum(aux)
}

dt.importance <- function(x, y, test, ...) {
  tryCatch({
    aux <- C50::C5imp(C50::C5.0(x[-test,], y[-test]))
    stats::setNames(aux$Overall, rownames(aux))
  }, error = function(e) {
    stats::setNames(rep(0, ncol(x)), colnames(x))
  })
}

one.vs.one <- function(x, y) {
  comb <- utils::combn(levels(y), 2)
  data <- apply(comb, 2, function(i) {
    n <- subset(x, y %in% i)
    p <- subset(y, y %in% i)
    list(n, factor(p))
  })

  return(data)
}

one.vs.all <- function(x, y) {
  comb <- levels(y)
  data <- lapply(comb, function(i) {
    p <- y
    p[p != i] <- setdiff(comb, i)[1]
    list(x, factor(p))
  })

  if(nlevels(y) < 3)
    return(data[1])
  return(data)
}

decision.stumps <- function(x, y, split, ...) {

  aux <- sapply(split, function(test) {
    imp <- names(dt.importance(x, y, test))[1]
    model <- C50::C5.0(x[-test, imp, drop=FALSE], y[-test])
    prediction <- stats::predict(model, x[test,])
    accuracy(prediction, y[test])
  })

  return(aux)
}

worst.node <- function(x, y, split, ...) {

  aux <- sapply(split, function(test) {
    imp <- names(dt.importance(x, y, test))[ncol(x)]
    model <- C50::C5.0(x[-test, imp, drop=FALSE], y[-test])
    prediction <- stats::predict(model, x[test,])
    accuracy(prediction, y[test])
  })

  return(aux)
}

nearest.neighbor <- function(x, y, split, transform.attr=TRUE, ...) {

  x <- validate.and.replace.nominal.attr(x, transform.attr)
  aux <- sapply(split, function(test) {
    data <- data.frame(Class=y, x)
    prediction <- kknn::kknn(Class~., data[-test,], data[test,-1], k=1)
    accuracy(prediction$fitted.values, y[test])
  })

  return(aux)
}

elite.nearest.neighbor <- function(x, y, split, transform.attr=TRUE, ...) {

  x <- validate.and.replace.nominal.attr(x, transform.attr)
  aux <- sapply(split, function(test) {
    imp <- dt.importance(x, y, test)
    att <- names(which(imp != 0))
    if(all(imp == 0))
      att <- colnames(x)

    data <- data.frame(Class=y, x[, att, drop=FALSE])
    prediction <- kknn::kknn(Class ~ ., data[-test,],
                             data[test, att, drop=FALSE], k=1)
    accuracy(prediction$fitted.values, y[test])
  })

  return(aux)
}

naive.bayes <- function(x, y, split, ...) {

  aux <- sapply(split, function(test) {
    model <- e1071::naiveBayes(x[-test,], y[-test])
    prediction <- stats::predict(model, x[test,])
    accuracy(prediction, y[test])
  })

  return(aux)
}

linear.discriminant <- function(x, y, split, transform.attr=TRUE, ...) {

  x <- validate.and.replace.nominal.attr(x, transform.attr)
  aux <- sapply(split, function(test) {
    tryCatch({
      model <- MASS::lda(x[-test,], grouping=y[-test])
      prediction <- stats::predict(model, x[test,])$class
      accuracy(prediction, y[test])
    }, error = function(e) {
      return(0)
    })
  })

  return(aux)
}

