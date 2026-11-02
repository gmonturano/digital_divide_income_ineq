# Data availability and variable inspection; run from repository root
pdata <- readRDS("db/pdata.rds")
cat("Rows:", nrow(pdata), " Columns:", ncol(pdata), "\n")
print(names(pdata))
print(utils::head(pdata, 6))
