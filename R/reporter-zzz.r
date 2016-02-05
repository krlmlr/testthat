#' @include reporter-stop.r
NULL

#' Get/set reporter; execute code in specified reporter.
#'
#' Changes global reporter to that specified, runs code and the returns
#' global reporter back to previous value.
#'
#' @keywords internal
#' @param reporter test reporter to use
#' @param code code block to execute
#' @name reporter-accessors
NULL

testthat_env <- new.env()

# Default has to be the stop reporter, since it is this that will be run by
# default from the command line and in R CMD test.
testthat_env$reporter <- StopReporter$new()

#' @rdname reporter-accessors
#' @export
set_reporter <- function(reporter) {
  old <- testthat_env$reporter
  testthat_env$reporter <- reporter
  old
}

#' @rdname reporter-accessors
#' @export
get_reporter <- function() {
  testthat_env$reporter
}

#' @rdname reporter-accessors
#' @export
with_reporter <- function(reporter, code) {
  reporter <- find_reporter(reporter)

  old <- set_reporter(reporter)
  on.exit(set_reporter(old))

  reporter$start_reporter()
  force(code)
  reporter$end_reporter()

  invisible(reporter)
}

#' Find reporter object given name or object.
#'
#' If not found, will return informative error message.
#' Will return null if given NULL.
#'
#' @param reporter name of reporter
#' @keywords internal
#' @examples
#' find_reporter("minimal")
#' find_reporter("summary+fail")
find_reporter <- function(reporter) {
  if (is.null(reporter)) return(NULL)
  if (inherits(reporter, "Reporter")) return(reporter)
  if (reporter == "") {
    return(find_reporter_one(reporter))
  }

  reporter_names <- strsplit(reporter, " *[+] *")[[1L]]
  if (length(reporter_names) <= 1L) {
    find_reporter_one(reporter_names)
  } else {
    MultiReporter$new(reporters = lapply(reporter_names, find_reporter_one))
  }
}

find_reporter_one <- function(reporter) {
  name <- reporter
  substr(name, 1, 1) <- toupper(substr(name, 1, 1))
  name <- paste0(name, "Reporter")

  if (!exists(name)) {
    stop("Can not find test reporter ", reporter, call. = FALSE)
  }

  get(name)$new()
}
