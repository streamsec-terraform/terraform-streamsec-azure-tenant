mock_data "streamsec_host" {
  defaults = { url = "https://acme.streamsec.io" }
}

mock_data "streamsec_azure_volume_scanner" {
  defaults = { collection_token = "collection-token" }
}
