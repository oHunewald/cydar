#' @export
#' @importFrom kmknn precluster
#' @importFrom methods as
#' @importFrom S4Vectors DataFrame
#' @importFrom SingleCellExperiment int_metadata SingleCellExperiment
prepareCellData <- function(x, markers=NULL, ...) 
# Converts it into a format more suitable for high-speed analysis.
# Also does k-means clustering to generate the necessary clusters.
#
# written by Aaron Lun
# created 14 August 2016
{
    cell.data <- .pull_out_data(x)
    sample.names <-  cell.data$samples
    marker.names <- cell.data$markers
    exprs.list <- cell.data$exprs

    exprs <- do.call(rbind, exprs.list)
    ncells.per.sample <- vapply(exprs.list, FUN=nrow, FUN.VALUE=0L)
    sample.id <- rep(seq_along(exprs.list), ncells.per.sample)
    cell.id <- unlist(lapply(exprs.list, FUN=function(exprs) seq_len(nrow(exprs)) ))

    # Picking markers to use.
    used <- .chosen_markers(markers, marker.names)
    reorg <- precluster(exprs[,used,drop=FALSE], ...)
  
    # Collating the output (constructing an SCE first to avoid CyData validity check).
    output <- SingleCellExperiment(colData=DataFrame(row.names=sample.names))
    int_metadata(output)$cydar <- list(
        precomputed=reorg,
        markers=list(used=marker.names[used], unused=marker.names[!used]),
        sample.id=sample.id[reorg$order],
        cell.id=cell.id[reorg$order],
        unused=t(exprs[reorg$order,!used,drop=FALSE])
    )

    output$totals <- ncells.per.sample
    as(output, "CyData")
}

#' @importFrom methods is
#' @importFrom Biobase sampleNames 
#' @importFrom BiocGenerics colnames
#' @importFrom flowCore exprs
.pull_out_data <- function(x)
# Pulling out data so we don't have to rely on ncdfFlowSet input.
{
    if (is.list(x)) { 
        sample.names <- names(x)
        if (is.null(sample.names)) { 
            sample.names <- seq_along(x)
        }

        if (!length(x)) {
            stop("number of samples must be positive")
        } 

        marker.names <- colnames(x[[1]])
        for (i in sample.names) {
            x[[i]] <- as.matrix(x[[i]])
            tmp <- colnames(x[[i]])
            if (is.null(tmp)) { stop("column names must be labelled with marker identities"); }
            stopifnot(identical(tmp, marker.names))
        }
        expr.val <- x

    } else if (is(x, "ncdfFlowSet")) {
        sample.names <- sampleNames(x)
        marker.names <- colnames(x)
        by.sample <- seq_along(sample.names)
        expr.val <- lapply(by.sample, FUN=function(i) flowCore::exprs(x[[i]]))
    } else {
        stop("'cell.data' must be a list or ncdfFlowSet object") 
    }
    return(list(samples=sample.names, markers=marker.names, exprs=expr.val))
}
