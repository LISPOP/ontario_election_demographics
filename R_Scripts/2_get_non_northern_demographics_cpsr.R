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
#We want the federal ridings that are NOT among the 14 northern ridings.
#Filtering by fed_code here would be unreliable - fed_code comes from a name-matched join in
#1_data_import.R that is missing or wrong for several ridings (including some northern ones).
#Instead we derive each federal riding's Elections Ontario ED_ID directly (last 3 digits of FED,
#i.e. the "35" Ontario prefix stripped - see 2_get_northern_demographics_cpsr.R) and exclude the
#ED_IDs already covered by the northern shapefile data (`northern$ED_ID`).
fed_on %>%
  mutate(ED_ID=as.numeric(str_sub(FED, -3))) %>%
  filter(!ED_ID %in% northern$ED_ID)->non_northern_dguid
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

#Elections Ontario's ED_ID (and ElectoralDistrictNumber in the election results) is just the
#federal DGUID/FED code with the "35" (Ontario) province prefix stripped, since Ontario adopted
#the federal boundaries in the 2013 redistribution. Deriving it this way avoids relying on the
#name-matched `fed_code` join in 1_data_import.R, which is incomplete/unreliable for several ridings.
non_northern_data %>%
  mutate(ED_ID=as.numeric(str_sub(FED, -3)))->non_northern_data

#Bring in the riding name for the non-northern ridings. Joining by ED_ID (rather than fed_code)
#for the same reliability reason as above; fedcreate==2013 keeps this to the current boundaries,
#matching the scope of the ED_ID join used downstream in 3_merge_northern_non_northern_cpsr.R.
on %>%
  filter(fedcreate==2013) %>%
  distinct(ElectoralDistrictNumber, ElectoralDistrictName) ->on_names_2013

non_northern_data %>%
  left_join(on_names_2013, by=c("ED_ID"="ElectoralDistrictNumber")) %>%
  rename(Name=ElectoralDistrictName)->non_northern_data

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

