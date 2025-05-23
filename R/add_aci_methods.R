#' Create Azure Container Instance (ACI)
#'
#' Method for the [AzureRMR::az_resource_group] class.
#'
#' @rdname create_aci
#' @name create_aci
#' @aliases create_aci
#' @section Usage:
#' ```
#' create_aci(name, location = self$location,
#'            container = name, image,
#'            registry_creds = list(),
#'            cores = 1, memory = 8,
#'            os = c("Linux", "Windows"),
#'            command = list(), env_vars = list(),
#'            ports = aci_ports(), dns_name = name, public_ip = TRUE,
#'            restart = c("Always", "OnFailure", "Never"), managed_identity = TRUE,
#'            ...)
#' ```
#' @section Arguments:
#' - `name`: The name of the ACI service.
#' - `location`: The location/region in which to create the ACI service. Defaults to this resource group's location.
#' - `container`: The name of the running container.
#' - `image`: The name of the image to run.
#' - `registry_creds`: Docker registry authentication credentials, if the image is stored in a private registry. See 'Details'.
#' - `cores`: The number of CPU cores for the instance.
#' - `memory`: The memory size in GB for the instance.
#' - `os`: The operating system to run in the instance.
#' - `command`: A list of commands to run in the instance. This is similar to the `--entrypoint` commandline argument to `docker run`; see [here](https://learn.microsoft.com/en-us/azure/container-instances/container-instances-start-command) for some examples.
#' - `env_vars`: A list of name-value pairs to set as environment variables in the instance.
#' - `secure_env_vars`: A list of name-value pairs to set as _secure_ environment variables in the instance. The values of these variables are not visible in the container's properties, eg when viewed in the Azure portal or via the CLI.
#' - `ports`: The network ports to open. By default, opens ports 80 and 443. See 'Details'.
#' - `dns_name`: The domain name prefix for the instance. Only takes effect if `public_ip=TRUE`.
#' - `public_ip`: Whether the instance should be publicly accessible.
#' - `restart`: Whether to restart the instance should an event occur.
#' - `managed_identity`: Whether to assign the container instance a managed identity.
#' - `...`: Other named arguments to pass to the [AzureRMR::az_resource] initialization function.
#'
#' @section Details:
#' An ACI resource is a running container hosted in Azure. See the [documentation for the resource](https://learn.microsoft.com/en-us/azure/container-instances/) for more information. Currently ACI only supports a single image in an instance.
#'
#' To supply the registry authentication credentials, the `registry_creds` argument should contain either an [ACR][acr] object, a [docker_registry] object, or the result of a call to the [aci_creds] function.
#'
#' The ports to open should be obtained by calling the [aci_ports] function. This takes a vector of port numbers as well as the protocol (TCP or UDP) for each port.
#'
#' @section Value:
#' An object of class `az_container_instance` representing the instance.
#'
#' @seealso
#' [get_aci], [delete_aci], [list_acis]
#'
#' [az_container_instance]
#'
#' [ACI documentation](https://learn.microsoft.com/en-us/azure/container-instances/) and
#' [API reference](https://learn.microsoft.com/en-us/rest/api/container-instances/)
#'
#' [Docker commandline reference](https://docs.docker.com/engine/reference/commandline/cli/)
#'
#' @examples
#' \dontrun{
#'
#' rg <- AzureRMR::get_azure_login()$
#'     get_subscription("subscription_id")$
#'     get_resource_group("rgname")
#'
#' # get the ACR resource that contains the image
#' myacr <- rg$get_acr("myregistry", as_admin=TRUE)
#'
#' rg$create_aci("mycontainer",
#'     image="myregistry.azurecr.io/myimage:latest",
#'     registry_creds=myacr)
#'
#' }
NULL


#' Get Azure Container Instance (ACI)
#'
#' Method for the [AzureRMR::az_resource_group] class.
#'
#' @rdname get_aci
#' @name get_aci
#' @aliases get_aci list_acis
#'
#' @section Usage:
#' ```
#' get_aci(name)
#' list_acis()
#' ```
#' @section Arguments:
#' - `name`: For `get_aci()`, the name of the container instance resource.
#'
#' @section Details:
#' The `AzureRMR::az_resource_group` class has both `get_aci()` and `list_acis()` methods, while the `AzureRMR::az_subscription` class only has the latter.
#'
#' @section Value:
#' For `get_aci()`, an object of class `az_container_instance` representing the instance resource.
#'
#' For `list_acis()`, a list of such objects.
#'
#' @seealso
#' [create_aci], [delete_aci]
#'
#' [az_container_instance]
#'
#' [ACI documentation](https://learn.microsoft.com/en-us/azure/container-instances/) and
#' [API reference](https://learn.microsoft.com/en-us/rest/api/container-instances/)
#'
#' [Docker commandline reference](https://docs.docker.com/engine/reference/commandline/cli/)
#'
#' @examples
#' \dontrun{
#'
#' rg <- AzureRMR::get_azure_login()$
#'     get_subscription("subscription_id")$
#'     get_resource_group("rgname")
#'
#' rg$get_aci("mycontainer")
#'
#' }
NULL


#' Delete an Azure Container Instance (ACI)
#'
#' Method for the [AzureRMR::az_resource_group] class.
#'
#' @rdname delete_aci
#' @name delete_aci
#' @aliases delete_aci
#'
#' @section Usage:
#' ```
#' delete_aci(name, confirm=TRUE, wait=FALSE)
#' ```
#' @section Arguments:
#' - `name`: The name of the container instance.
#' - `confirm`: Whether to ask for confirmation before deleting.
#' - `wait`: Whether to wait until the deletion is complete.
#'
#' @section Value:
#' NULL on successful deletion.
#'
#' @seealso
#' [create_aci], [get_aci]
#'
#' [az_container_instance]
#'
#' [ACI documentation](https://learn.microsoft.com/en-us/azure/container-instances/) and
#' [API reference](https://learn.microsoft.com/en-us/rest/api/container-instances/)
#'
#' [Docker commandline reference](https://docs.docker.com/engine/reference/commandline/cli/)
#'
#' @examples
#' \dontrun{
#'
#' rg <- AzureRMR::get_azure_login()$
#'     get_subscription("subscription_id")$
#'     get_resource_group("rgname")
#'
#' rg$delete_aci("mycontainer")
#'
#' }
NULL


add_aci_methods <- function()
{
    az_resource_group$set("public", "create_aci", overwrite=TRUE,
    function(name, location=self$location,
             container=name,
             image,
             registry_creds=list(),
             cores=1,
             memory=8,
             os=c("Linux", "Windows"),
             command=list(),
             env_vars=list(),
             secure_env_vars=list(),
             ports=aci_ports(),
             dns_name=name,
             public_ip=TRUE,
             restart=c("Always", "OnFailure", "Never"),
             managed_identity=TRUE,
             ...,
             wait=TRUE)
    {
        as_name_value_pairs <- function(vars, securevars)
        {
            c(
                lapply(seq_along(vars), function(i) list(name=names(vars)[i], value=vars[[i]])),
                lapply(seq_along(securevars), function(i) list(name=names(securevars)[i], secureValue=securevars[[i]]))
            )
        }

        containers <- list(
            name=container,
            properties=list(
                image=image,
                command=I(command),
                environmentVariables=as_name_value_pairs(env_vars, secure_env_vars),
                resources=list(requests=list(cpu=cores, memoryInGB=memory)),
                ports=ports
            )
        )

        props <- list(
            containers=list(containers),
            restartPolicy=match.arg(restart),
            osType=match.arg(os)
        )

        if(!is_empty(registry_creds))
            props$imageRegistryCredentials <- get_aci_credentials_list(registry_creds)
        if(public_ip)
            props$ipAddress <- list(type="public", dnsNameLabel=dns_name, ports=ports)

        identity <- if(managed_identity)
            list(type="systemAssigned")
        else NULL

        AzureContainers::aci$new(self$token, self$subscription, self$name,
            type="Microsoft.containerInstance/containerGroups", name=name, location=location,
            properties=props,
            identity=identity,
            ...,
            wait=wait)
    })

    az_resource_group$set("public", "get_aci", overwrite=TRUE,
    function(name)
    {
        AzureContainers::aci$new(self$token, self$subscription, self$name,
            type="Microsoft.containerInstance/containerGroups", name=name)
    })

    az_resource_group$set("public", "delete_aci", overwrite=TRUE,
    function(name, confirm=TRUE, wait=FALSE)
    {
        self$get_aci(name)$delete(confirm=confirm, wait=wait)
    })

    az_resource_group$set("public", "list_acis", overwrite=TRUE,
    function()
    {
        provider <- "Microsoft.ContainerInstance"
        path <- "containerGroups"
        api_version <- az_subscription$
            new(self$token, self$subscription)$
            get_provider_api_version(provider, path)

        op <- file.path("resourceGroups", self$name, "providers", provider, path)

        cont <- call_azure_rm(self$token, self$subscription, op, api_version=api_version)
        lst <- lapply(cont$value,
            function(parms) AzureContainers::aci$new(self$token, self$subscription, deployed_properties=parms))

        # keep going until paging is complete
        while(!is_empty(cont$nextLink))
        {
            cont <- call_azure_url(self$token, cont$nextLink)
            lst <- lapply(cont$value,
                function(parms) AzureContainers::aci$new(self$token, self$subscription, deployed_properties=parms))
        }
        named_list(lst)
    })

    az_subscription$set("public", "list_acis", overwrite=TRUE,
    function()
    {
        provider <- "Microsoft.ContainerInstance"
        path <- "containerGroups"
        api_version <- self$get_provider_api_version(provider, path)

        op <- file.path("providers", provider, path)

        cont <- call_azure_rm(self$token, self$id, op, api_version=api_version)
        lst <- lapply(cont$value,
            function(parms) AzureContainers::aci$new(self$token, self$id, deployed_properties=parms))

        # keep going until paging is complete
        while(!is_empty(cont$nextLink))
        {
            cont <- call_azure_url(self$token, cont$nextLink)
            lst <- lapply(cont$value,
                function(parms) AzureContainers::aci$new(self$token, self$id, deployed_properties=parms))
        }
        named_list(lst)
    })

}

