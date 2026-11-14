library(tidyverse, warn.conflicts = FALSE)
library(dplyr)
library(readr)

eng_sl <- read_csv("energy_timeSeries_forecast/Energy_consump_SL.csv", skip = 1, show_col_types = TRUE)
View(eng_sl)

col_name <- colnames(eng_sl) |> print()
col_name <- as.data.frame(col_name)
col_name <- col_name |> slice(-1,-2) #delete first two rows
col_name <- col_name[, !(names(col_name) %in% c("V1", "V2"))] # let's delete the first two columns
col_name <- rowid_to_column(col_name, var = "index")#add an index column

#let's convert eng_sl to dataframe
eng_sl <- as.data.frame(eng_sl)

eng_sl <- eng_sl[, !(names(eng_sl) %in% c("API", "...2"))] #delete those two columns
eng_sl <- eng_sl |> slice(-1)
eng_sl <- t(eng_sl)
eng_sl <- as.data.frame(eng_sl)
eng_sl <- eng_sl |> rowid_to_column(var = "index") #add an index column
eng_sl <- eng_sl |> rename(sl_eng_cons = V1) #rename the column V1 to energycons


rm("col_name", "eng_sl")

````````````````````````````````````````````````````````````````````````````````


en_lib <- read_csv("energy_timeSeries_forecast\\Energy_consump_LIB.csv", skip = 1, show_col_types = TRUE)

en_lib <- as.data.frame(en_lib)

en_lib <- en_lib[, !(names(en_lib) %in% c("API", "...2"))]
en_lib <- en_lib |> slice(-1)
en_lib <- t(en_lib)
en_lib <- as.data.frame(en_lib)
en_lib <- en_lib |> rowid_to_column(var = "index")
en_lib <- en_lib |> rename(lib_eng_cons = V1)


````````````````````````````````````````````````````````````````````````````````
en_gui <- read_csv("energy_timeSeries_forecast\\Energy_consump_GUI.csv", skip = 1, show_col_types = TRUE)

en_gui <- as.data.frame(en_gui)
en_gui <- en_gui[, !(names(en_gui) %in% c("API", "...2"))] #delete the two columns
en_gui <- en_gui |> slice(-1)
en_gui <- t(en_gui)
en_gui <- as.data.frame(en_gui)
en_gui <- slice(-1,-2)
en_gui <- en_gui |> rename(gui_eng_cons = V1)
en_gui <- en_gui |> rowid_to_column(var = "index")

en_sl <- eng_sl
rm(eng_sl)
````````````````````````````````````````````````````````````````````````````````

# now let's group them all and see

group_df <- col_name |> 
  full_join(en_sl, by = "index") |> 
  full_join(en_lib, by = "index") |> 
  full_join(en_gui, by = "index")

energy_df <- group_df |> rename(year = col_name)
rm(group_df)


library(tsibble, warn.conflicts = FALSE) #let's add the tsibble library
library(feasts, warn.conflicts = FALSE)
library(mixtime, warn.conflicts = FALSE)
library(ggtime, warn.conflicts = FALSE)

rm("col_name", "en_gui", "en_lib", "en_sl")

energy_df <- energy_df[, !(names(energy_df) %in% c("index"))]

testt <- t(energy_df) |> 
  as.data.frame(testt) |> View()

#let's reshape or data i.e pivot on pivot longer since we will have longer rows and reduced columns
df_long <- energy_df |> 
  pivot_longer(
    cols = c(sl_eng_cons, lib_eng_cons, gui_eng_cons), #columns to pivot
    names_to = "country", #the new column of the previous pivoted column names
    values_to = "energy_consumption" # the new column name of the new column for all the values under each pivoted colmn
  ) |> 
  mutate(country = case_when( #now we replace the old column names that are now observations
    country == "sl_eng_cons" ~ "Sierra Leone", # replace with Sierra Leone under country column only when this code is tru
    country == "lib_eng_cons" ~ "Liberia", # replace with Liberia under country column only when this code is tru
    country == "gui_eng_cons" ~ "Guinea" # replace with Guinea under country column only when this code is tru
  ))

rm("testt", "energy_df") #we clean our storage variables

energy_data <- df_long
rm(df_long)

tibble_ds <- energy_data |> 
  mutate(year = yearquarter(year)) |> 
  as_tsibble(index = year, key = c(country))

tib <- energy_data |> as_tsibble(key = "country", index = year)
View(tib)

rm(tibble_ds)

#let's create a time series for sierra leone only
tib |> 
  filter(country == "Sierra Leone" | country == "Liberia" | country == "Guinea") |> 
  filter(year >= 1980 & year <= 1990) |> 
  autoplot(energy_consumption) |> aes(color = "red")

tib |> 
  filter(country == "Sierra Leone") |> summarise(engc = sum(energy_consumption)) |> 
  gg_season() |> View()
tourism |> View()


energy_data <- energy_data |> 
  mutate(year = as.integer(year)) # we change year column datatype from str to int

tib |> 
  filter(country == "Sierra Leone") |> 
  autoplot(energy_consumption) +
  labs(title = "Sierra Leone Energy Consumption Time Series")

library(ggplot2)

ggplot(tib, aes(x = year, y = energy_consumption, color = country, group = country)) +
  geom_line(linewidth = 1) +
  # geom_point(size = 1) +
  # scale_x_continuous(breaks = seq(1980, 1985, by = 5)) +
  
  # 1. Custom colors for each trend line
  scale_color_manual(values = c(
    "Sierra Leone" = "dodgerblue", 
    "Liberia" = "forestgreen", 
    "Guinea" = "firebrick"
  )) +
  
  labs(
    title = "Energy Consumption by Country",
    subtitle = "Annual data from 1980 to 2024",
    x = "Year",
    y = "Energy Consumption",
    color = "Country"
  ) +
  theme_minimal() +
  
  # 2. Center the title (hjust = 0.5 centers it, face = "bold" makes it bold)
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
    plot.subtitle = element_text(hjust = 0.5) # Optional: center subtitle too
  )


