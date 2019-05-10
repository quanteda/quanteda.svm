#' A sentence-level corpus of annotated or machine-readable UK party manifestos, 1945--2017
#' 
#' A text corpus of publicly available, machine-readable party manifestos from the 
#' United Kingdom, published between 1945 and 2017. 
#' Manifestos from the three main parties (Labour Party, Conservatives, Liberal Democrats) 
#' between 1987 and 2010 are crowd-sourced in terms of Economic Policy and Social Policy, 
#' and the direction of Economic Policy and Social Policy. All manifestos from the 2010 
#' General Election have been crowd coded in terms of immigration policy, 
#' and the direction of immigration policy. 
#' For more information on the coding approach see 
#' \href{https://doi.org/10.1017/S0003055416000058}{Benoit et al. (2016)}.  
#' The corpus contains the aggregated labels on the level of sentences.
#' Note that the segmentation into sentences does not always work correctly due to missing punctuation. 
#' The Examples below show to use \link[quanteda]{corpus_trim} for removing very short and 
#' very long sentences.
#' @format 
#'   The corpus consists of 68,947 documents (i.e. sentences). and includes the following 
#'   document-level variables: \describe{
#'   \item{party}{factor; abbreviation of the party that wrote the manifesto.}
#'   \item{partyname}{factor; party that wrote the manifesto.}
#'   \item{year}{4-digit year of the election.}
#'   \item{crowd_econsocial}{A factor variable indicating whether a majority of crowd workers 
#'   labeled a sentence as Economic Policy, Social Policy, or Neither. The variable has missing values 
#'   (NA) for all non-annotated manifestos.}
#'   \item{crowd_econsocial_dir}{A factor indicating the direction of a sentence if it was coded as 
#'   Economic Policy or Social Policy by a majority of crowd coders. 
#'   The variable has missing values (NA) for all non-annotated manifestos or if a sentence was coded as
#'   "Not Economic or Social".}
#'   \item{crowd_econsocial_mean}{The average evaluation used to construct "crowd_econsocial". 
#'   The variable has missing values (NA) for all non-annotated manifestos. This variable indicates 
#'   the (dis)agreement between crowd workers.}
#'   \item{crowd_econsocial_dir_mean}{The average evaluation used to construct 
#'   "crowd_econsocial_dir". The variable has missing values (NA) for all non-annotated manifestos or 
#'   if a sentence was coded as "Not Economic or Social". This variable indicates 
#'   the (dis)agreement between crowd workers.}
#'   \item{crowd_immigration}{A factor variable indicating whether the majority of crowd workers
#'   labeled a sentence as referring to immigration. The variable has missing values (NA) for all non-annotated manifestos.}
#'   \item{crowd_immigration_dir}{A factor indicating the direction of a sentence 
#'   (Against, Neutral, Supportive) if it was coded as referring to immigration. 
#'   The variable has missing values (NA) for all non-annotated manifestos or if a sentence was coded not 
#'   coded as referring to immigration policy.}
#'   \item{crowd_immigration_dir}{A numeric variable, ranging between 0 and 1. 
#'   0 implies that none of the crowd coders labeled the sentence as referring to immigration;
#'   1 implies that all crowd coders labeled the sentence as referring to immigration. 
#'   The variable has missing values (NA) for all non-annotated manifestos or if a sentence was
#'   not coded as referring to immigration policy.}
#'   \item{crowd_immigration_dir_mean}{A numeric variable, ranging between -1 and 1; a value of 
#'   - 1 indicates that all crowd coders labeled the sentence as "Supportive" of immigration, 
#'   a value of 1 means that all coders labeled the sentences as "Against" immigration. 
#'   This variable indicates the (dis)agreement between crowd workers.}
#'   }
#' @examples 
#' \donttest{
#' # remove very short and very long sentences
#' corp_trimmed <- data_corpus_manifestosentsUK %>% 
#'     quanteda::corpus_trim(min_ntoken = 1, max_ntoken = 80)
#' 
#' # keep only crowd coded manifestos (with respect to economic and social policy)
#' corp_crowdeconsocial <- data_corpus_manifestosentsUK %>% 
#'     corpus_subset(!is.na(crowd_econsocial))
#' 
#' # keep only crowd coded manifestos (with respect to immigration policy)
#' corp_crowdimmig <- data_corpus_manifestosentsUK %>% 
#'     corpus_subset(!is.na(crowd_immigration))
#' }
#' @references Benoit, K., Conway, D., Lauderdale, B.E., Laver, M., & Mikhaylov, S. (2016). 
#' "\href{https://doi.org/10.1017/S0003055416000058}{Crowd-sourced Text Analysis: 
#'   Reproducible and Agile Production of Political Data}." 
#'   \emph{American Political Science Review} 100(2): 278--295.
#' @format
#'  A \link[quanteda]{corpus} object.
#' @keywords data
"data_corpus_manifestosentsUK"