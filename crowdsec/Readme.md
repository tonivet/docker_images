# CrowdSec Integration with Traefik

This guide describes how to integrate **CrowdSec** with **Traefik** using the CrowdSec Traefik Bouncer plugin and CrowdSec AppSec.

## 1. Components and versions

| Component | Version |
|---|---|
| Traefik | 3.7.19 |
| CrowdSec | 1.8.2 |
| CrowdSec Traefik Bouncer Plugin | 1.8.1 |

The integration provides several layers of protection:

- **CrowdSec Log Analysis:** Detects suspicious activity by analyzing Traefik access logs.
- **Traefik Bouncer Plugin:** Applies CrowdSec decisions and blocks malicious IP addresses.
- **CrowdSec AppSec:** Inspects HTTP requests in real time and detects malicious requests.
- **CrowdSec Community Blocklist:** Receives threat intelligence and block decisions from CrowdSec Central API (CAPI).

---

## 2. Docker Compose configuration

Both Traefik and CrowdSec must be connected to a shared Docker network.

Example:

```yaml
networks:
  frontend:
    external: true
```

Make sure both services are attached to this network.

### CrowdSec environment variables

Add the following environment variables to the CrowdSec service:

```yaml
environment:
  COLLECTIONS: "crowdsecurity/traefik crowdsecurity/appsec-virtual-patching crowdsecurity/appsec-generic-rules"
  APPSEC_CONFIGS: "crowdsecurity/appsec-default crowdsecurity/generic-rules crowdsecurity/virtual-patching"
```

`COLLECTIONS` installs the required CrowdSec collections.

`APPSEC_CONFIGS` installs the AppSec configurations used by the AppSec engine.

---

## 3. Create the CrowdSec acquisition directory

CrowdSec uses acquisition configuration files to determine which logs and sources it should monitor.

Create the `acquis.d` directory inside the CrowdSec configuration directory:

```bash
mkdir -p ./crowdsec/config/acquis.d
```

The directory structure should look like this:

```text
crowdsec/
└── config/
    ├── acquis.d/
    │   ├── appsec.yaml
    │   └── traefik.yaml
    ├── appsec-configs/
    ├── appsec-rules/
    └── ...
```

The example assumes that `./crowdsec/config` is mounted as `/etc/crowdsec` inside the CrowdSec container.

### 3.1. Create `appsec.yaml`

Create:

`./crowdsec/config/acquis.d/appsec.yaml`

```yaml
source: appsec
appsec_configs:
  - crowdsecurity/appsec-default
labels:
  type: appsec
listen_addr: 0.0.0.0:7422
```

This configuration:

- Enables the CrowdSec AppSec acquisition source.
- Loads the default AppSec configuration.
- Identifies the source as `appsec`.
- Starts the AppSec HTTP inspection service on port `7422`.

The AppSec service must be reachable from the Traefik container through the shared Docker network.

### 3.2. Create `traefik.yaml`

Create:

`./crowdsec/config/acquis.d/traefik.yaml`

```yaml
filenames:
  - /var/log/traefik/access.log
labels:
  type: traefik
```

This configuration tells CrowdSec to read Traefik access logs.

**Important:** The path `/var/log/traefik/access.log` is an example. It must match the actual access log path inside the CrowdSec container.

Make sure the Traefik access log directory or file is mounted into the CrowdSec container as a read-only volume.

For example:

```yaml
volumes:
  - ./traefik/logs:/var/log/traefik:ro
```

Also make sure Traefik has access logging enabled and writes to the corresponding file:

```yaml
accessLog:
  filePath: /var/log/traefik/access.log
  format: json
```

Adjust both paths to match your actual Docker Compose volume configuration.

---

## 4. Enable the Traefik plugin

In the Traefik static configuration (`traefik.yaml`), enable the experimental plugin:

```yaml
experimental:
  plugins:
    bouncer:
      moduleName: github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin
      version: v1.8.1
```

### Configure the file provider

Make sure the file provider is enabled:

```yaml
providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: frontend

  file:
    filename: /etc/traefik/config.yml
```

The file provider is used to define the CrowdSec middleware.

---

## 5. Configure CrowdSec middleware

Create or edit `/etc/traefik/config.yml`.

Example:

```yaml
http:
  middlewares:
    crowdsec-bouncer:
      plugin:
        bouncer:
          enabled: true
          crowdsecLapiHost: crowdsec:8080
          crowdsecLapiKey: "YOUR_LAPI_BOUNCER_API_KEY"

    crowdsec-appsec:
      plugin:
        bouncer:
          enabled: true
          crowdsecAppsecEnabled: true
          crowdsecAppsecHost: crowdsec:7422
          crowdsecAppsecKey: "YOUR_APPSEC_API_KEY"
          crowdsecAppsecFailureBlock: false
          crowdsecAppsecUnreachableBlock: false
```

Replace the API key placeholders with the corresponding keys generated for your installation.

**Important:**
- Do not commit API keys to a public Git repository.
- Keep the LAPI and AppSec endpoints accessible only through trusted Docker networks.
- `crowdsecAppsecFailureBlock: false` and `crowdsecAppsecUnreachableBlock: false` configure fail-open behavior.
- Verify option names against the documentation for the installed plugin version.

---

## 6. Attach the middleware to Traefik routers

Add the CrowdSec middlewares to the routers that should be protected.

Example Docker labels:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.nextcloud.middlewares=nextcloud-dav,nextcloud-header,crowdsec-bouncer@docker,crowdsec-appsec@file"
```

The CrowdSec bouncer applies IP-based decisions, while AppSec inspects HTTP requests.

You can attach the middleware to individual routers or define a reusable middleware chain.

---

## 7. CrowdSec Community Blocklist

CrowdSec can receive threat intelligence and block decisions from CrowdSec Central API.

Check the CAPI status:

```bash
docker exec crowdsec cscli capi status
```

Expected output should include:

```text
You can successfully interact with Central API (CAPI)
Sharing signals is enabled
Pulling community blocklist is enabled
Pulling blocklists from the console is enabled
```

Check received decisions:

```bash
docker exec crowdsec cscli decisions list -a
```

Community decisions should have:

```text
Source: CAPI
Action: ban
```

These decisions are available to the configured bouncer.

---

## 8. Verify the installation

### Check installed collections

```bash
docker exec crowdsec cscli collections list
```

Expected collections include:

```text
crowdsecurity/traefik
crowdsecurity/appsec-generic-rules
crowdsecurity/appsec-virtual-patching
```

### Check AppSec configurations

```bash
docker exec crowdsec cscli appsec-configs list
```

Expected configurations:

```text
crowdsecurity/appsec-default
crowdsecurity/generic-rules
crowdsecurity/virtual-patching
```

### Check acquisition configuration

```bash
docker exec crowdsec cscli metrics show acquisition
```

Verify that both Traefik and AppSec sources are active.

### Check AppSec metrics

```bash
docker exec crowdsec cscli metrics show appsec
```

This displays processed requests, blocked requests and triggered AppSec rules.

### Check bouncers

```bash
docker exec crowdsec cscli bouncers list
```

The Traefik bouncer should appear as registered and valid.

### Check active decisions

```bash
docker exec crowdsec cscli decisions list
```

To inspect decisions for a particular IP:

```bash
docker exec crowdsec cscli decisions list --ip 1.2.3.4
```

### Inspect alerts

```bash
docker exec crowdsec cscli alerts list
```

Inspect a specific alert:

```bash
docker exec crowdsec cscli alerts inspect ALERT_ID
```

---

## 9. Security recommendations

1. Do not expose CrowdSec LAPI port `8080` or AppSec port `7422` directly to the Internet.
2. Use separate API keys for the LAPI bouncer and AppSec where supported by the installed plugin version.
3. Keep CrowdSec, Traefik and the bouncer plugin updated.
4. Keep Traefik access logging enabled so CrowdSec can analyze incoming requests.
5. Monitor AppSec metrics and CrowdSec alerts regularly.
6. Protect API keys and configuration files containing credentials.
7. Test configuration changes before restarting production services.
8. Consider the impact of fail-open and fail-closed settings before changing AppSec failure behavior.

---

## 10. Useful references

- CrowdSec documentation: https://docs.crowdsec.net/
- CrowdSec Hub: https://app.crowdsec.net/hub/
- CrowdSec Traefik Bouncer Plugin: https://github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin
- Traefik documentation: https://doc.traefik.io/traefik/

---

**Result:** Traefik is protected by CrowdSec IP-based decisions, AppSec HTTP inspection, local detection scenarios and CrowdSec Community Blocklist intelligence.