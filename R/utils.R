#' Load secrets from a file and set them in options
#'
#' @param path Path to the secret file
#'
#' @return The current options of \code{ribiosAnnotation}
#' The function writes the \code{credentials} field of the options
#' After running this function, database names and passwords can be accessed
#' @importFrom jsonlite read_json
#' @export
loadSecrets <- function(path=file.path("/pstore/apps/bioinfo",
                                       "ribios/secrets",
                                       "ribiosAnnotation-secrets.json")) {
  if (!file.exists(path)) {
    ## the message below must not be sent with warning, otherwise
    ## packages that depdend on ribiosAnnotation will not load properly.
    message("Can't find secret file: '", path, "'. Queries will not work.")
    path <- system.file("secrets/secrets-template.json", 
                        package="ribiosAnnotation")
  }
  secrets <- jsonlite::read_json(path)
  opts <- options("ribiosAnnotation")[[1]]
  opts$credentials <- secrets$credentials
  opts$connection <- secrets$connection
  options("ribiosAnnotation"=opts)
  return(invisible(opts))
}

#' Quick access of credentials
#' 
#' @aliases biaUser biaPwd bia2User bia2Pwd biaroUser biaroPwd binUser binPwd
#' @section Functions: \itemize{ \item \code{biaPwd}: BIA password
#' 
#' \item \code{bia2User}: BIA2 username
#' 
#' \item \code{bia2Pwd}: BIA2 password
#' 
#' \item \code{biaroUser}: BIA READONLY username
#' 
#' \item \code{biaroPwd}: BIA READONLY password
#' 
#' \item \code{binUser}: BIN username
#' 
#' \item \code{binPwd}: BIN password }
#' @export
biaUser <- function() 
  return(options()$ribiosAnnotation$credentials$bi$username)

#' @describeIn biaUser BIA password
#' @export
biaPwd <- function() 
  return(options()$ribiosAnnotation$credentials$bi$password)

#' @describeIn biaUser BIA2 username
#' @export
bia2User <- function() 
  return(options()$ribiosAnnotation$credentials$bi2$username)

#' @describeIn biaUser BIA2 password
#' @export
bia2Pwd <- function() 
  return(options()$ribiosAnnotation$credentials$bi2$password)

#' @describeIn biaUser BIA READONLY username
#' @export
biaroUser <- function() 
  return(options()$ribiosAnnotation$credentials$biaro$username)

#' @describeIn biaUser BIA READONLY password
#' @export
biaroPwd <- function() 
  return(options()$ribiosAnnotation$credentials$biaro$password)

#' @describeIn biaUser BIN username
#' @export 
binUser <- function() 
  return(options()$ribiosAnnotation$credentials$bin$username)

#' @describeIn biaUser BIN password
#' @export
binPwd <- function() return(options()$ribiosAnnotation$credentials$bin$password)

#' Maximum vector length in the IN syntax
#' 
oracleInNmax <- function() return(options()$ribiosAnnotation$ORACLE.IN.NMAX)


#' Make connect string for Oracle
#' @param host A character string, host name
#' @param post A integer, port
#' @param sid A character string, service id
#' @return A string that can be used by \code{\link{dbConnect}} as dbname
#' @keywords internal
#' @seealso \code{jdbcConnectString}
oracleConnectString <- function(host, port, sid) {
  res <- paste(
    "(DESCRIPTION=",
    "(ADDRESS=(PROTOCOL=TCP)(HOST=", host, ")(PORT=", port, "))",
    "(CONNECT_DATA=(SERVER=dedicated)(SERVICE_NAME=", sid, ")))", sep = "")
  return(res)
}

#' Database name for Oracle
#' @export
dbName <- function() {
  connection <- options()$ribiosAnnotation$connection
  res <- oracleConnectString(connection$host,
                             connection$port,
                             connection$service_name)
  return(res)
}

#' Oracle object name
#' @export
oracleObject <- function() return(options()$ribiosAnnotation$oracleObject)

##--------------------##
## constants
##--------------------##

## function to test whether Oracle is available


#' Testing whether the Oracle client library is installed
#' 
#' The function tests whether the Oracle client library is installed. If so,
#' the package uses \code{ROracle} as driver interface to Oracle database,
#' otherwise \code{RJDBC} is used.
#' 
#' 
#' @return Logical. \code{TRUE} indicates Oracle SQL client is installed.
#' @author Jitao David Zhang <jitao_david.zhang@@roche.com>
#' @examples
#' 
#' hasOracle()
#' 
#' @export hasOracle
hasOracle <- function() {
  return(requireNamespace("ROracle", quietly=TRUE))
}

## onload / onAttach
## .onLoad <- function(libname, pkgname) {}
.onAttach <- function(libname, pkgname) {
  if(hasOracle()) {
    if(!"package:ROracle" %in% search())
      attachNamespace("ROracle")
    oracleObj <- ROracle::Oracle(interruptible = TRUE)
  } else {
    oracleObj <- NULL
  }
  options("ribiosAnnotation"=list(oracleObject=oracleObj,
                                  ORACLE.IN.NMAX=1000L))
  loadSecrets()
}

#' Make connect string for JDBC
#' @param user A character string, user id
#' @param password A character string, password
#' @param host A character string, host name
#' @param post A integer, port
#' @param sid A character string, service id
#' @return A string that can be used by \code{\link{dbConnect}} as dbname
#' @keywords internal
#' @seealso \code{oracleConnectString}
jdbcConnectString <- function(user, password, host, port, sid) {
  res <- paste("jdbc:oracle:thin:", user, "/", password, 
               "@", host, ":", port, "/", sid, sep="")
  return(res)
}

#' Get a connection object
#' 
#' Get a connection object for communication with Oracle database.
#' 
#' Depending on the availability of Oracle client library,
#' \code{ribiosAnnotation} automatically uses either \code{OraConnection} of
#' the \code{ROracle} package or \code{JDBCConnection} of \code{RJDBC} to
#' access database.
#' 
#' @param db Database name
#' @param user User name
#' @param password Password
#' @param forceJDBC Logical, forcing the user of JDBC interface to fetch data
#' from Oracle servers. By default it is set to \code{FALSE}, since the JDBC
#' interface is slower than native ROracle implementation. This option is
#' largely for debugging purposes.
#' @return A connection object of the type \code{OraConnection} when Oracle
#' client library is available, or \code{JDBCConnection} otherwise. Setting
#' \code{forceJDBC} to \code{FALSE} makes the function return a
#' \code{JDBCCOnnection} object independent of library availability.
#' @note TODO: 1g memory at least is hard-coded. How to infer it?
#' @author Jitao David Zhang <jitao_david.zhang@@roche.com>
#' @seealso \code{\link{dbConnect}}
#' @examples
#' 
#' options(error=utils::recover)
#' (con <- ribiosCon(db="bia", user="biread", password="biread"))
#' (conJDBC <- ribiosCon(db="bia", user="biread", password="biread",
#' forceJDBC=TRUE))
#' 
#' dbDisconnect(con)
#' dbDisconnect(conJDBC)
#' options(error=NULL)
#' 
#' @importFrom DBI dbConnect dbExistsTable dbSendQuery dbHasCompleted fetch dbClearResult dbDisconnect
#' @export ribiosCon
ribiosCon <- function(db=dbName(), user=biaroUser(), password=biaroPwd(), 
                      forceJDBC=FALSE) {
  if(hasOracle() & !forceJDBC) {
    con <- dbConnect(oracleObject(), user = user, password = password, db = db)
  } else {
    options(java.parameters = "-Xmx1g" ) ## increase the heap size before the RJDBC package is loaded
    suppressWarnings(suppressMessages(hasJDBC <- requireNamespace("RJDBC")))
    if(!hasJDBC)
      stop("No JDBC package installed: please run 'install.packages('RJDBC')' first and then load ribiosAnnotation again.")
    drv <- RJDBC::JDBC("oracle.jdbc.OracleDriver",
                       system.file("drivers", "ojdbc7.jar", package="ribiosAnnotation"))
    connection <- options()$ribiosAnnotation$connection
    str <- jdbcConnectString(user, password,
                             connection$host,
                             connection$port,
                             connection$service_name)
    con <- dbConnect(drv,str)
  }
  return(con)
}

## shortcuts for common connections
newconBIA <- function() ribiosCon(db=dbName(), user=biaUser(), password=biaPwd())
newconBIA2 <- function() ribiosCon(db=dbName(), user=bia2User(), password=bia2Pwd())
newconBIARO <- function() ribiosCon(db=dbName(), user=biaroUser(), password=biaroPwd())
newconBIN <- function() ribiosCon(db=dbName(), user=binUser(), password=binPwd())

##----------------------------------------##
## deprecated functions
##----------------------------------------##
biosCurrentGeneSymbol <- function(...) {
  .Deprecated("gtiChipAnnotation",
              package="ribiosAnnotation")
  gtiChipAnnotation(...)
}

raceChipAnnotation <- function(...) {
  .Deprecated("gtiChipAnnotation",
              package="ribiosAnnotation")
  gtiChipAnnotation(...)
}
