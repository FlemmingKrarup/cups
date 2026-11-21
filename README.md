# CUPS Print Server (Docker)

A Docker image that runs a [CUPS](https://openprinting.github.io/cups/) print server, built from the OpenPrinting CUPS source on top of `debian:stable-slim`. It comes preloaded with a broad set of printer drivers and has network discovery (Avahi/Bonjour) and the web admin interface enabled out of the box, so you can share printers across your network (including to AirPrint-capable clients) with a single container.

## Features

- **CUPS 2.4.20**, compiled from the official OpenPrinting source release
- **Web interface** on port `631`, listening on all interfaces
- **Network discovery** via Avahi (mDNS/DNS-SD on `5353/udp`) with browsing enabled
- **Wide driver coverage**, including:
  - `printer-driver-all`, `foo2zjs`, Foomatic / OpenPrinting PPDs
  - HP drivers (`hplip`, `hpijs-ppds`, `hp-ppd`)
  - Samsung ULD drivers (`suld-driver2`) from the SULDR repository
  - `printer-driver-cups-pdf` for printing to PDF
- **Persistent volumes** for configuration, service definitions and generated PDFs
- Timezone preset to `Europe/Copenhagen`

## Quick start

Build the image:

```bash
git clone https://github.com/FlemmingKrarup/cups.git
cd cups
docker build -t cups .
```

Run it:

```bash
docker run -d \
  --name cups \
  --restart unless-stopped \
  --net host \
  --device /dev/bus/usb \
  -e CUPSADMIN=admin \
  -e CUPSPASSWORD=change-me \
  -v $(pwd)/config:/config \
  -v $(pwd)/services:/services \
  -v $(pwd)/PDF:/PDF \
  cups
```

Then open <http://localhost:631> and manage printers under **Administration**.

### Docker Compose

```yaml
services:
  cups:
    build: .
    container_name: cups
    restart: unless-stopped
    network_mode: host        # needed for mDNS/Bonjour discovery
    devices:
      - /dev/bus/usb:/dev/bus/usb   # only needed for USB printers
    environment:
      - CUPSADMIN=admin
      - CUPSPASSWORD=change-me
      - TZ=Europe/Copenhagen
    volumes:
      - ./config:/config
      - ./services:/services
      - ./PDF:/PDF
```

> **Tip:** Host networking is the simplest way to make printer discovery and AirPrint advertising work. If you use bridge networking instead, publish `631/tcp` and `5353/udp` and expect to add printers manually.

## Configuration

### Environment variables

| Variable       | Default              | Description                                  |
| -------------- | -------------------- | -------------------------------------------- |
| `CUPSADMIN`    | `admin`              | Username for the CUPS admin interface        |
| `CUPSPASSWORD` | `password`           | Password for the admin user                  |
| `TZ`           | `Europe/Copenhagen`  | Container timezone                           |
| `CUPS_VERSION` | `2.4.20`             | CUPS release to compile (**build-time** arg) |

### Volumes

| Path        | Purpose                                      |
| ----------- | -------------------------------------------- |
| `/config`   | CUPS configuration (printers, `cupsd.conf`)  |
| `/services` | Avahi service definitions                    |
| `/PDF`      | Output location for the CUPS-PDF printer     |

### Ports

| Port       | Protocol | Purpose                         |
| ---------- | -------- | ------------------------------- |
| `631`      | TCP      | CUPS web interface / IPP        |
| `5353`     | UDP      | mDNS / Bonjour discovery        |

## Default CUPS settings

The image patches `cupsd.conf` at build time so that the server is usable from other machines on your network:

- Listens on `0.0.0.0:631` instead of `localhost` only
- `IdleExitTimeout` disabled so the daemon keeps running
- Printer browsing enabled
- Remote access allowed to `/` and the admin locations (admin still requires a system-group user)
- `ServerAlias *` set, so the server answers to any hostname
- `DefaultEncryption Never` (plain HTTP)
- Avahi's D-Bus integration disabled (`enable-dbus=no`)

## Security notes

This image is designed for a **trusted home or lab network**. Before exposing it anywhere else:

- **Change the default credentials.** The defaults are `admin` / `password`.
- Encryption is disabled and the admin interface is reachable from any host. Do not expose port `631` to the internet, and consider firewalling it to your LAN.
- Restrict access further by editing `cupsd.conf` if you need to.

## Adding a printer

1. Open <http://localhost:631/admin> and log in with `CUPSADMIN` / `CUPSPASSWORD`.
2. Choose **Add Printer** and pick a detected network or USB printer.
3. Select a driver (a driverless/IPP Everywhere option is best for modern printers; otherwise choose a matching PPD from the bundled drivers).
4. Tick **Share This Printer** so other devices can see it.

## Repository layout

| Path                | Description                                          |
| ------------------- | ---------------------------------------------------- |
| `Dockerfile`        | Image definition (CUPS build, drivers, config tweaks) |
| `root/`             | Scripts copied into the image (e.g. `run_cups.sh`)   |
| `entrypoint.sh`     | Alternate entrypoint (currently commented out in the Dockerfile) |
| `.github/workflows` | CI workflow(s)                                       |
| `LICENSE`           | GPL-3.0                                              |

## Updating CUPS

Bump the `CUPS_VERSION` value in the `Dockerfile` (or pass `--build-arg`/edit the `ENV`) to a release available at
<https://github.com/OpenPrinting/cups/releases>, then rebuild.

## License

Released under the [GNU General Public License v3.0](LICENSE).

CUPS itself is developed by [OpenPrinting](https://github.com/OpenPrinting/cups) under the Apache License 2.0.
