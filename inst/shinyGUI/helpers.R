# ==================================================================================================
# debarcoding tab summary table 
# --------------------------------------------------------------------------------------------------

summary_tbl <- function(x) {
    
    # better way to do this?
    ids <- rownames(x@bc_key)
    yields <- x@yields[cbind(1:nrow(x@bc_key), 
        match(x@sep_cutoffs, seq(0, 1, .01)))]
    tbl <- matrix(c(paste0("<b>", ids, "</b>"), 
        sapply(ids, function(k) sum(x@bc_ids == k)), 
        x@sep_cutoffs, round(yields, 4) * 100), ncol=4)
    colnames(tbl) <- c("IDs", "Counts", "Cutoffs", "Yields")
    cols <- colorRampPalette(RColorBrewer::brewer.pal(11, "RdYlGn")[-c(1, 11)])(100)
    if (nrow(x@bc_key) < 21) {
        dom <- "t"
    } else {
        dom <- "tp"
    }
    DT::datatable(tbl, 
                  class="stripe", selection="none", escape=FALSE,
                  extensions="FixedHeader",
                  options=list(scrollY=TRUE, ordering=FALSE, selection=FALSE, 
                               searching=FALSE, info=FALSE, pageLength=20, dom=dom)) %>% 
        DT::formatStyle("Yields", 
                        backgroundColor=DT::styleInterval(cuts=1:99, values=cols))
                            
}

# ==================================================================================================
# get medians from rectangular brush
# --------------------------------------------------------------------------------------------------

text_info <- function(ff, cf, brush, ch1, ch2) {
    if (is.null(brush)) {
        paste("Brush points to\ncheck medians.")
    } else {
        selected <- brushedPoints(
            df=data.frame(asinh(flowCore::exprs(ff)/cf)),
            brush=brush, 
            xvar=ch1,
            yvar=ch2)
        xmed <- sprintf("% .3f", median(sinh(selected[, ch1])*cf))
        ymed <- sprintf("% .3f", median(sinh(selected[, ch2])*cf))
        paste0(sprintf("%5s", ch1), ": ", xmed, "\n", 
               sprintf("%5s", ch2), ": ", ymed)
    }
}