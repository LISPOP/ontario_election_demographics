source(here::here("R_Scripts/2_get_northern_demographics_cpsr.R"))
#on_da_tongfen %>% view()
#This gets the federal electoral district metadata
fed_on_meta<-get_statcan_wds_metadata("2021", level="FED", version="1.3")
#This filters out the metadata for federal electoral districts
fed_on_meta %>% 
  filter(str_detect(`Codelist ID`, "CL_GEO_FED"))->fed_on


#We need to find the Ontario federal electoral districts
#This takes the 10th an 11th digits of the DGUID 
# and puts it into a variable called PRUID
fed_on$PRUID<-str_sub(fed_on$ID, 10, 11)
#35 is the provincial code for ONtario
fed_on %>% 
  filter(PRUID==35)->fed_on
#Now find the FED codes
#They are the last 5 didigts of the DGUID
fed_on$FED<-str_sub(fed_on$ID, -5)
names(on)
head(on)
#### Anchor on the ONTARIO provincial ridings ####
#This project is about Ontario elections, so the Ontario provincial riding is the key throughout.
#We want the federal electoral districts that correspond to the NON-northern provincial ridings.
#
#The provincial ridings adopted the 2015 (2013 Representation Order) federal boundaries, so each
#non-northern provincial riding has a federal district with the SAME name. We therefore build a
#name-based crosswalk from the provincial riding to its federal DGUID, and carry the provincial
#ED_ID (Elections Ontario's ElectoralDistrictNumber) and name through to the demographics.
#
#This replaces the previous approach, which derived ED_ID from the federal riding NUMBER
#(last 3 digits of FED). Federal and provincial ridings are both numbered alphabetically but over
#different sets (121 federal vs 124 provincial), so the numbering drifts apart - e.g. Guelph is
#provincial 33 but federal 35032 - and the old code silently attached each riding's demographics
#to the wrong provincial riding.

#Normalize names for matching: em/en dashes -> "--", collapse whitespace, upper case.
norm_name <- function(x) str_trim(toupper(str_replace_all(str_replace_all(x, "—|–", "--"), "\\s+", " ")))

#Non-northern provincial ridings, straight from the Elections Ontario shapefile (`ontario`,
#built in 1_data_import.R; northern flag set from the named northern-riding list).
prov_non_northern <- ontario %>%
  st_drop_geometry() %>%
  filter(northern == 0) %>%
  distinct(ED_ID, ENGLISH_NA) %>%
  mutate(name_key = norm_name(ENGLISH_NA))

fed_on <- fed_on %>% mutate(name_key = norm_name(en))

#Crosswalk: one row per non-northern provincial riding, carrying the matched federal DGUID (`ID`).
#Federal northern ridings simply never match a non-northern provincial name, so they drop out here.
non_northern_dguid <- prov_non_northern %>%
  left_join(select(fed_on, name_key, ID, FED), by = "name_key")

#Fail loudly rather than silently mis-merge if any provincial riding has no federal name match.
.unmatched <- filter(non_northern_dguid, is.na(ID))
if (nrow(.unmatched) > 0) {
  stop("Non-northern provincial ridings with no federal name match:\n  ",
       paste(.unmatched$ENGLISH_NA, collapse = "\n  "))
}
non_northern_dguid$ID
#Look for income
fed_on_meta %>% 
  filter(`Codelist en`=="Characteristic") %>% 
  filter(str_detect(en, "French"))
fed_on_meta %>% 
  filter(`Codelist en`=="Characteristic") %>% 
  filter(str_detect(en, "income")) 

fed_on_meta %>% 
  filter(`Codelist en`=="Characteristic") %>% 
  filter(str_detect(en, "visible")) 

#Get Visible Minority
visible<-get_statcan_wds_data(DGUIDs=non_northern_dguid$ID, members=1670, gender="Total", version="1.3")

#Unemployed
fed_on_meta %>% 
  filter(`Codelist en`=="Characteristic") %>% 
  filter(str_detect(en, "Unempl"))
unemployed<-get_statcan_wds_data(DGUIDs=non_northern_dguid$ID, members=2226, gender="Total", version="1.3")
# LFS Participation
fed_on_meta %>% 
  filter(`Codelist en`=="Characteristic") %>% 
  filter(str_detect(en, "in the labour force"))
not_labour_force<-get_statcan_wds_data(DGUIDs=non_northern_dguid$ID, members=2227, gender="Total", version="1.3")
# Density
density<-get_statcan_wds_data(DGUIDs=non_northern_dguid$ID, members=6, gender="Total", version="1.3")
#save(density, file=here("data/non_northern_density.rds"))
# gini
fed_on_meta %>% 
  filter(`Codelist en`=="Characteristic") %>% 
  filter(str_detect(en, "Gini"))
gini<-get_statcan_wds_data(DGUIDs=non_northern_dguid$ID, members=365, gender="Total", version="1.3")
gini
#Francophones
francophones<-get_statcan_wds_data(DGUIDs=non_northern_dguid$ID, members=371, gender="Total", version="1.3")
# Post-seconary
fed_on_meta %>% 
  filter(`Codelist en`=="Characteristic") %>% 
  filter(str_detect(en, "certificate")) %>% view()
post_secondary_certificate<-get_statcan_wds_data(DGUIDs=non_northern_dguid$ID, members=2017, gender="Total", version="1.3")
# Income
average_household_income<-get_statcan_wds_data(DGUIDs=non_northern_dguid$ID, members=238, gender="Total", version="1.3")
average_household_income %>% view()
#Average_age
average_age<-get_statcan_wds_data(DGUIDs=non_northern_dguid$ID, members=39, gender="Total", version="1.3")
#Population
population<-get_statcan_wds_data(DGUIDs=non_northern_dguid$ID, members=1, gender="Total", version="1.3")
fed_on_meta %>% 
  filter(`Codelist en`=="Characteristic") %>% 
  filter(str_detect(en, "30%"))
#Housing Costs
hh_30<-get_statcan_wds_data(DGUIDs=non_northern_dguid$ID, members=1453, gender="Total", version="1.3")

# non_northern_dguid$ID %>%
#   map(., function(x){
#    # Sys.sleep(2)
#     get_statcan_wds_data(DGUIDs=x, members=6, gender="Total", version="1.3", refresh=T)
#     }) %>%
#   list_rbind()->density
# 
# save(density, file=here("data/non_northern_density.rds"))
# non_northern_dguid$ID %>%
#   map(., function(x){
#    # Sys.sleep(2)
#     get_statcan_wds_data(DGUIDs=x, members=371, gender="Total", version="1.3")
#     }) %>%
#   list_rbind()->french
# 
# save(french, file=here("data/non_northern_francophones.rds"))

# non_northern_dguid$ID %>% 
#   map(., function(x){
#     # Sys.sleep(2)
#     get_statcan_wds_data(DGUIDs=x, members=2013, gender="Total", version="1.3")
#   }) %>% 
#   list_rbind()->phds
# save(phds, file=here("data/non_northern_phds.rds"))

# non_northern_dguid$ID %>% 
#   map(., function(x){
#     # Sys.sleep(2)
#     get_statcan_wds_data(DGUIDs=x, members=238, gender="Total", version="1.3")
#   }) %>% 
#   list_rbind()->average_total_hh_income_2020
# 
#save(average_total_hh_income_2020, file=here("data/non_northern_average_total_hh_income_2020.rds"))

# non_northern_dguid$ID %>% 
#   map(., function(x){
#     # Sys.sleep(2)
#     get_statcan_wds_data(DGUIDs=x, members=39, gender="Total", version="1.3")
#   }) %>% list_rbind()->average_age
# save(average_age, file=here("data/non_northern_average_age.rds"))
#This loads the non_northern
# load(here("data/non_northern_average_total_hh_income_2020.rds"))
# load(here("data/non_northern_phds.rds"))
# load(here("data/non_northern_francophones.rds"))
# load(here("data/non_northern_average_age.rds"))
visible %>% 
  bind_rows(gini, francophones, unemployed, not_labour_force, density, post_secondary_certificate, average_age, average_household_income, population, hh_30)->non_northern_data
# non_northern_data %>% 
#   mutate(Variable=case_when(
#     CHARACTERISTIC==1670~"Visible",
#     CHARACTERISTIC==39~"Average Age",
#     CHARACTERISTIC==371~"Francophones",
#     CHARACTERISTIC==238~"Average_HH_Income",
#     CHARACTERISTIC==35~"Gini",
#     CHARACTERISTIC==2227~"Not Labour Force",
#     CHARACTERISTIC==2226~"Unemployed",
#   ))->non_northern_data
# table(non_northern_data$CHARACTERISTIC_NAME)
# phds %>% 
#   bind_rows(., french, average_age, average_total_hh_income_2020)->non_northern_data
# 
# non_northern_data %>% 
#   mutate(Variable=case_when(
#     CHARACTERISTIC==2013~"phds",
#     CHARACTERISTIC==39~"age",
#     CHARACTERISTIC==371~"francophones",
#     CHARACTERISTIC==238~"income",
#     CHARACTERISTIC==238~"income"
#   ))->non_northern_data

non_northern_data %>%
  select(CHARACTERISTIC_NAME,Value=OBS_VALUE, DGUID=REF_AREA) %>%
  pivot_wider(., names_from=c("CHARACTERISTIC_NAME"), values_from=c("Value")) %>%
  mutate(FED=str_sub(DGUID, -5)) %>%
  rename(`Visible`=2, `Gini`=3, `Francophones`=4, `Unemployed`=5,`Not Labour Force`=6,`Density`=7, `Certificate`=8,`Age`=9, `Average Income`=10,Population=11)->non_northern_data

#Attach the PROVINCIAL ED_ID and riding name via the name-based crosswalk built above, joining on
#the federal DGUID (REF_AREA from the WDS pull == `ID` in the crosswalk). ED_ID is therefore
#Elections Ontario's ElectoralDistrictNumber - the key used to merge back onto the election
#results in 3_merge_northern_non_northern_cpsr.R - and Name is the provincial riding name, both
#carried from the Ontario shapefile rather than re-derived from the federal riding number.
non_northern_data %>%
  left_join(select(non_northern_dguid, ID, ED_ID, Name=ENGLISH_NA),
            by=c("DGUID"="ID"))->non_northern_data

#Combine with the northern demographics (built via the tongfen estimation in
#2_get_northern_demographics_cpsr.R) into a single province-wide demographics table keyed on ED_ID.
#`northern` is left out here - `on` already carries its own reliable northern flag from the
#named riding list in 1_data_import.R, so we don't want a second, differently-sourced copy.
on_da_tongfen %>%
  st_drop_geometry() %>%
  select(ED_ID, Name=ENGLISH_NA, Population=population_real,
         Visible=visible, Unemployed=unemployed, `Not Labour Force`=not_in_labour_force,
         Density=density, Gini=gini, Francophones=francophones,
         Certificate=post_secondary_certificate_diploma_degree,
         `Average Income`=average_household_income, Age=average_age,
         `Spending 30% or more of income on shelter costs`=hh_30) %>%
  bind_rows(non_northern_data)->on_demographics

