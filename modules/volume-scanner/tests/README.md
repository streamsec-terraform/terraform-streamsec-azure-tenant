# volume-scanner tests

```bash
terraform test
```

Mock providers throughout, no Azure or Stream Security API calls. Requires Terraform >= 1.7 for `mock_provider`, stricter than the module's own `required_version` of 1.3.
