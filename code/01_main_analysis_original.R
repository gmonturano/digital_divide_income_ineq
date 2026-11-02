


################################################################################
########################### DIGITAL FUSCO ######################################





############# librerie ##############

library(sf)
library(ggplot2)
library(tmap)
#install.packages("tmap", repos="http://cran.rstudio.com/", dependencies=TRUE)
library(tmaptools)
library(leaflet)
library(dplyr)
library(tidyr)
library(LabRS)
library(tidyverse)
library(sf)
library("RColorBrewer")
library(dplyr)
library(summarytools)
library(writexl)
library(desc)
library(summarytools)
library(readxl)
library(patchwork)
library(viridis)
library(cowplot)
library("openxlsx")
library(data.table)
library(stringr)
library(gridExtra)
library(lubridate)
library(tidyverse)
library(readxl)
library(dplyr)
library(openxlsx)
library(writexl)
library(readr)
library(stringr)

library(plm)

library(tidyr)
library(dplyr)


library(plm)
library(tidyverse)
library(readxl)
library(dplyr)
library(openxlsx)
library(writexl)
library(jtools)




#1 main 






pdata <- readRDS("C:/Users/Utente/Dropbox/Digital_Fusco/Codice/pdata.rds")




names(pdata)




summary(pdata)


table(pdata$Target_100_Mbps_rurale_sup, pdata$Anno)
table(pdata$Target_100_Mbps_rurale_pop, pdata$Anno)



#log1p
pdata$PM10<-log1p(pdata$PM10)
pdata$Totale.Alberghi_pl <- log1p(pdata$Totale.Alberghi_pl)
pdata$Campeggi.e.Villaggi.turistici_pl <- log1p(pdata$Campeggi.e.Villaggi.turistici_pl)





########################### genero il Panel ####################################

Panel <- pdata.frame(pdata, index=c("Provincia", "Anno"))

################################################################################






################## Verifo se ci sono duplicati nel Panel #######################


# Check for duplicate id-time combinations
duplicates <- table(index(Panel), useNA = "ifany")

# Find the duplicates where the count is more than 1
duplicate_indices <- which(duplicates > 1)

# If you want to see the actual values of the duplicates
if (length(duplicate_indices) > 0) {
  print(duplicates[duplicate_indices])
} else {
  print("No duplicates found")
}

################################################################################










######################### genero il Metadataframe ##############################


Panel_names<-pdata

Panel_names<-data.frame(names(Panel_names))

setwd("C:/Users/Utente/Dropbox/Digital_Fusco")


# Esporta il database in Excel
#write_xlsx(Panel_names, "meta_Db_Variabili.xlsx")

metadata <- read_xlsx("meta_fusco.xlsx", sheet = 7)

################################################################################


setwd("C:/Users/Utente/Dropbox/Digital_Fusco/output")




################################################################################
############################### Regressione TOTALE  ############################
################################################################################



# Crea un nuovo workbook
wb <- createWorkbook()

# Crea un foglio per i risultati
addWorksheet(wb, sheetName = "Summary")

# Inizializza l'indice di colonna
col_index <- 1

# Trova tutte le colonne "Spec" nel dataframe metadata
spec_columns <- grep("^Spec", colnames(metadata), value = TRUE)

# Creazione della lista per i risultati dei modelli
model_results <- list()

# Loop per eseguire la regressione per ogni colonna "Spec"
for (i in seq_along(spec_columns)) {
  col <- spec_columns[i]
  
  # Filtra le colonne corrispondenti
  control_vars <- metadata$names.Panel.[metadata[[col]] == "control_vars"]
  control_vars <- na.omit(control_vars)
  
  dependent_var <- metadata$names.Panel.[metadata[[col]] == "dependent_var"]
  dependent_var <- na.omit(dependent_var)
  
  independent_vars <- metadata$names.Panel.[metadata[[col]] == "independent_vars"]
  independent_vars <- na.omit(independent_vars)
  
  # Ottieni l'elenco delle interazioni specificate nel dataframe metadata
  interaction_vars <- metadata$names.Panel.[metadata[[col]] == "interaction"]
  interaction_vars <- na.omit(interaction_vars)
  
  # Aggiungi le interazioni all'elenco delle independent_vars
  independent_vars <- c(independent_vars, interaction_vars)
  
  # Esegui la regressione differenze in differenze per la colonna "Spec"
  formula_sum <- as.formula(paste(dependent_var, "~", paste(c(independent_vars, control_vars), collapse = "+")))
  model_sum <- plm(formula_sum, effect = "twoways", model = "within", data = Panel)
  
  # Aggiungi il risultato del modello alla lista dei risultati dei modelli
  model_results[[i]] <- model_sum
}

# Genera il riassunto dei risultati per tutti i modelli
summary_export <- export_summs(model_results, scale = TRUE, digits = 3, stars = c('***' = 0.01, '**' = 0.05, '*' = 0.1))

summary_export<-data.frame(summary_export)


#gli cambio nome per controllarlo
summary_export_1<-summary_export


num_cols <- ncol(summary_export)

for (i in 2:num_cols) {
  col_name <- paste0("Asterisco_", i-1)
  summary_export[col_name] <- sapply(summary_export[, i], function(x) {
    num_asterisks <- nchar(gsub("[^\\*]", "", x))
    if (num_asterisks > 0) {
      paste(rep("*", num_asterisks), collapse = "")
    } else {
      ""
    }
  })
  summary_export[, i] <- gsub("\\*", "", summary_export[, i])
}




# Seleziona le colonne "Model" e "Asterisco" nel nuovo ordine
num_columns <- min(length(grep("^Model\\.", colnames(summary_export))), length(grep("^Asterisco_", colnames(summary_export))))
model_cols <- grep("^Model\\.", colnames(summary_export), value = TRUE)[1:num_columns]
asterisco_cols <- grep("^Asterisco_", colnames(summary_export), value = TRUE)[1:num_columns]
summary_export_new <- summary_export[, c(rbind(model_cols, asterisco_cols))]

# Rinomina le colonne
colnames(summary_export_new) <- c(paste0("Model.", seq(num_columns)), paste0("Asterisco_", seq(num_columns)))


# Numero di colonne nel dataframe
n_colonne <- ncol(summary_export_new)

# Creazione del nuovo vettore di nomi delle colonne
nuovi_nomi <- c()

# Generazione dei nuovi nomi delle colonne
for (i in 1:n_colonne) {
  if (i %% 2 == 1) {
    nuovo_nome <- paste0("Model.", (i + 1) %/% 2)
  } else {
    nuovo_nome <- paste0("Asterisco_", i %/% 2)
  }
  nuovi_nomi <- c(nuovi_nomi, nuovo_nome)
}


# Rinomina delle colonne
colnames(summary_export_new) <- nuovi_nomi


# Rimozione delle parentesi dalle colonne del dataframe
summary_export_new <- apply(summary_export_new, 2, function(x) gsub("[()]", "", x))


summary_export_new<-summary_export_new[-1,]

summary_export_1_1<-summary_export_1
summary_export_1_1<-summary_export_1_1[-1,]
summary_export_1_1<-data.frame(summary_export_1_1[,1])
colnames(summary_export_1_1)<-"names"


summary_export_new<-cbind(summary_export_1_1,summary_export_new)





# Determina il numero totale di colonne nel dataframe
numero_colonne <- ncol(summary_export_new)

# Indici delle colonne da convertire
colonne_da_convertire <- seq(2, numero_colonne, by = 2)

# Conversione delle colonne selezionate in tipo numerico
summary_export_new[, colonne_da_convertire] <- lapply(summary_export_new[, colonne_da_convertire], as.numeric)

# Visualizzazione del dataframe con le colonne convertite
print(summary_export_new)



str(summary_export_new)



# Indici delle colonne numeriche da arrotondare
colonne_numeriche <- sapply(summary_export_new, is.numeric)

# Arrotondamento delle colonne numeriche alla terza cifra decimale
summary_export_new[, colonne_numeriche] <- lapply(summary_export_new[, colonne_numeriche], function(x) round(x, 3))

# Visualizzazione del dataframe con le colonne arrotondate
print(summary_export_new)

str(summary_export_new)




summary_export_new <- summary_export_new
for (i in seq(2, ncol(summary_export_new), by = 2)) {
  for (j in seq(2, ncol(summary_export_new), by = 2)) {
    if (!is.na(summary_export_new[i, j])) {
      if (i %% 2 == 0) {
        summary_export_new[i, j] <- paste0("(", summary_export_new[i, j], ")") # Nessuno spazio prima della parentesi
      } else {
        summary_export_new[i, j] <- paste0(summary_export_new[i, j], ".000") # Nessuno spazio prima del punto
      }
    }
  }
}





# Funzione per attaccare i valori delle colonne
attach_columns <- function(summary_export_new) {
  # Itera su tutte le colonne del dataframe
  for (col in names(summary_export_new)) {
    # Controlla se il nome della colonna inizia con "Asterisco_"
    if (startsWith(col, "Asterisco_")) {
      # Trova l'indice numerico corrispondente alla colonna Model.
      model_col_index <- match(sub("Asterisco_", "Model.", col), names(summary_export_new))
      # Attacca i valori delle colonne
      model_values <- summary_export_new[[model_col_index]]
      asterisco_values <- summary_export_new[[col]]
      
      # Sostituisci gli "NA" (stringhe) nella colonna Model. con NA (valori mancanti)
      model_values[model_values == "NA"] <- NA
      
      # Concatena i valori delle colonne
      summary_export_new[[model_col_index]] <- ifelse(is.na(model_values), NA, paste0(model_values, asterisco_values))
    }
  }
  
  return(summary_export_new)
}

# Chiamata alla funzione attach_columns
summary_export_new <- attach_columns(summary_export_new)



# Indice della colonna da cui iniziare
start_column <- 3

# Rimuovere le colonne dispari a partire dalla terza colonna
summary_export_new <- summary_export_new[, c(1:start_column-1, seq(start_column+1, ncol(summary_export_new), 2))]


summary_export_new


setwd("C:/Users/Utente/Il mio Drive")


# Scrivi il riassunto dei risultati nel foglio "Summary"
writeData(wb, sheet = "Summary", x = summary_export_new, startRow = 1, startCol = col_index)

# Salva il workbook in formato XLSX
saveWorkbook(wb, "output_generale.xlsx", overwrite = TRUE)


################################################################################



























































################################################################################
########################### DIGITAL FUSCO ######################################





############# librerie ##############

library(sf)
library(ggplot2)
library(tmap)
#install.packages("tmap", repos="http://cran.rstudio.com/", dependencies=TRUE)
library(tmaptools)
library(leaflet)
library(dplyr)
library(tidyr)
library(LabRS)
library(tidyverse)
library(sf)
library("RColorBrewer")
library(dplyr)
library(summarytools)
library(writexl)
library(desc)
library(summarytools)
library(readxl)
library(patchwork)
library(viridis)
library(cowplot)
library("openxlsx")
library(data.table)
library(stringr)
library(gridExtra)
library(lubridate)
library(tidyverse)
library(readxl)
library(dplyr)
library(openxlsx)
library(writexl)
library(readr)
library(stringr)

library(plm)

library(tidyr)
library(dplyr)


library(plm)
library(tidyverse)
library(readxl)
library(dplyr)
library(openxlsx)
library(writexl)
library(jtools)




#1 main 


pdata <- readRDS("C:/Users/Utente/Dropbox/Digital_Fusco/Codice/pdata.rds")


names(pdata)



pdata<-filter(pdata, pdata$Macroarea==1)




#log1p
pdata$PM10<-log1p(pdata$PM10)
pdata$Totale.Alberghi_pl <- log1p(pdata$Totale.Alberghi_pl)
pdata$Campeggi.e.Villaggi.turistici_pl <- log1p(pdata$Campeggi.e.Villaggi.turistici_pl)




str(Panel)

########################### genero il Panel ####################################

Panel <- pdata.frame(pdata, index=c("Provincia", "Anno"))

################################################################################






################## Verifo se ci sono duplicati nel Panel #######################


# Check for duplicate id-time combinations
duplicates <- table(index(Panel), useNA = "ifany")

# Find the duplicates where the count is more than 1
duplicate_indices <- which(duplicates > 1)

# If you want to see the actual values of the duplicates
if (length(duplicate_indices) > 0) {
  print(duplicates[duplicate_indices])
} else {
  print("No duplicates found")
}

################################################################################










######################### genero il Metadataframe ##############################


Panel_names<-pdata

Panel_names<-data.frame(names(Panel_names))

setwd("C:/Users/Utente/Dropbox/Digital_Fusco")


# Esporta il database in Excel
#write_xlsx(Panel_names, "meta_Db_Variabili.xlsx")

metadata <- read_xlsx("meta_fusco.xlsx", sheet = 7)

################################################################################


setwd("C:/Users/Utente/Dropbox/Digital_Fusco/output")




################################################################################
############################### Regressione TOTALE  ############################
################################################################################



# Crea un nuovo workbook
wb <- createWorkbook()

# Crea un foglio per i risultati
addWorksheet(wb, sheetName = "Summary")

# Inizializza l'indice di colonna
col_index <- 1

# Trova tutte le colonne "Spec" nel dataframe metadata
spec_columns <- grep("^Spec", colnames(metadata), value = TRUE)

# Creazione della lista per i risultati dei modelli
model_results <- list()

# Loop per eseguire la regressione per ogni colonna "Spec"
for (i in seq_along(spec_columns)) {
  col <- spec_columns[i]
  
  # Filtra le colonne corrispondenti
  control_vars <- metadata$names.Panel.[metadata[[col]] == "control_vars"]
  control_vars <- na.omit(control_vars)
  
  dependent_var <- metadata$names.Panel.[metadata[[col]] == "dependent_var"]
  dependent_var <- na.omit(dependent_var)
  
  independent_vars <- metadata$names.Panel.[metadata[[col]] == "independent_vars"]
  independent_vars <- na.omit(independent_vars)
  
  # Ottieni l'elenco delle interazioni specificate nel dataframe metadata
  interaction_vars <- metadata$names.Panel.[metadata[[col]] == "interaction"]
  interaction_vars <- na.omit(interaction_vars)
  
  # Aggiungi le interazioni all'elenco delle independent_vars
  independent_vars <- c(independent_vars, interaction_vars)
  
  # Esegui la regressione differenze in differenze per la colonna "Spec"
  formula_sum <- as.formula(paste(dependent_var, "~", paste(c(independent_vars, control_vars), collapse = "+")))
  model_sum <- plm(formula_sum, effect = "twoways", model = "within", data = Panel)
  
  # Aggiungi il risultato del modello alla lista dei risultati dei modelli
  model_results[[i]] <- model_sum
}

# Genera il riassunto dei risultati per tutti i modelli
summary_export <- export_summs(model_results, scale = TRUE, digits = 3, stars = c('***' = 0.01, '**' = 0.05, '*' = 0.1))

summary_export<-data.frame(summary_export)


#gli cambio nome per controllarlo
summary_export_1<-summary_export


num_cols <- ncol(summary_export)

for (i in 2:num_cols) {
  col_name <- paste0("Asterisco_", i-1)
  summary_export[col_name] <- sapply(summary_export[, i], function(x) {
    num_asterisks <- nchar(gsub("[^\\*]", "", x))
    if (num_asterisks > 0) {
      paste(rep("*", num_asterisks), collapse = "")
    } else {
      ""
    }
  })
  summary_export[, i] <- gsub("\\*", "", summary_export[, i])
}




# Seleziona le colonne "Model" e "Asterisco" nel nuovo ordine
num_columns <- min(length(grep("^Model\\.", colnames(summary_export))), length(grep("^Asterisco_", colnames(summary_export))))
model_cols <- grep("^Model\\.", colnames(summary_export), value = TRUE)[1:num_columns]
asterisco_cols <- grep("^Asterisco_", colnames(summary_export), value = TRUE)[1:num_columns]
summary_export_new <- summary_export[, c(rbind(model_cols, asterisco_cols))]

# Rinomina le colonne
colnames(summary_export_new) <- c(paste0("Model.", seq(num_columns)), paste0("Asterisco_", seq(num_columns)))


# Numero di colonne nel dataframe
n_colonne <- ncol(summary_export_new)

# Creazione del nuovo vettore di nomi delle colonne
nuovi_nomi <- c()

# Generazione dei nuovi nomi delle colonne
for (i in 1:n_colonne) {
  if (i %% 2 == 1) {
    nuovo_nome <- paste0("Model.", (i + 1) %/% 2)
  } else {
    nuovo_nome <- paste0("Asterisco_", i %/% 2)
  }
  nuovi_nomi <- c(nuovi_nomi, nuovo_nome)
}


# Rinomina delle colonne
colnames(summary_export_new) <- nuovi_nomi


# Rimozione delle parentesi dalle colonne del dataframe
summary_export_new <- apply(summary_export_new, 2, function(x) gsub("[()]", "", x))


summary_export_new<-summary_export_new[-1,]

summary_export_1_1<-summary_export_1
summary_export_1_1<-summary_export_1_1[-1,]
summary_export_1_1<-data.frame(summary_export_1_1[,1])
colnames(summary_export_1_1)<-"names"


summary_export_new<-cbind(summary_export_1_1,summary_export_new)





# Determina il numero totale di colonne nel dataframe
numero_colonne <- ncol(summary_export_new)

# Indici delle colonne da convertire
colonne_da_convertire <- seq(2, numero_colonne, by = 2)

# Conversione delle colonne selezionate in tipo numerico
summary_export_new[, colonne_da_convertire] <- lapply(summary_export_new[, colonne_da_convertire], as.numeric)

# Visualizzazione del dataframe con le colonne convertite
print(summary_export_new)



str(summary_export_new)



# Indici delle colonne numeriche da arrotondare
colonne_numeriche <- sapply(summary_export_new, is.numeric)

# Arrotondamento delle colonne numeriche alla terza cifra decimale
summary_export_new[, colonne_numeriche] <- lapply(summary_export_new[, colonne_numeriche], function(x) round(x, 3))

# Visualizzazione del dataframe con le colonne arrotondate
print(summary_export_new)

str(summary_export_new)




summary_export_new <- summary_export_new
for (i in seq(2, ncol(summary_export_new), by = 2)) {
  for (j in seq(2, ncol(summary_export_new), by = 2)) {
    if (!is.na(summary_export_new[i, j])) {
      if (i %% 2 == 0) {
        summary_export_new[i, j] <- paste0("(", summary_export_new[i, j], ")") # Nessuno spazio prima della parentesi
      } else {
        summary_export_new[i, j] <- paste0(summary_export_new[i, j], ".000") # Nessuno spazio prima del punto
      }
    }
  }
}





# Funzione per attaccare i valori delle colonne
attach_columns <- function(summary_export_new) {
  # Itera su tutte le colonne del dataframe
  for (col in names(summary_export_new)) {
    # Controlla se il nome della colonna inizia con "Asterisco_"
    if (startsWith(col, "Asterisco_")) {
      # Trova l'indice numerico corrispondente alla colonna Model.
      model_col_index <- match(sub("Asterisco_", "Model.", col), names(summary_export_new))
      # Attacca i valori delle colonne
      model_values <- summary_export_new[[model_col_index]]
      asterisco_values <- summary_export_new[[col]]
      
      # Sostituisci gli "NA" (stringhe) nella colonna Model. con NA (valori mancanti)
      model_values[model_values == "NA"] <- NA
      
      # Concatena i valori delle colonne
      summary_export_new[[model_col_index]] <- ifelse(is.na(model_values), NA, paste0(model_values, asterisco_values))
    }
  }
  
  return(summary_export_new)
}

# Chiamata alla funzione attach_columns
summary_export_new <- attach_columns(summary_export_new)



# Indice della colonna da cui iniziare
start_column <- 3

# Rimuovere le colonne dispari a partire dalla terza colonna
summary_export_new <- summary_export_new[, c(1:start_column-1, seq(start_column+1, ncol(summary_export_new), 2))]


summary_export_new


setwd("C:/Users/Utente/Il mio Drive")


# Scrivi il riassunto dei risultati nel foglio "Summary"
writeData(wb, sheet = "Summary", x = summary_export_new, startRow = 1, startCol = col_index)

# Salva il workbook in formato XLSX
saveWorkbook(wb, "output_nord.xlsx", overwrite = TRUE)


################################################################################



































################################################################################
########################### DIGITAL FUSCO ######################################





############# librerie ##############

library(sf)
library(ggplot2)
library(tmap)
#install.packages("tmap", repos="http://cran.rstudio.com/", dependencies=TRUE)
library(tmaptools)
library(leaflet)
library(dplyr)
library(tidyr)
library(LabRS)
library(tidyverse)
library(sf)
library("RColorBrewer")
library(dplyr)
library(summarytools)
library(writexl)
library(desc)
library(summarytools)
library(readxl)
library(patchwork)
library(viridis)
library(cowplot)
library("openxlsx")
library(data.table)
library(stringr)
library(gridExtra)
library(lubridate)
library(tidyverse)
library(readxl)
library(dplyr)
library(openxlsx)
library(writexl)
library(readr)
library(stringr)

library(plm)

library(tidyr)
library(dplyr)


library(plm)
library(tidyverse)
library(readxl)
library(dplyr)
library(openxlsx)
library(writexl)
library(jtools)




#1 main 




pdata <- readRDS("C:/Users/Utente/Dropbox/Digital_Fusco/Codice/pdata.rds")


names(pdata)



pdata<-filter(pdata, pdata$Macroarea==0)






#log1p
pdata$PM10<-log1p(pdata$PM10)
pdata$Totale.Alberghi_pl <- log1p(pdata$Totale.Alberghi_pl)
pdata$Campeggi.e.Villaggi.turistici_pl <- log1p(pdata$Campeggi.e.Villaggi.turistici_pl)





str(Panel)

########################### genero il Panel ####################################

Panel <- pdata.frame(pdata, index=c("Provincia", "Anno"))

################################################################################






################## Verifo se ci sono duplicati nel Panel #######################


# Check for duplicate id-time combinations
duplicates <- table(index(Panel), useNA = "ifany")

# Find the duplicates where the count is more than 1
duplicate_indices <- which(duplicates > 1)

# If you want to see the actual values of the duplicates
if (length(duplicate_indices) > 0) {
  print(duplicates[duplicate_indices])
} else {
  print("No duplicates found")
}

################################################################################










######################### genero il Metadataframe ##############################


Panel_names<-pdata

Panel_names<-data.frame(names(Panel_names))

setwd("C:/Users/Utente/Dropbox/Digital_Fusco")


# Esporta il database in Excel
#write_xlsx(Panel_names, "meta_Db_Variabili.xlsx")

metadata <- read_xlsx("meta_fusco.xlsx", sheet = 7)

################################################################################


setwd("C:/Users/Utente/Dropbox/Digital_Fusco/output")




################################################################################
############################### Regressione TOTALE  ############################
################################################################################



# Crea un nuovo workbook
wb <- createWorkbook()

# Crea un foglio per i risultati
addWorksheet(wb, sheetName = "Summary")

# Inizializza l'indice di colonna
col_index <- 1

# Trova tutte le colonne "Spec" nel dataframe metadata
spec_columns <- grep("^Spec", colnames(metadata), value = TRUE)

# Creazione della lista per i risultati dei modelli
model_results <- list()

# Loop per eseguire la regressione per ogni colonna "Spec"
for (i in seq_along(spec_columns)) {
  col <- spec_columns[i]
  
  # Filtra le colonne corrispondenti
  control_vars <- metadata$names.Panel.[metadata[[col]] == "control_vars"]
  control_vars <- na.omit(control_vars)
  
  dependent_var <- metadata$names.Panel.[metadata[[col]] == "dependent_var"]
  dependent_var <- na.omit(dependent_var)
  
  independent_vars <- metadata$names.Panel.[metadata[[col]] == "independent_vars"]
  independent_vars <- na.omit(independent_vars)
  
  # Ottieni l'elenco delle interazioni specificate nel dataframe metadata
  interaction_vars <- metadata$names.Panel.[metadata[[col]] == "interaction"]
  interaction_vars <- na.omit(interaction_vars)
  
  # Aggiungi le interazioni all'elenco delle independent_vars
  independent_vars <- c(independent_vars, interaction_vars)
  
  # Esegui la regressione differenze in differenze per la colonna "Spec"
  formula_sum <- as.formula(paste(dependent_var, "~", paste(c(independent_vars, control_vars), collapse = "+")))
  model_sum <- plm(formula_sum, effect = "twoways", model = "within", data = Panel)
  
  # Aggiungi il risultato del modello alla lista dei risultati dei modelli
  model_results[[i]] <- model_sum
}

# Genera il riassunto dei risultati per tutti i modelli
summary_export <- export_summs(model_results, scale = TRUE, digits = 3, stars = c('***' = 0.01, '**' = 0.05, '*' = 0.1))

summary_export<-data.frame(summary_export)


#gli cambio nome per controllarlo
summary_export_1<-summary_export


num_cols <- ncol(summary_export)

for (i in 2:num_cols) {
  col_name <- paste0("Asterisco_", i-1)
  summary_export[col_name] <- sapply(summary_export[, i], function(x) {
    num_asterisks <- nchar(gsub("[^\\*]", "", x))
    if (num_asterisks > 0) {
      paste(rep("*", num_asterisks), collapse = "")
    } else {
      ""
    }
  })
  summary_export[, i] <- gsub("\\*", "", summary_export[, i])
}




# Seleziona le colonne "Model" e "Asterisco" nel nuovo ordine
num_columns <- min(length(grep("^Model\\.", colnames(summary_export))), length(grep("^Asterisco_", colnames(summary_export))))
model_cols <- grep("^Model\\.", colnames(summary_export), value = TRUE)[1:num_columns]
asterisco_cols <- grep("^Asterisco_", colnames(summary_export), value = TRUE)[1:num_columns]
summary_export_new <- summary_export[, c(rbind(model_cols, asterisco_cols))]

# Rinomina le colonne
colnames(summary_export_new) <- c(paste0("Model.", seq(num_columns)), paste0("Asterisco_", seq(num_columns)))


# Numero di colonne nel dataframe
n_colonne <- ncol(summary_export_new)

# Creazione del nuovo vettore di nomi delle colonne
nuovi_nomi <- c()

# Generazione dei nuovi nomi delle colonne
for (i in 1:n_colonne) {
  if (i %% 2 == 1) {
    nuovo_nome <- paste0("Model.", (i + 1) %/% 2)
  } else {
    nuovo_nome <- paste0("Asterisco_", i %/% 2)
  }
  nuovi_nomi <- c(nuovi_nomi, nuovo_nome)
}


# Rinomina delle colonne
colnames(summary_export_new) <- nuovi_nomi


# Rimozione delle parentesi dalle colonne del dataframe
summary_export_new <- apply(summary_export_new, 2, function(x) gsub("[()]", "", x))


summary_export_new<-summary_export_new[-1,]

summary_export_1_1<-summary_export_1
summary_export_1_1<-summary_export_1_1[-1,]
summary_export_1_1<-data.frame(summary_export_1_1[,1])
colnames(summary_export_1_1)<-"names"


summary_export_new<-cbind(summary_export_1_1,summary_export_new)





# Determina il numero totale di colonne nel dataframe
numero_colonne <- ncol(summary_export_new)

# Indici delle colonne da convertire
colonne_da_convertire <- seq(2, numero_colonne, by = 2)

# Conversione delle colonne selezionate in tipo numerico
summary_export_new[, colonne_da_convertire] <- lapply(summary_export_new[, colonne_da_convertire], as.numeric)

# Visualizzazione del dataframe con le colonne convertite
print(summary_export_new)



str(summary_export_new)



# Indici delle colonne numeriche da arrotondare
colonne_numeriche <- sapply(summary_export_new, is.numeric)

# Arrotondamento delle colonne numeriche alla terza cifra decimale
summary_export_new[, colonne_numeriche] <- lapply(summary_export_new[, colonne_numeriche], function(x) round(x, 3))

# Visualizzazione del dataframe con le colonne arrotondate
print(summary_export_new)

str(summary_export_new)




summary_export_new <- summary_export_new
for (i in seq(2, ncol(summary_export_new), by = 2)) {
  for (j in seq(2, ncol(summary_export_new), by = 2)) {
    if (!is.na(summary_export_new[i, j])) {
      if (i %% 2 == 0) {
        summary_export_new[i, j] <- paste0("(", summary_export_new[i, j], ")") # Nessuno spazio prima della parentesi
      } else {
        summary_export_new[i, j] <- paste0(summary_export_new[i, j], ".000") # Nessuno spazio prima del punto
      }
    }
  }
}





# Funzione per attaccare i valori delle colonne
attach_columns <- function(summary_export_new) {
  # Itera su tutte le colonne del dataframe
  for (col in names(summary_export_new)) {
    # Controlla se il nome della colonna inizia con "Asterisco_"
    if (startsWith(col, "Asterisco_")) {
      # Trova l'indice numerico corrispondente alla colonna Model.
      model_col_index <- match(sub("Asterisco_", "Model.", col), names(summary_export_new))
      # Attacca i valori delle colonne
      model_values <- summary_export_new[[model_col_index]]
      asterisco_values <- summary_export_new[[col]]
      
      # Sostituisci gli "NA" (stringhe) nella colonna Model. con NA (valori mancanti)
      model_values[model_values == "NA"] <- NA
      
      # Concatena i valori delle colonne
      summary_export_new[[model_col_index]] <- ifelse(is.na(model_values), NA, paste0(model_values, asterisco_values))
    }
  }
  
  return(summary_export_new)
}

# Chiamata alla funzione attach_columns
summary_export_new <- attach_columns(summary_export_new)



# Indice della colonna da cui iniziare
start_column <- 3

# Rimuovere le colonne dispari a partire dalla terza colonna
summary_export_new <- summary_export_new[, c(1:start_column-1, seq(start_column+1, ncol(summary_export_new), 2))]


summary_export_new


setwd("C:/Users/Utente/Il mio Drive")


# Scrivi il riassunto dei risultati nel foglio "Summary"
writeData(wb, sheet = "Summary", x = summary_export_new, startRow = 1, startCol = col_index)

# Salva il workbook in formato XLSX
saveWorkbook(wb, "output_sud.xlsx", overwrite = TRUE)


################################################################################




































################################################################################
########################### DIGITAL FUSCO ######################################





############# librerie ##############

library(sf)
library(ggplot2)
library(tmap)
#install.packages("tmap", repos="http://cran.rstudio.com/", dependencies=TRUE)
library(tmaptools)
library(leaflet)
library(dplyr)
library(tidyr)
library(LabRS)
library(tidyverse)
library(sf)
library("RColorBrewer")
library(dplyr)
library(summarytools)
library(writexl)
library(desc)
library(summarytools)
library(readxl)
library(patchwork)
library(viridis)
library(cowplot)
library("openxlsx")
library(data.table)
library(stringr)
library(gridExtra)
library(lubridate)
library(tidyverse)
library(readxl)
library(dplyr)
library(openxlsx)
library(writexl)
library(readr)
library(stringr)

library(plm)

library(tidyr)
library(dplyr)


library(plm)
library(tidyverse)
library(readxl)
library(dplyr)
library(openxlsx)
library(writexl)
library(jtools)




#1 main 






pdata <- readRDS("C:/Users/Utente/Dropbox/Digital_Fusco/Codice/pdata.rds")




names(pdata)




summary(pdata)


table(pdata$Target_100_Mbps_rurale_sup, pdata$Anno)
table(pdata$Target_100_Mbps_rurale_pop, pdata$Anno)



#log1p
pdata$PM10<-log1p(pdata$PM10)
pdata$Totale.Alberghi_pl <- log1p(pdata$Totale.Alberghi_pl)
pdata$Campeggi.e.Villaggi.turistici_pl <- log1p(pdata$Campeggi.e.Villaggi.turistici_pl)



pdata$Anno <-as.numeric(as.character(pdata$Anno))



pdata<-subset(pdata, pdata$Anno>2019)


########################### genero il Panel ####################################

Panel <- pdata.frame(pdata, index=c("Provincia", "Anno"))

################################################################################






################## Verifo se ci sono duplicati nel Panel #######################


# Check for duplicate id-time combinations
duplicates <- table(index(Panel), useNA = "ifany")

# Find the duplicates where the count is more than 1
duplicate_indices <- which(duplicates > 1)

# If you want to see the actual values of the duplicates
if (length(duplicate_indices) > 0) {
  print(duplicates[duplicate_indices])
} else {
  print("No duplicates found")
}

################################################################################










######################### genero il Metadataframe ##############################


Panel_names<-pdata

Panel_names<-data.frame(names(Panel_names))

setwd("C:/Users/Utente/Dropbox/Digital_Fusco")


# Esporta il database in Excel
#write_xlsx(Panel_names, "meta_Db_Variabili.xlsx")

metadata <- read_xlsx("meta_fusco.xlsx", sheet = 7)

################################################################################


setwd("C:/Users/Utente/Dropbox/Digital_Fusco/output")




################################################################################
############################### Regressione TOTALE  ############################
################################################################################



# Crea un nuovo workbook
wb <- createWorkbook()

# Crea un foglio per i risultati
addWorksheet(wb, sheetName = "Summary")

# Inizializza l'indice di colonna
col_index <- 1

# Trova tutte le colonne "Spec" nel dataframe metadata
spec_columns <- grep("^Spec", colnames(metadata), value = TRUE)

# Creazione della lista per i risultati dei modelli
model_results <- list()

# Loop per eseguire la regressione per ogni colonna "Spec"
for (i in seq_along(spec_columns)) {
  col <- spec_columns[i]
  
  # Filtra le colonne corrispondenti
  control_vars <- metadata$names.Panel.[metadata[[col]] == "control_vars"]
  control_vars <- na.omit(control_vars)
  
  dependent_var <- metadata$names.Panel.[metadata[[col]] == "dependent_var"]
  dependent_var <- na.omit(dependent_var)
  
  independent_vars <- metadata$names.Panel.[metadata[[col]] == "independent_vars"]
  independent_vars <- na.omit(independent_vars)
  
  # Ottieni l'elenco delle interazioni specificate nel dataframe metadata
  interaction_vars <- metadata$names.Panel.[metadata[[col]] == "interaction"]
  interaction_vars <- na.omit(interaction_vars)
  
  # Aggiungi le interazioni all'elenco delle independent_vars
  independent_vars <- c(independent_vars, interaction_vars)
  
  # Esegui la regressione differenze in differenze per la colonna "Spec"
  formula_sum <- as.formula(paste(dependent_var, "~", paste(c(independent_vars, control_vars), collapse = "+")))
  model_sum <- plm(formula_sum, effect = "twoways", model = "within", data = Panel)
  
  # Aggiungi il risultato del modello alla lista dei risultati dei modelli
  model_results[[i]] <- model_sum
}

# Genera il riassunto dei risultati per tutti i modelli
summary_export <- export_summs(model_results, scale = TRUE, digits = 3, stars = c('***' = 0.01, '**' = 0.05, '*' = 0.1))

summary_export<-data.frame(summary_export)


#gli cambio nome per controllarlo
summary_export_1<-summary_export


num_cols <- ncol(summary_export)

for (i in 2:num_cols) {
  col_name <- paste0("Asterisco_", i-1)
  summary_export[col_name] <- sapply(summary_export[, i], function(x) {
    num_asterisks <- nchar(gsub("[^\\*]", "", x))
    if (num_asterisks > 0) {
      paste(rep("*", num_asterisks), collapse = "")
    } else {
      ""
    }
  })
  summary_export[, i] <- gsub("\\*", "", summary_export[, i])
}




# Seleziona le colonne "Model" e "Asterisco" nel nuovo ordine
num_columns <- min(length(grep("^Model\\.", colnames(summary_export))), length(grep("^Asterisco_", colnames(summary_export))))
model_cols <- grep("^Model\\.", colnames(summary_export), value = TRUE)[1:num_columns]
asterisco_cols <- grep("^Asterisco_", colnames(summary_export), value = TRUE)[1:num_columns]
summary_export_new <- summary_export[, c(rbind(model_cols, asterisco_cols))]

# Rinomina le colonne
colnames(summary_export_new) <- c(paste0("Model.", seq(num_columns)), paste0("Asterisco_", seq(num_columns)))


# Numero di colonne nel dataframe
n_colonne <- ncol(summary_export_new)

# Creazione del nuovo vettore di nomi delle colonne
nuovi_nomi <- c()

# Generazione dei nuovi nomi delle colonne
for (i in 1:n_colonne) {
  if (i %% 2 == 1) {
    nuovo_nome <- paste0("Model.", (i + 1) %/% 2)
  } else {
    nuovo_nome <- paste0("Asterisco_", i %/% 2)
  }
  nuovi_nomi <- c(nuovi_nomi, nuovo_nome)
}


# Rinomina delle colonne
colnames(summary_export_new) <- nuovi_nomi


# Rimozione delle parentesi dalle colonne del dataframe
summary_export_new <- apply(summary_export_new, 2, function(x) gsub("[()]", "", x))


summary_export_new<-summary_export_new[-1,]

summary_export_1_1<-summary_export_1
summary_export_1_1<-summary_export_1_1[-1,]
summary_export_1_1<-data.frame(summary_export_1_1[,1])
colnames(summary_export_1_1)<-"names"


summary_export_new<-cbind(summary_export_1_1,summary_export_new)





# Determina il numero totale di colonne nel dataframe
numero_colonne <- ncol(summary_export_new)

# Indici delle colonne da convertire
colonne_da_convertire <- seq(2, numero_colonne, by = 2)

# Conversione delle colonne selezionate in tipo numerico
summary_export_new[, colonne_da_convertire] <- lapply(summary_export_new[, colonne_da_convertire], as.numeric)

# Visualizzazione del dataframe con le colonne convertite
print(summary_export_new)



str(summary_export_new)



# Indici delle colonne numeriche da arrotondare
colonne_numeriche <- sapply(summary_export_new, is.numeric)

# Arrotondamento delle colonne numeriche alla terza cifra decimale
summary_export_new[, colonne_numeriche] <- lapply(summary_export_new[, colonne_numeriche], function(x) round(x, 3))

# Visualizzazione del dataframe con le colonne arrotondate
print(summary_export_new)

str(summary_export_new)




summary_export_new <- summary_export_new
for (i in seq(2, ncol(summary_export_new), by = 2)) {
  for (j in seq(2, ncol(summary_export_new), by = 2)) {
    if (!is.na(summary_export_new[i, j])) {
      if (i %% 2 == 0) {
        summary_export_new[i, j] <- paste0("(", summary_export_new[i, j], ")") # Nessuno spazio prima della parentesi
      } else {
        summary_export_new[i, j] <- paste0(summary_export_new[i, j], ".000") # Nessuno spazio prima del punto
      }
    }
  }
}





# Funzione per attaccare i valori delle colonne
attach_columns <- function(summary_export_new) {
  # Itera su tutte le colonne del dataframe
  for (col in names(summary_export_new)) {
    # Controlla se il nome della colonna inizia con "Asterisco_"
    if (startsWith(col, "Asterisco_")) {
      # Trova l'indice numerico corrispondente alla colonna Model.
      model_col_index <- match(sub("Asterisco_", "Model.", col), names(summary_export_new))
      # Attacca i valori delle colonne
      model_values <- summary_export_new[[model_col_index]]
      asterisco_values <- summary_export_new[[col]]
      
      # Sostituisci gli "NA" (stringhe) nella colonna Model. con NA (valori mancanti)
      model_values[model_values == "NA"] <- NA
      
      # Concatena i valori delle colonne
      summary_export_new[[model_col_index]] <- ifelse(is.na(model_values), NA, paste0(model_values, asterisco_values))
    }
  }
  
  return(summary_export_new)
}

# Chiamata alla funzione attach_columns
summary_export_new <- attach_columns(summary_export_new)



# Indice della colonna da cui iniziare
start_column <- 3

# Rimuovere le colonne dispari a partire dalla terza colonna
summary_export_new <- summary_export_new[, c(1:start_column-1, seq(start_column+1, ncol(summary_export_new), 2))]


summary_export_new


setwd("C:/Users/Utente/Il mio Drive")


# Scrivi il riassunto dei risultati nel foglio "Summary"
writeData(wb, sheet = "Summary", x = summary_export_new, startRow = 1, startCol = col_index)

# Salva il workbook in formato XLSX
saveWorkbook(wb, "output_post.xlsx", overwrite = TRUE)


################################################################################


