#### Background script
# This calls the scripts that
# import the ontario voting results, the ontario riding boundaries
# gets the non-northern demographics from statistics canada and estimates the demographics
# on the northern districts
source("R_Scripts/2_get_non_northern_demographics_cpsr.R")

#on_demographics is the combined northern + non-northern demographics table, keyed on ED_ID
#(built at the end of 2_get_non_northern_demographics_cpsr.R)

#ED_ID only lines up with Elections Ontario's ElectoralDistrictNumber for the 2013 redistribution
#(the 2018 and 2022 elections) - earlier elections used different Ontario-specific boundaries that
#don't align with the federal ridings, and the same ElectoralDistrictNumber can refer to a
#different riding under an earlier redistribution. So the join below is restricted to
#fedcreate==2013 rows; earlier rows are left without demographics rather than risk a false match.
#Note: this replaces the old merge key, `fed_code`, which was built from a name-matched join in
#1_data_import.R and is missing/wrong for several ridings (e.g. Algoma--Manitoulin, Kenora--Rainy
#River were NA; Renfrew--Nipissing--Pembroke resolved to the wrong federal code).


#Write out the demographics table on its own.
on_demographics %>%
  write.csv(file=here("data/ontario_demographics.csv"), row.names=FALSE)

#### Produce the final merged dataset: election results + demographics
#Restricted to the 2018, 2022 and 2025 provincial elections. on_demographics is keyed on the
#Ontario provincial ED_ID (= Elections Ontario's ElectoralDistrictNumber): the northern rows carry
#it from the shapefile, and the non-northern rows carry it via the name-based crosswalk in
#2_get_non_northern_demographics_cpsr.R. So this is a provincial-to-provincial join.
#`on` carries one row per candidate, so the merged table is candidate-level with the riding's
#demographics attached.
on %>%
  filter(Date %in% c(2018, 2022, 2025)) %>%
  left_join(on_demographics, by=c("ElectoralDistrictNumber"="ED_ID"))->on_voting_demographics_data

#Ontario-centric coverage check: every 2018/2022/2025 riding must pick up demographics. If any
#riding is missing, the merge key has drifted - stop rather than write a silently-wrong dataset.
.missing_demo <- on_voting_demographics_data %>%
  filter(is.na(Name)) %>%
  distinct(ElectoralDistrictNumber, ElectoralDistrictName)
if (nrow(.missing_demo) > 0) {
  stop("Ridings with no demographics after merge:\n  ",
       paste0(.missing_demo$ElectoralDistrictNumber, " ", .missing_demo$ElectoralDistrictName,
              collapse = "\n  "))
}

#Write out the merged voting + demographics dataset (the deliverable for this project).
write.csv(on_voting_demographics_data, file=here("data/ontario_election_demographics.csv"), row.names=FALSE)

