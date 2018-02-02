# ==============================================================================
# FlowSOM clustering and ConsensusClusterPlus metaclustering
# ------------------------------------------------------------------------------
#' @rdname cluster
#' @title FlowSOM clustering and ConsensusClusterPlus metaclustering
#' 
#' @description 
#' \code{CATALYST::cluster()} runs \code{\link{FlowSOM}} clustering into 100,
#' and \code{\link{ConsensusClusterPlus}} metaclustering into 2-20 clusters. 
#' In the returned \code{daFrame}, those antigens used for clustering will be 
#' labelled as 'type1', and the remainder of antigens as 'type2'. A binary 
#' indication of each marker's type can be viewed via \code{colData(daFrame)}. 
#' Differential analysis should be performed on type2 markers exclusively. 
#'
#' @param x a \code{\link{daFrame}}.
#' @param cols_to_use a character vector.
#' Specifies which antigens to use for clustering.
#' @param xdim,ydim numerical values specifying the grid size of the
#' self-orginizing map. The default 10x10 grid will yield 100 clusters. 
#' @param maxK numerical value. Specifies the maximum 
#' number of clusters to evaluate in the metaclustering.
#' 
#' @return a \code{ggplot} object.
#' 
#' @examples
#' data(PBMC_fs, PBMC_panel, PBMC_md)
#' re <- daFrame(PBMC_fs, PBMC_panel, PBMC_md)
#' 
#' # specify antigens to use for clustering
#' lineage <- c("CD3", "CD45", "CD4", "CD20", "CD33", 
#'     "CD123", "CD14", "IgM", "HLA_DR", "CD7")
#' (re <- cluster(re, cols_to_use=lineage))
#' 
#' # sanity check
#' all.equal(lineage, type1(re))
#' 
#' # get type2 markers for differential analysis
#' type2(re)
#' 
#' @author
#' Helena Lucia Crowell \email{crowellh@student.ethz.ch}
#' @references 
#' Nowicka M, Krieg C, Weber LM et al. 
#' CyTOF workflow: Differential discovery in 
#' high-throughput high-dimensional cytometry datasets.
#' \emph{F1000Research} 2017, 6:748 (doi: 10.12688/f1000research.11622.1)
#' 
#' @import ConsensusClusterPlus
#' @importFrom flowCore flowFrame
#' @importFrom FlowSOM BuildSOM ReadInput
# ==============================================================================

setMethod(f="cluster",
    signature=signature(x="daFrame"),
    definition=function(x, cols_to_use, xdim=10, ydim=10, maxK=20) {
        
        # replace dash with underscore
        cols_to_use <- gsub("-", "_", cols_to_use)
        
        # flowSOM clustering
        message("o running FlowSOM clustering...")
        fsom <- ReadInput(flowFrame(exprs(x)))
        som <- BuildSOM(fsom, colsToUse=cols_to_use, 
            silent=TRUE, xdim=xdim, ydim=ydim)
        codes <- som$map$codes
        cluster_ids <- som$map$mapping[, 1]
        
        # metaclustering
        message("o running ConsensusClusterPlus metaclustering...")
        pdf(NULL)
        mc <- suppressMessages(ConsensusClusterPlus(t(codes), 
            maxK=maxK, reps=100, distance="euclidean", plot="pdf"))
        dev.off()

        # get cluster codes
        k <- xdim * ydim
        cluster_codes <- data.frame(matrix(0, k, maxK, 
            dimnames=list(NULL, c(k, 2:maxK))), check.names=FALSE)
        for (i in seq_len(maxK)[-1])
            cluster_codes[, i] <- mc[[i]]$consensusClass
        cluster_codes[, 1] <- seq_len(k)
        
        col_data <- data.frame(row.names=colnames(exprs(x)),
            type1=as.numeric(colnames(exprs(x)) %in% cols_to_use))
        col_data$type2 <- as.numeric(!col_data$type1)

        rowData(x)$cluster_id <- cluster_ids
        colData(x)$type1 <- col_data$type1
        colData(x)$type2 <- col_data$type2
        metadata(x)$SOM_codes <- codes
        metadata(x)$cluster_codes <- cluster_codes
        return(x)
    }
)