# Metadata-driven estimation helpers

load_rdata_panel <- function(path, preferred = NULL) {
  if (!file.exists(path)) stop('Missing data file: ', path)
  env <- new.env(parent = baseenv())
  nm <- load(path, envir = env)
  if (!is.null(preferred) && preferred %in% nm && is.data.frame(env[[preferred]])) {
    return(as.data.frame(env[[preferred]]))
  }
  available <- nm[vapply(nm, function(x) is.data.frame(env[[x]]), logical(1))]
  if (length(available) != 1L) {
    stop('Expected one data.frame in ', path, '; found: ', paste(available, collapse=', '))
  }
  as.data.frame(env[[available]])
}

read_main_specs <- function(file) {
  if (!requireNamespace('readxl', quietly = TRUE)) stop('Install the readxl package.')
  m <- as.data.frame(readxl::read_excel(file, sheet = 1, .name_repair = 'minimal'))
  names(m)[1] <- 'variable'
  m$variable <- trimws(as.character(m$variable))
  m <- m[!is.na(m$variable) & nzchar(m$variable), , drop=FALSE]
  spec_names <- grep('^Spec', names(m), value = TRUE)
  if (!length(spec_names)) stop('No specification columns in metadata.')
  lapply(setNames(spec_names, spec_names), function(s) {
    role <- as.character(m[[s]])
    role[is.na(role)] <- ''
    take <- function(label) unique(m$variable[role == label & nzchar(m$variable)])
    list(dependent=take('dependent_var'), independent=take('independent_vars'),
         controls=take('control_vars'), interaction=take('interaction'),
         instruments=take('instrument_vars'))
  })
}

run_twfe_specs <- function(dat, metadata, id, time, output_dir='results') {
  if (!requireNamespace('plm', quietly = TRUE)) stop('Install the plm package.')
  if (!id %in% names(dat) || !time %in% names(dat)) stop('Panel indexes missing in data.')
  dir.create(output_dir, recursive=TRUE, showWarnings=FALSE)
  dat <- as.data.frame(dat)
  dat <- dat[!is.na(dat[[id]]) & !is.na(dat[[time]]), , drop=FALSE]
  dat <- dat[!duplicated(dat[, c(id,time)]), , drop=FALSE]
  spec <- read_main_specs(metadata)
  results <- list()
  status <- list()
  for (name in names(spec)) {
    s <- spec[[name]]
    dep <- s$dependent
    rhs <- unique(c(s$independent, s$interaction, s$controls))
    needed <- unique(c(dep, rhs))
    absent <- setdiff(needed, names(dat))
    if (length(dep) != 1L || !length(rhs) || length(absent)) {
      status[[name]] <- data.frame(specification=name, status='not estimated',
                                    detail=paste(c(if (length(dep)!=1L) 'invalid outcome',
                                                   if (!length(rhs)) 'empty RHS',
                                                   if (length(absent)) paste('missing:',paste(absent,collapse='; '))),collapse=' | '))
      next
    }
    f <- stats::reformulate(rhs, response=dep)
    model <- tryCatch(plm::plm(f, data=plm::pdata.frame(dat,index=c(id,time)),
                                model='within', effect='twoways'), error=function(e) e)
    if (inherits(model,'error')) {
      status[[name]] <- data.frame(specification=name,status='failed',detail=conditionMessage(model))
      next
    }
    results[[name]] <- model
    tab <- as.data.frame(summary(model)$coefficients)
    tab$term <- rownames(tab)
    utils::write.csv(tab,file.path(output_dir,paste0(name,'_coefficients.csv')),row.names=FALSE)
    status[[name]] <- data.frame(specification=name,status='estimated',detail='TWFE within model')
  }
  if (length(status)) utils::write.csv(do.call(rbind,status),file.path(output_dir,'model_status.csv'),row.names=FALSE)
  invisible(results)
}
