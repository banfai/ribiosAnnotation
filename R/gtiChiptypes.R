gtiChiptypes <- function(include.desc=FALSE) {

  state <- "SELECT ARRAY_TYPE, TECHNOLOGY, SPECIES, DESCRIPTION FROM genome.CHIP_ARRAY_TYPES"
  df <- querydb(state, db="bin", user=ORACLE.BIN.USER, password=ORACLE.BIN.PWD)
  if(include.desc) {
    res <- df
    colnames(res) <- c("Chiptype", "Technology", "Species", "Description")
  } else {
    res <- df[,1L]
  }
  return(res)
}

isGtiChiptype <- function(x, exceptions, ignore.case=FALSE) {
  gct <- gtiChiptypes(include.desc=FALSE)
  if(!missing(exceptions))
    gct <- c(gct, as.character(exceptions))
  if(ignore.case) {
    x <- tolower(x);
    gct <- tolower(gct)
  }
  x %in% gct
}

scriptChiptypes <- function() {
  return(c("GeneID", "GeneSymbol",gtiChiptypes()))
}

gtiChipnames <- function(...) {gtiChiptypes(...)}
gtiArraytypes <- function(...) {gtiChiptypes(...)}
  
affychipNames <- function(...) {
  .Deprecated("gtiChiptypes",package="ribiosAnnotation")
  gtiChipnames(...) 
}
raceChiptypes <- function(...) {
  .Deprecated("gtiChiptypes",package="ribiosAnnotation")
  gtiChiptypes(...) 
}
raceChipnames <- function(...) {
  .Deprecated("gtiChipnames",package="ribiosAnnotation")
  gtiChipnames(...) 
}