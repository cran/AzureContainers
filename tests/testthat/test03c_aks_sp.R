context("AKS interface with service principal")

tenant <- Sys.getenv("AZ_TEST_TENANT_ID")
app <- Sys.getenv("AZ_TEST_APP_ID")
password <- Sys.getenv("AZ_TEST_PASSWORD")
subscription <- Sys.getenv("AZ_TEST_SUBSCRIPTION")

if(tenant == "" || app == "" || password == "" || subscription == "")
    skip("Tests skipped: ARM credentials not set")

rgname <- make_name(10)
rg <- AzureRMR::az_rm$
    new(tenant=tenant, app=app, password=password)$
    get_subscription(subscription)$
    create_resource_group(rgname, location="australiaeast")

echo <- getOption("azure_containers_tool_echo")
options(azure_containers_tool_echo=FALSE)

test_that("AKS works with service principal",
{
    aksname <- paste0(sample(letters, 10, TRUE), collapse="")
    expect_true(is_aks(rg$create_aks(aksname, agent_pools=agent_pool("pool1", 1), managed_identity=FALSE)))
    aks <- rg$get_aks(aksname)
    expect_true(is_aks(aks))

    expect_message(aks$update_service_password())

    pool1 <- aks$get_agent_pool("pool1")
    expect_is(pool1, "az_agent_pool")

    pools <- aks$list_agent_pools()
    expect_true(is.list(pools) && length(pools) == 1 && all(sapply(pools, inherits, "az_agent_pool")))

    pool2 <- aks$create_agent_pool("pool2", 1, disksize=500, wait=TRUE)
    expect_is(pool2, "az_agent_pool")

    pools <- aks$list_agent_pools()
    expect_true(is.list(pools) && length(pools) == 2 && all(sapply(pools, inherits, "az_agent_pool")))

    expect_message(pool2$delete(confirm=FALSE))

    clus <- aks$get_cluster()
    expect_true(is_kubernetes_cluster(clus))
})


teardown({
    options(azure_containers_tool_echo=echo)
    suppressMessages(rg$delete(confirm=FALSE))
})
