% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/az_kubernetes_service.R
\docType{class}
\name{aks}
\alias{aks}
\alias{az_kubernetes_service}
\title{Azure Kubernetes Service class}
\description{
Class representing an Azure Kubernetes Service (AKS) resource. For working with the cluster endpoint itself, including deploying images, creating services etc, see \link{kubernetes_cluster}.
}
\section{Methods}{

The following methods are available, in addition to those provided by the \link[AzureRMR:az_resource]{AzureRMR::az_resource} class:
\itemize{
\item \code{new(...)}: Initialize a new AKS object.
\item \code{get_cluster(config, role)}: Return an object representing the Docker registry endpoint.
\item \code{get_agent_pool(pollname)}: Returns an object of class \code{az_agent_pool} representing an agent pool. This class inherits from \link[AzureRMR:az_resource]{AzureRMR::az_resource}; it currently has no extra methods, but these may be added in the future.
\item \code{list_agent_pools()}: Returns a list of agent pool objects.
\item \code{create_agent_pool(poolname, ..., wait=FALSE)}: Creates a new agent pool. See the \link{agent_pool} function for further arguments to this method.
\item \verb{delete_agent_pool(poolname, confirm=TRUE. wait=FALSE)}: Deletes an agent pool.
\item \code{list_cluster_resources()}: Returns a list of all the Azure resources managed by the cluster.
\item \code{update_aad_password(name=NULL, duration=NULL, ...)}: Update the password for Azure Active Directory integration, returning the new password invisibly. See 'Updating credentials' below.
\item \code{update_service_password(name=NULL, duration=NULL, ...)}: Update the password for the service principal used to manage the cluster resources, returning the new password invisibly.  See 'Updating credentials' below.
}
}

\section{Details}{

Initializing a new object of this class can either retrieve an existing AKS resource, or create a new resource on the host. Generally, the best way to initialize an object is via the \code{get_aks}, \code{create_aks} or \code{list_aks} methods of the \link[AzureRMR:az_resource_group]{AzureRMR::az_resource_group} class, which handle the details automatically.

Note that this class is separate from the Kubernetes cluster itself. This class exposes methods for working with the Azure resource: updating resource tags, updating and deleting the resource (including updating the Kubernetes version), and so on.

For working with the cluster, including deploying images, services, etc use the object generated with the \code{get_cluster} method. This method takes two optional arguments:
\itemize{
\item \code{config}: The file in which to store the cluster configuration details. By default, this will be located in the AzureR configuration directory if it exists (see \link[AzureAuth:AzureR_dir]{AzureAuth::AzureR_dir}); otherwise, in the R temporary directory. To use the Kubernetes default \verb{~/.kube/config} file, set this argument to NULL. Any existing file in the given location will be overwritten.
\item \code{role}: This can be \code{"User"} (the default) or \code{"Admin"}.
}
}

\section{Updating credentials}{

An AKS resource can have up to three service principals associated with it. Two of these are for Azure Active Directory (AAD) integration. The third is used to manage the subsidiary resources (VMs, networks, disks, etc) used by the cluster, if it doesn't have a service identity.

Any service principals used by the AKS resource will have secret passwords, which have to be refreshed as they expire. The \code{update_aad_password()} and \code{update_service_password()} methods let you refresh the passwords for the cluster's service principals. Their arguments are:
\itemize{
\item \code{name}: An optional friendly name for the password.
\item \code{duration}: The duration for which the new password is valid. Defaults to 2 years.
\item \code{...}: Other arguments passed to \code{AzureGraph::create_graph_login}. Note that these are used to authenticate with Microsoft Graph, which does the actual work of updating the service principals, not to the cluster itself.
}
}

\examples{
\dontrun{

rg <- AzureRMR::get_azure_login()$
    get_subscription("subscription_id")$
    get_resource_group("rgname")

myaks <- rg$get_aks("mycluster")

# sync with Azure: AKS resource creation can take a long time, use this to track status
myaks$sync_fields()

# get the cluster endpoint
kubclus <- myaks$get_cluster()

# list of agent pools
myaks$list_agent_pools()

# create a new agent pool, then delete it
pool <- myaks$create_agent_pool("pool2", 3, size="Standard_DS3_v2")
pool$delete()

# refresh the service principal password (mostly for legacy clusters without a managed identity)
myaks$update_service_password()

# refresh the service principal password, using custom credentials to authenticate with MS Graph
# arguments here are for Graph, not AKS!
myaks$update_service_password(app="app_id", password="app_password")

}
}
\seealso{
\link{create_aks}, \link{get_aks}, \link{delete_aks}, \link{list_aks}, \link[AzureAuth:AzureR_dir]{AzureAuth::AzureR_dir}, \link[AzureGraph:graph_login]{AzureGraph::create_graph_login}

\link{kubernetes_cluster} for interacting with the cluster endpoint

\href{https://learn.microsoft.com/en-us/azure/aks/}{AKS documentation} and
\href{https://learn.microsoft.com/en-us/rest/api/aks/}{API reference}
}
