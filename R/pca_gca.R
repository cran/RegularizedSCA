#' PCA-GCA method for selecting the number of common and distinctive components.
#'
#' Use PCA-GCA method to identify the number of common and distinctive components.
#'
#' @param DATA A concatenated data matrix with the same number of rows.
#' @param Jk A vector containing number of variables  in the concatinated data matrix. Please see the example below.
#' @param cor_min The minimum correlation between two components. The default value is .7; thus, it means that if the correlation
#' between the two component is at least .7, then these two components are regarded as forming a single common component.
#' @param return_scores If TRUE, then the function will return the component scores for each block for further analysis.
#' @return It prints out the number of components of each block and the number of common components. It also returns the component scores for each block for further analysis, if \code{return_scores = TRUE}.
#' @examples
#' \dontrun{
#' DATA1 <- matrix(rnorm(50), nrow=5)
#' DATA2 <- matrix(rnorm(100), nrow=5)
#' DATA <- cbind(DATA1, DATA2)
#' R <- 5
#' Jk <- c(10, 20) 
#' pca_gca(DATA, Jk, cor_min = .8)
#' }
#' @references Tenenhaus, A., & Tenenhaus, M. (2011). Regularized generalized canonical correlation analysis. Psychometrika, 76(2), 257-284.
#' @references Smilde, A.K., Mage, I., Naes, T., Hankemeier, T., Lips, M.A., Kiers, H.A., Acar, E., & Bro, R. (2016). Common and distinct components in data fusion. arXiv preprint arXiv:1607.02328.
#' @note
#' Please be ware of the interactive input: The function first performs PCA on each data block and then displays the eigenvalues (and a scree plot).
#' Afterwards the function awaits the input from the user - it needs to know how many components need to be retained for that block.
#'@export
pca_gca <- function(DATA, Jk, cor_min, return_scores){
 
  if(missing(return_scores)==TRUE){
    return_scores <- FALSE
  }
  DATA <- data.matrix(DATA)
  if(missing(cor_min)){
    cor_min <- .7
  }

  num_block <- length(Jk)

  data_block <- list()
  svd_block <- list()
  num_componentBlock <- array() #number of components to be kept per block
  compScores_block <- list()
  compScores_columnlist <- list()

  L <- 1
  for (k in 1:num_block){

    U <- L + Jk[k] - 1
    data_block[[k]] <- DATA[, L:U]
    svdblock <- svd(data_block[[k]])
    cat(sprintf("\nThe eigenvalues of block \"%s\" are\n", k))
    print(svdblock$d)
    y <- readline("Show the scree plot for the eigenvalues. 1: YES; 0: NO.    ")
    if (y == 1){
      graphics::plot(as.vector(svdblock$d), type='b', ylab = "Eigenvalue", xlab = 'Component Number')
    } else if (y!=1 & y!=0){
      stop("Please enter 1 or 0!")
    }
    x <- readline("How many components to be kept for this block?    ")
    num_componentBlock[k] <- as.numeric(x)
    if(num_componentBlock[k]%%1!=0 | num_componentBlock[k]<=0){
      stop("The number of components to be kept must be a positibe integrers!")
    }
    svd_block[[k]] <- svd(data_block[[k]], num_componentBlock[k], num_componentBlock[k])
    compScores_block[[k]] <- svd_block[[k]]$u

    L <- U + 1

  }

  #----cononical correlation via rgcca

  canonical_cor <- RGCCA::rgcca(compScores_block, C=1-diag(length(compScores_block)), tau = rep(0, length(compScores_block)),
                                ncomp = rep(min(num_componentBlock), length(compScores_block)), verbose = FALSE)

  com_comp <- sum(sqrt(canonical_cor$AVE$AVE_inner) >= cor_min)

  cat("\nThe number of components in each block:  ", num_componentBlock)

  cat(sprintf("\nThere are in total %s common components in the concatenated data.\n", com_comp))

  if(return_scores==TRUE){
    return(compScores_block)
  }


}
