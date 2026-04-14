# HPE Smart Array RAID Monitoring for Zabbix

Installs and configures monitoring for HPE Smart Array RAID controllers using `ssacli` and Zabbix Agent2.

Tested on:
- HPE Smart Array P408i-a SR Gen10
- Proxmox VE 8.x (Debian 12 bookworm)
- Proxmox VE 9.x (Debian 13 trixie)
- Zabbix Agent2 7.0 LTS

Should work on any HPE server with a PQI-based Smart Array controller and a Debian-based OS.

---

## What it does

- Installs the HPE MCP repository and `ssacli`
- Detects the controller slot automatically
- Installs a health check script (`/usr/local/bin/hpe_raid_check.sh`)
- Configures Zabbix Agent2 UserParameters
- Sets up sudoers so the Zabbix agent can run `ssacli` without a password

---

## Requirements

- Debian 12/13 or Proxmox VE 8/9
- Zabbix Agent2 installed and configured
- Root access
- Internet access to download HPE packages

---

## Installation

```bash
wget https://raw.githubusercontent.com/oh2lak/hpe-raid-zabbix/main/install_hpe_raid_monitor.sh
chmod +x install_hpe_raid_monitor.sh
sudo ./install_hpe_raid_monitor.sh
```

The installer will:
1. Check for an HPE controller via `lspci`
2. Add the HPE SDR repository and install `ssacli`
3. Detect the controller slot number
4. Install the health check script
5. Configure Zabbix UserParameters
6. Restart the Zabbix agent
7. Run a self-test

---

## Zabbix template

Import `HPE_RAID_Zabbix_template.yaml` into your Zabbix server:

**Configuration → Templates → Import**

Then link the template to your host:

**Configuration → Hosts → [your host] → Templates → HPE Smart Array RAID**

### Items

| Item | Key | Interval | Description |
|---|---|---|---|
| HPE RAID overall status | `hpe.raid.status` | 5 min | Returns `OK` or `CRITICAL`/`WARNING` with details |
| HPE RAID logical drives | `hpe.raid.ld.raw` | 5 min | Raw logical drive status output |
| HPE RAID physical drives | `hpe.raid.pd.raw` | 5 min | Raw physical drive status output |
| HPE RAID controller temp | `hpe.raid.ctrl.temp` | 10 min | Controller ASIC temperature in °C |

### Triggers

| Trigger | Severity | Condition |
|---|---|---|
| RAID status is not OK | High | `hpe.raid.status` does not match `^OK$` |
| Logical drive failure | Disaster | Output contains `failed` or `degraded` |
| Physical drive failure | High | Output contains `failed` |
| Predictive drive failure | Average | Output contains `predictive failure` |
| Controller temp high | Warning | Temperature > 75°C |
| Controller temp critical | High | Temperature > 85°C |

---

## Manual testing

After installation, test the UserParameters directly:

```bash
zabbix_agent2 -t hpe.raid.status
zabbix_agent2 -t hpe.raid.ld.raw
zabbix_agent2 -t hpe.raid.pd.raw
zabbix_agent2 -t hpe.raid.ctrl.temp
```

Or run the health check script directly:

```bash
/usr/local/bin/hpe_raid_check.sh
```

Expected output when healthy: `OK`

---

## Files installed

| File | Description |
|---|---|
| `/usr/local/bin/hpe_raid_check.sh` | Health check script |
| `/etc/zabbix/zabbix_agent2.d/hpe_raid.conf` | Zabbix UserParameters |
| `/etc/sudoers.d/zabbix-ssacli` | Sudoers rule for Zabbix agent |
| `/etc/apt/sources.list.d/hpe-mcp.list` | HPE MCP repository |
| `/usr/share/keyrings/hpe-mcp.gpg` | HPE GPG keys |

---

## License

MIT

## Author

OH2LAK — [oh2lak.radio](https://oh2lak.radio)
