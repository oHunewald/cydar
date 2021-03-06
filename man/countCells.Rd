\name{countCells}
\alias{countCells}

\title{Count cells in high-dimensional space}

\description{
Count the number of cells from each sample lying inside hyperspheres in high-dimensional space.
}

\usage{
countCells(x, tol=0.5, BPPARAM=SerialParam(), downsample=10, filter=10)
}

\arguments{
\item{x}{A CyData object produced by \code{\link{prepareCellData}}.}
\item{tol}{A numeric scalar proportional to the hypersphere radius.}
\item{BPPARAM}{A BiocParallelParam object specifying how parallelization is to be performed in \code{\link{findNeighbors}}.}
\item{downsample}{An integer scalar specifying the frequency with which cells are sampled to form hyperspheres.}
\item{filter}{An integer scalar specifying the minimum count sum required to report a hypersphere.} 
}

\details{
Consider that each cell defines a point in M-dimensional space (where M is the number of markers), based on its marker intensities.
This function constructs hyperspheres and counts the number of cells from each sample lying within each hypersphere.
In this manner, the distribution of cells across the space can be quantified.
For each hypersphere, cell counts for all samples are reported along with the median intensity across the counted cells for each marker.

Each hypersphere is centered on a cell to ensure that only occupied spaces are counted.
However, for high-density spaces, this can result in many redundant hyperspheres.
To reduce computational work, only a subset of cells are used to define hyperspheres.
The downsampling frequency is specified by \code{downsample}, e.g., only every 10th cell is used to make a hypersphere by default.

Each hypersphere also has a radius of \code{tol*sqrt(M)} (this relationship avoids loss of counts as M increases).
\code{tol} can be interpreted as the acceptable amount of deviation in the intensity of a single marker for a given subpopulation.
The default value of 0.5 means that, for any one marker, cells with +0.5 or -0.5 intensity will be counted into the same subpopulation.
This value is sensible as intensities are usually on a log-10 scale, such that a total of 10-fold variability in marker intensities is tolerated.

The coordinates are reported as (weighted) medians across all cells in each hypersphere.
Compared to the center, the median better reflects the location of the hypersphere if the cells are not distributed around the centre.
Each cell is weighted inversely proportional to the total number of cells in the corresponding sample.
This ensures that large samples do not dominate the median calculation.

All hyperspheres with count sums below \code{filter} are removed by default.
Such hyperspheres do not have enough counts (and thus, information) for downstream analyses.
Removing them reduces the amount of memory required to form the output matrix.
}

\value{
A CyData object containing the following information:
\describe{
\item{\code{counts}}{An integer matrix of counts for each hypersphere (row) and sample (column) in the \code{assays} slot.}
\item{\code{intensities}:}{A numeric matrix of median intensities for each hypersphere (row) and marker (column), stored in the \code{"cydar"} DataFrame in the \code{rowData} slot.}
\item{\code{cellAssignments}:}{A list of integer vectors specifying the cells contained within each hypersphere, stored in the \code{"cydar"} DataFrame in the \code{rowData}.}
\item{\code{totals}:}{An integer vector specifying the total number of cells in each sample, stored as a field in the \code{colData}.}
\item{\code{center.cell}:}{An integer vector specifying the cell that is used as the centre of each hypersphere, stored in the \code{"cydar"} DataFrame in the \code{rowData}.}
\item{\code{tol}:}{An integer scalar equal to \code{tol}, stored in the \code{"cydar"} list in the \code{metadata} slot.}
}

Any existing \code{rowData} and \code{assays} are discarded.
All other slots are left unchanged from the values supplied in \code{x}.
}

\author{
Aaron Lun
}

\references{
Lun ATL, Richard AC, Marioni JC (2017). 
Testing for differential abundance in mass cytometry data. 
\emph{Nat. Methods}, 14, 7:707-709.

Samusik N, Good Z, Spitzer MH et al. (2016).
Automated mapping of phenotype space with single-cell data.
\emph{Nat. Methods} 13:493-496
}

\seealso{
\code{\link{prepareCellData}}
}
\examples{
example(prepareCellData, echo=FALSE)
downsample <- 10L
tol <- 0.5

cnt <- countCells(cd, filter=1, downsample=downsample, tol=tol)
cnt
}
