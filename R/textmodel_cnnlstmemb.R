#' sequential neural network model for text classification
#'
#' Explain
#' @param x tokens object
#' @inheritParams textmodel_svm
#' @param units The number of network nodes used in the first layer of the
#'   sequential model
#' @param dropout1 A floating variable bound between 0 and 1. It determines the
#'   rate at which units are dropped for the linear transformation of the
#'   inputs for the embedding layer.
#' @param dropout2 A floating variable bound between 0 and 1. It determines the
#'   rate at which units are dropped for the linear transformation of the
#'   inputs for the LSTM layer.
#' @param dropout3 A floating variable bound between 0 and 1. It determines the
#'   rate at which units are dropped for the linear transformation of the
#'   inputs for the recurrent layer.
#' @param wordembeddim The number of word embedding dimensions to be fit
#' @param filter The number of output filters in the convolution
#' @param kernel_size An integer or list of a single integer, specifying the length of the 1D convolution window
#' @param pool_size Size of the max pooling windows.
#'   \code{\link[keras]{layer_max_pooling_1d}}
#' @param units_lstm The number of nodes of the lstm layer
#' @param words The maximum number of words used to train model. Defaults to the number of features in \code{x}
#' @param maxsenlen The maximum sentence length of training data 
#' @param optimizer optimizer used to fit model to training data, see
#'   \code{\link[keras]{compile.keras.engine.training.Model}}
#' @param loss objective loss function, see
#'   \code{\link[keras]{compile.keras.engine.training.Model}}
#' @param metrics metric used to train algorithm, see
#'   \code{\link[keras]{compile.keras.engine.training.Model}}
#' @param ... additional options passed to
#'   \code{\link[keras]{fit.keras.engine.training.Model}}
#' @keywords textmodel
#' @importFrom keras keras_model_sequential to_categorical
#' @importFrom keras layer_dense layer_activation layer_dropout compile fit
#' @importFrom keras layer_embedding layer_conv_1d layer_max_pooling_1d layer_lstm
#' @export
#' @examples 
#' \dontrun{
#' # create a dataset with evenly balanced coded and uncoded immigration sentences
#' corpcoded <- corpus_subset(data_corpus_manifestosentsUK, !is.na(crowd_immigration_label))
#' corpuncoded <- data_corpus_manifestosentsUK %>%
#'     corpus_subset(is.na(crowd_immigration_label) & year > 1980) %>%
#'     corpus_sample(size = ndoc(corpcoded))
#' corp <- corpcoded + corpuncoded
#' 
#' # form a tokens object
#' corptok <- tokens(texts(corp))
#' 
#' set.seed(1000)
#' tmod <- textmodel_cnnlstmemb(corptok, y = docvars(dfmat, "crowd_immigration_label"),
#'                         epochs = 5, verbose = 1)
#' pred <- predict(tmod, newdata = dfm_subset(dfmat, is.na(crowd_immigration_label)))
#' table(pred)
#' tail(texts(corpuncoded)[pred == "Immigration"], 10)
#' }
textmodel_cnnlstmemb <- function(x, y, units = 512, dropout1 = .2, dropout2 = .2, dropout3 = .2, 
                                 wordembeddim = 30, filter = 48, kernel_size = 5, pool_size = 4,
                                 units_lstm = 128, words = NULL, maxsenlen = 50,
                                 optimizer = "adam",
                                 loss = "categorical_crossentropy", 
                                 metrics = "categorical_accuracy", ...) {
    UseMethod("textmodel_cnnlstmemb")
}

#' @export
textmodel_cnnlstmemb.tokens <- function(x, y, units = 512, dropout1 = .2, dropout2 = .2, dropout3 = .2, 
                                     wordembeddim = 30, filter = 48, kernel_size = 5, pool_size = 4,
                                     units_lstm = 128, words = NULL, maxsenlen = 50, 
                                optimizer = "adam",
                                loss = "categorical_crossentropy", 
                                metrics = "categorical_accuracy", ...) {
    stopifnot(ndoc(x) == length(y))
    
    y <- as.factor(y)
    result <- list(x = x, y = y, call = match.call(), classnames = levels(y))

    # trim missings for fitting model
    na_ind <- which(is.na(y))
    if (length(na_ind) > 0) {
        # message(length(na_ind), "observations with the value 'NA' were removed.")
        y <- y[-na_ind]
        x <- x[-na_ind]
    }

    x <- tokens2sequences(x, maxsenlen = maxsenlen, keepn = words)
    
    if (is.null(words)) {words = x$nfeatures}    
    # "one-hot" encode y
    y2 <- to_categorical(as.integer(y) - 1, num_classes = nlevels(y))
    
    # use keras to fit the model
    model <- keras_model_sequential()
    model %>%
        layer_embedding(input_dim = words + 1, output_dim = wordembeddim, input_length = dim(x)[2]) %>%
        layer_dropout(rate = dropout1) %>% 
        layer_conv_1d(filters = filter, kernel_size = kernel_size, activation='relu') %>% 
        layer_max_pooling_1d(pool_size = pool_size) %>% 
        layer_lstm(units = units_lstm, dropout = dropout2, recurrent_dropout = dropout3) %>% 
        layer_dense(units = nlevels(y), activation = 'softmax')
    compile(model, loss = loss, optimizer = optimizer, metrics = metrics)
    history <- fit(model, x$matrix, y2, ...)
    
    # compile, class, and return the result
    result <- c(result, nfeatures = x$nfeatures, maxsenlen = maxsenlen, list(clefitted = model))
    class(result) <- c("textmodel_cnnlstmemb", "textmodel", "list")
    return(result)
}

#' Prediction from a fitted textmodel_cnnlstmemb object
#'
#' \code{predict.textmodel_cnnlstmemb()} implements class predictions from a fitted
#' sequential neural network model.
#' @param object a fitted \link{textmodel_cnnlstmemb} model
#' @param newdata dfm on which prediction should be made
#' @param type the type of predicted values to be returned; see Value
#' @param force make \code{newdata}'s feature set conformant to the model terms
#' @param ... not used
#' @return \code{predict.textmodel_cnnlstmemb} returns either a vector of class
#'   predictions for each row of \code{newdata} (when \code{type = "class"}), or
#'   a document-by-class matrix of class probabilities (when \code{type =
#'   "probability"}).
#' @seealso \code{\link{textmodel_cnnlstmemb}}
#' @keywords textmodel internal
#' @importFrom keras predict_classes predict_proba
#' @export
predict.textmodel_cnnlstmemb <- function(object, newdata = NULL,
                                  type = c("class", "probability"),
                                  force = TRUE,
                                  ...) {
    quanteda:::unused_dots(...)
    
    type <- match.arg(type)
    
    if (!is.null(newdata)) {
        data <- tokens2sequences(newdata, maxsenlen = object$maxsenlen, keepn = object$nfeatures)
        t2s_object <- tokens2sequences(object$x, maxsenlen = object$maxsenlen, keepn = object$nfeatures)
        data <- t2s_conform(data, t2s_object)
    } else {
        data <- tokens2sequences(object$x, maxsenlen = object$maxsenlen, keepn = object$nfeatures)
    }
    
    if (type == "class") {
        pred_y <- predict_classes(object$clefitted, x = data$matrix)
        pred_y <- factor(pred_y, labels = object$classnames, levels = (seq_along(object$classnames) - 1))
        names(pred_y) <- rownames(data$matrix)
    } else if (type == "probability") {
        pred_y <- predict_proba(object$clefitted, x = data$matrix)
        colnames(pred_y) <- object$classnames
        rownames(pred_y) <- rownames(data$matrix)
    }
    
    pred_y
}

#' @export
#' @method print textmodel_cnnlstmemb
print.textmodel_cnnlstmemb <- function(x, ...) {
    layer_names <- gsub(pattern = "_\\d*", "", lapply(x$clefitted$layers, function(z) z$name))
    cat("\nCall:\n")
    print(x$call)
    cat("\n",
        format(length(na.omit(x$y)), big.mark = ","), " training documents; ",
        format(length(x$weights), big.mark = ","), " fitted features",
        ".\n",
        "Structure: ", paste(layer_names, collapse = " -> "), "\n",
        sep = "")
}

#' summary method for textmodel_cnnlstmemb objects
#' @param object output from \code{\link{textmodel_cnnlstmemb}}
#' @param ... additional arguments not used
#' @keywords textmodel internal
#' @method summary textmodel_cnnlstmemb
#' @export
summary.textmodel_cnnlstmemb <- function(object, ...) {
    layer_names <- gsub(pattern = "_\\d*", "", lapply(object$clefitted$layers, function(x) x$name))
    
    result <- list(
        "call" = object$call,
        "model structure" = paste(layer_names, collapse = " -> ")
    )
    as.summary.textmodel(result)
}

#' @export
#' @method print predict.textmodel_cnnlstmemb
print.predict.textmodel_cnnlstmemb <- function(x, ...) {
    print(unclass(x))
}