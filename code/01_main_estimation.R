# Main empirical specifications: broadband coverage and income inequality
source('code/00_functions.R')
db <- load_rdata_panel('db/db_finale.RData', preferred='DB_COV9_')
db$Anno <- suppressWarnings(as.numeric(as.character(db$Anno)))
models <- run_twfe_specs(db, 'code/meta_fusco.xlsx', id='Provincia', time='Anno')
