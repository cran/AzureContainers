#' Azure Container Registry class
#'
#' Class representing an Azure Container Registry (ACR) resource. For working with the registry endpoint itself, including uploading and downloading images etc, see [docker_registry].
#'
#' @docType class
#' @section Methods:
#' The following methods are available, in addition to those provided by the [AzureRMR::az_resource] class:
#' - `new(...)`: Initialize a new ACR object. See 'Details'.
#' - `add_role_assignment(principal, role, scope=NULL, ...)`: Adds a role for the specified principal. This is an override mainly to handle AKS objects, so that the Kubernetes cluster can be granted access to the registry. You can use the `...` arguments to supply authentication details for AzureGraph, which is used to retrieve the cluster service principal.
#' - `list_credentials`: Return the username and passwords for this registry. Only valid if the Admin user for the registry has been enabled.
#' - `list_policies`: Return the policies for this registry.
#' - `list_usages`: Return the usage for this registry.
#' - `get_docker_registry(username, password)`: Return an object representing the Docker registry endpoint.
#'
#' @section Details:
#' Initializing a new object of this class can either retrieve an existing registry resource, or create a new registry on the host. Generally, the best way to initialize an object is via the `get_acr`, `create_acr` or `list_acrs` methods of the [AzureRMR::az_resource_group] class, which handle the details automatically.
#'
#' Note that this class is separate from the Docker registry itself. This class exposes methods for working with the Azure resource: listing credentials, updating resource tags, updating and deleting the resource, and so on.
#'
#' For working with the registry, including uploading and downloading images, updating tags, deleting layers and images etc, use the endpoint object generated with `get_docker_registry`. This method takes two optional arguments:
#'
#' - `username`: The username that Docker will use to authenticate with the registry.
#' - `password`: The password that Docker will use to authenticate with the registry.
#'
#' By default, these arguments will be retrieved from the ACR resource. They will only exist if the resource was created with `admin_user_enabled=TRUE`. Currently AzureContainers does not support authentication methods other than a username/password combination.
#'
#' @seealso
#' [create_acr], [get_acr], [delete_acr], [list_acrs]
#'
#' [docker_registry] for interacting with the Docker registry endpoint
#'
#' [Azure Container Registry](https://learn.microsoft.com/en-us/azure/container-registry/) and
#' [API reference](https://learn.microsoft.com/en-us/rest/api/containerregistry/registries)
#'
#' @examples
#' \dontrun{
#'
#' rg <- AzureRMR::get_azure_login()$
#'     get_subscription("subscription_id")$
#'     get_resource_group("rgname")
#'
#' myacr <- rg$get_acr("myregistry")
#'
#' myacr$list_credentials()
#' myacr$list_policies()
#'
#' # see who has push and pull access
#' myacr$list_role_assignments()
#'
#' # grant a Kubernetes cluster pull access
#' myaks <- rg$get_aks("myaks")
#' myacr$add_role_assignment(myaks, "Acrpull")
#'
#' # get the registry endpoint (for interactive use)
#' myacr$get_docker_registry()
#'
#' # get the registry endpoint (admin user account)
#' myacr$get_docker_registry(as_admin=TRUE)
#'
#' }
#' @aliases az_container_registry
#' @export
acr <- R6::R6Class("az_container_registry", inherit=AzureRMR::az_resource,

public=list(

    add_role_assignment=function(principal, role, scope=NULL, ...)
    {
        if(is_aks(principal))
        {
            clientid <- principal$properties$servicePrincipalProfile$clientId
            if(clientid == "msi")
            {
                ident <- principal$properties$identityProfile
                principal <- ident[[1]]$objectId
            }
            else
            {
                tenant <- self$token$tenant
                principal <- graph_login(tenant, ...)$get_app(clientid)

            }
        }
        super$add_role_assignment(principal, role, scope)
    },

    list_credentials=function()
    {
        if(!self$properties$adminUserEnabled)
            stop("Admin user account is disabled", call.=FALSE)

        creds <- private$res_op("listCredentials", http_verb="POST")
        pwds <- sapply(creds$passwords, `[[`, "value")
        names(pwds) <- sapply(creds$passwords, `[[`, "name")
        list(username=creds$username, passwords=pwds)
    },

    list_policies=function()
    {
        private$res_op("listPolicies")
    },

    list_usages=function()
    {
        use <- private$res_op("listUsages")$value
        do.call(rbind, lapply(use, as.data.frame))
    },

    get_docker_registry=function(..., as_admin=FALSE, token=self$token)
    {
        server <- paste0("https://", self$properties$loginServer)
        if(as_admin)
        {
            creds <- self$list_credentials()
            docker_registry(server, username=creds$username, password=creds$passwords[1], app=NULL)
        }
        else docker_registry(server, ..., token=token)
    }
))
