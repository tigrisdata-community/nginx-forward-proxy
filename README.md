# Forward Proxy

This is an installer for a forward proxy that can be used to access the internet if external connectivity is disabled.

## Starting the proxy machine

```bash
fly apps create proxy

fly -a proxy machine run . \
    --name "proxy-0" \
    --vm-size "performance-2x" \
    --region "sjc"
```
