% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/load.R
\name{load.tool.choices}
\alias{load.tool.choices}
\title{Load the 'choices' tab from a Kobo tool.}
\usage{
load.tool.choices(filename_tool, label_colname, keep_cols = F)
}
\arguments{
\item{filename_tool}{This is the path to the file that contains the tool}

\item{label_colname}{This is the variable of the label colname}

\item{keep_cols}{Whether all columns in your kobo choices sheet should be kept}
}
\value{
A dataframe: tool.choices, it's the same as the 'choices' tab from the tool, filtered to include only distinct rows.
}
\description{
Load the 'choices' tab from a Kobo tool.
}
\examples{
\dontrun{
filename_tool <- "tool.xlsx"
label_colname <- load.label.colname(filename_tool)
tool_choices <- load.tool.choices(filename_tool, label_colname)
}
}
