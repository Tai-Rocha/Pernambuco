################################################################################
###                                                                          ###
###                TUTORIAL TO DOWNLOAD OCCURRENCES FROM GGBIF               ###
###                     USING A LIST OF KNOWN NAMES OF SPECIES               ###
###https://data-blog.gbif.org/post/downloading-long-species-lists-on-gbif/   ###
###                                                                          ###
###                Modified by Tainá Rocha                                   ### 
###                    4.1.0 R version                                       ###   
###                                                                          ###  
###                   22 Jun 2021                                            ###
###                                                                          ###
################################################################################

#install.packages("remotes")
#remotes::install_github("ropensci/taxize")
#if(!require(pacman)) install.packages("pacman")
#pacman::p_load(dplyr, purrr, readr, magrittr, rgbif)

#The important part here is to use rgbif::occ_download with pred_in and to fill in your gbif credentials.

library(dplyr)
library(purrr)
library(readr)
library(magrittr) # for %T>% pipe
library(rgbif) # for occ_download
library(taxize) # for get_gbifid_


# fill in your gbif.org credentials. You need to create an account at gbif if you don't have it.

user <- "tai_rocha_013" # your gbif.org username
pwd <- "_________" # your gbif.org password
email <- "taina013@gmail.com" # your email

#############################################################################

spps <- read_csv("./data/sp_list_version_jun_2021/sps_arbus_arbor_check.csv")

gbif_taxon_keys <-
  read.csv("./data/sp_list_version_jun_2021/sps_arbus_arbor_check.csv", sep = ',') |>  #For an file with a list of spp names
  pull(scientific.name)  |>  #Specify the column from the list
  taxize::get_gbifid_(method="backbone") |> # match names to the GBIF backbone to get taxonkeys
  imap(~ .x |> mutate(original_sciname = .y)) |> # add original name back into data.frame
  bind_rows() %T>% # combine all data.frames into one
  readr::write_tsv(path = "all_matches.tsv") |> # save as side effect for you to inspect if you want
  filter(matchtype == "EXACT" & status == "ACCEPTED") |> # get only accepted and matched names
  filter(kingdom == "Plantae") |> # remove anything that might have matched to a non-plant
  pull(usagekey) # get the gbif taxonkeys


log_print(gbif_taxon_keys)

# gbif_taxon_keys should be a long vector like this c(2977832,2977901,2977966,2977835,2977863)
# !!very important here to use pred_in!!


# use matched gbif_taxon_keys from above
spp_lista <- occ_download(
  pred_in("taxonKey", gbif_taxon_keys),
  pred_in("basisOfRecord", c('PRESERVED_SPECIMEN')),
  #pred("geometry","POLYGON((-43.86 -17.57, -43.88 -21.49, -39.79 -19.86, -39.46 -17.98, -43.86
  #     -17.57))"),
  #pred("country", "BR"),
  #pred("continent", "South America"),
  pred("hasCoordinate", TRUE),
  pred("hasGeospatialIssue", FALSE),
  pred_gte("year", 1950),
  format = "SIMPLE_CSV",
  user=user,pwd=pwd,email=email
)

log_print(spp_lista)

## Go two '2_csv_to shape.R' 
