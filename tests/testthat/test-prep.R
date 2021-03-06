# Testing the prepareCellData machinery.
# require(testthat); require(cydar); source("test-prep.R")

set.seed(90001)
test_that("prepareCellData works as expected", {
    # Setup.
    nmarkers <- 10
    ncells1 <- 1001
    all.values1 <- matrix(rnorm(ncells1*nmarkers, sd=1), nrow=ncells1, ncol=nmarkers)
    colnames(all.values1) <- paste0("X", seq_len(nmarkers))
    ncells2 <- 2001
    all.values2 <- matrix(rnorm(ncells2*nmarkers, sd=1), nrow=ncells2, ncol=nmarkers)
    colnames(all.values2) <- colnames(all.values1)

    # Initial checks.
    out <- prepareCellData(list(X=all.values1, Y=all.values2))
    expect_identical(nrow(out), 0L)
    expect_identical(ncol(out), 2L)
    expect_identical(assayNames(out), NULL)
    expect_identical(colnames(out), c("X", "Y"))
    expect_identical(markernames(out), colnames(all.values1))

    # Checking that the cells are correctly ordered.
    sid <- rep(1:2, c(ncells1, ncells2))
    cid <- c(seq_len(ncells1), seq_len(ncells2))
    pre <- int_metadata(out)$cydar$precomputed
    expect_identical(sid[pre$order], int_metadata(out)$cydar$sample.id)
    expect_identical(cid[pre$order], unname(int_metadata(out)$cydar$cell.id))

    # Checking that the intensities are correctly reordered.
    current <- paste0(int_metadata(out)$cydar$sample.id, ".", int_metadata(out)$cydar$cell.id)
    original <- paste0(sid, ".", cid)
    m <- match(original, current)
    expect_equivalent(rbind(all.values1, all.values2), t(pre$data)[m,])
    expect_identical(dim(int_metadata(out)$cydar$unused), c(0L, as.integer(ncells1+ncells2)))
})

set.seed(90001)
test_that("prepareCellData works with subsetted markers", {
    # Setup.
    nmarkers <- 10
    ncells1 <- 1001
    all.values1 <- matrix(rnorm(ncells1*nmarkers, sd=1), nrow=ncells1, ncol=nmarkers)
    colnames(all.values1) <- paste0("X", seq_len(nmarkers))
    ncells2 <- 2001
    all.values2 <- matrix(rnorm(ncells2*nmarkers, sd=1), nrow=ncells2, ncol=nmarkers)
    colnames(all.values2) <- colnames(all.values1)

    # Initial check.
    spec <- c(2,3,4)
    set.seed(100)
    out.sub <- prepareCellData(list(X=all.values1, Y=all.values2), markers=spec)
    set.seed(100)
    out.ref <- prepareCellData(list(X=all.values1[,spec], Y=all.values2[,spec]))

    tmp.sub <- int_metadata(out.sub)$cydar
    tmp.ref <- int_metadata(out.ref)$cydar
    expect_identical(tmp.sub$markers$used, tmp.ref$markers$used)
    tmp.sub$unused <- NULL
    tmp.ref$unused <- NULL
    tmp.sub$markers <- NULL
    tmp.ref$markers <- NULL
    expect_equal(tmp.sub, tmp.ref)

    # Ensuring that the unused fields are valid.
    expect_identical(int_metadata(out.sub)$cydar$unused, 
        t(rbind(all.values1, all.values2)[tmp.sub$precomputed$order,-spec,drop=FALSE]))

    # Checking that we can subset by name as well.
    spec <- c("X2","X3","X4")
    set.seed(100)
    out.sub2 <- prepareCellData(list(X=all.values1, Y=all.values2), markers=spec)
    expect_equal(out.sub, out.sub2)
})

test_that("prepareCellData behaves with ncdfFlowSet inputs", {
    library(ncdfFlow)
    data(GvHD)
    fs <- GvHD[1:2]
    ncfs <- ncdfFlowSet(fs)

    out <- prepareCellData(ncfs)
    expect_identical(markernames(out), colnames(ncfs))
    expect_identical(colnames(out), sampleNames(ncfs))

    # Checking that the cells are correctly ordered.
    ncells1 <- nrow(fs[[1]])
    ncells2 <- nrow(fs[[2]])
    sid <- rep(1:2, c(ncells1, ncells2))
    cid <- c(seq_len(ncells1), seq_len(ncells2))
    pre <- int_metadata(out)$cydar$precomputed
    expect_identical(sid[pre$order], int_metadata(out)$cydar$sample.id)
    expect_identical(cid[pre$order], unname(int_metadata(out)$cydar$cell.id))
})

set.seed(90002)
test_that("prepareCellData behaves with silly inputs", {
    # Setup.
    nmarkers <- 10
    ncells1 <- 1001
    all.values1 <- matrix(rnorm(ncells1*nmarkers, sd=1), nrow=ncells1, ncol=nmarkers)
    colnames(all.values1) <- paste0("X", seq_len(nmarkers))
    
    ncells2 <- 2001
    all.values2 <- matrix(rnorm(ncells2*nmarkers, sd=1), nrow=ncells2, ncol=nmarkers)
    colnames(all.values2) <- colnames(all.values1)

    # No cells, no problems.
    expect_error(out <- prepareCellData(list(X=all.values1[0,], Y=all.values2[0,])), NA)

    # Handles missing column names.        
    out <- prepareCellData(list(all.values1, all.values2))
    expect_identical(colnames(out), as.character(1:2))

    # Throws upon no samples.
    expect_error(out <- prepareCellData(list()), "must be positive")

    # Throws when one matrix has mismatching markers.
    tmp <- all.values2
    colnames(tmp) <- sample(colnames(tmp))
    expect_error(prepareCellData(list(all.values1, tmp)), "not TRUE")
})
