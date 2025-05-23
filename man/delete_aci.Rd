% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/add_aci_methods.R
\name{delete_aci}
\alias{delete_aci}
\title{Delete an Azure Container Instance (ACI)}
\description{
Method for the \link[AzureRMR:az_resource_group]{AzureRMR::az_resource_group} class.
}
\section{Usage}{


\if{html}{\out{<div class="sourceCode">}}\preformatted{delete_aci(name, confirm=TRUE, wait=FALSE)
}\if{html}{\out{</div>}}
}

\section{Arguments}{

\itemize{
\item \code{name}: The name of the container instance.
\item \code{confirm}: Whether to ask for confirmation before deleting.
\item \code{wait}: Whether to wait until the deletion is complete.
}
}

\section{Value}{

NULL on successful deletion.
}

\examples{
\dontrun{

rg <- AzureRMR::get_azure_login()$
    get_subscription("subscription_id")$
    get_resource_group("rgname")

rg$delete_aci("mycontainer")

}
}
\seealso{
\link{create_aci}, \link{get_aci}

\link{az_container_instance}

\href{https://learn.microsoft.com/en-us/azure/container-instances/}{ACI documentation} and
\href{https://learn.microsoft.com/en-us/rest/api/container-instances/}{API reference}

\href{https://docs.docker.com/engine/reference/commandline/cli/}{Docker commandline reference}
}
