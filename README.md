# hpe-raid-zabbix

Monitor HPE Smart Array RAID controllers (via `ssacli`) with Zabbix Agent2 —
no proprietary HPE monitoring agent required.

Tested on:
- HPE Smart Array P408i-a SR Gen10
- Proxmox VE 8.x (Debian 12 bookworm) and 9.x (Debian 13 trixie)
- Zabbix Agent2 7.0 LTS

Should work on any HPE (or Adaptec-based) Smart Array controller on a
Debian-based OS, as long as `ssacli` is installed.

## What this gives you

- An aggregated `OK` / `WARNING` / `CRITICAL` health status item, with
  triggers already wired up
- Raw logical/physical drive status text (for drilling into an alert)
- Controller ASIC temperature
- A `sudo`-based setup so Zabbix Agent2 (running as the unprivileged
  `zabbix` user) can call `ssacli`, which normally requires root

## A note on the sudoers path

`ssacli` is usually installed to `/usr/sbin/ssacli`, **not** `/usr/bin/ssacli`.
If the path in your sudoers rule doesn't exactly match the path actually
invoked by the script or the UserParameters, `sudo` silently falls back to
requiring a password — which fails for the `zabbix` user with no console —
and the item just returns nothing useful. The installer below detects the
real path with `command -v ssacli` and writes it consistently everywhere,
but if you ever move ssacli or install manually, keep this in mind.

## Install

```bash
git clone https://github.com/OH2LAK/hpe-raid-zabbix.git
cd hpe-raid-zabbix
sudo ./install_hpe_raid_monitor.sh
```

The installer will:
1. Locate `ssacli` and detect the controller slot
2. Install `/usr/local/bin/hpe_raid_check.sh`
3. Write `/etc/sudoers.d/zabbix-ssacli` (validated with `visudo -cf` before use)
4. Write `/etc/zabbix/zabbix_agent2.d/hpe_raid.conf`
5. Restart Zabbix Agent2
6. Run a self-test as the `zabbix` user to confirm sudo works end-to-end

## Manual install

If you'd rather not run the installer, copy the pieces yourself:

| File | Destination |
|---|---|
| `scripts/hpe_raid_check.sh` | `/usr/local/bin/hpe_raid_check.sh` (`chmod +x`) |
| `sudoers/zabbix-ssacli` | `/etc/sudoers.d/zabbix-ssacli` (`chmod 440`) |
| `userparameter/hpe_raid.conf` | `/etc/zabbix/zabbix_agent2.d/hpe_raid.conf` |

Then `systemctl restart zabbix-agent2`.

**Before copying manually**, run `which ssacli` and make sure the path
matches in all three files — the manual copies default to `/usr/sbin/ssacli`.

## Zabbix template

Import `templates/hpe_raid_zabbix_template.yaml` under
**Data collection → Templates → Import**, then link it to your host under
**Data collection → Hosts → *host* → Templates**.

> The UUIDs in the shipped YAML were hand-written for portability. If you'd
> rather have Zabbix generate fresh, guaranteed-unique UUIDs, build the
> items manually once in the UI (using the item keys below) and export the
> template yourself — that's the more robust path for a production instance.

### Item keys

| Key | Type | Description |
|---|---|---|
| `hpe.raid.status` | Text | Aggregated OK/WARNING/CRITICAL |
| `hpe.raid.ld.raw` | Text | Raw logical drive status |
| `hpe.raid.pd.raw` | Text | Raw physical drive status |
| `hpe.raid.ctrl.temp` | Float | Controller ASIC temperature (°C) |

## Verifying it works

```bash
su -s /bin/bash zabbix -c "sudo /usr/local/bin/hpe_raid_check.sh"
```

Should print `OK` (or `WARNING: ...` / `CRITICAL: ...`) with no password
prompt. If you get a password prompt or "command not allowed", the ssacli
path in `/etc/sudoers.d/zabbix-ssacli` doesn't match the actual `ssacli`
location — see the note above.

## License

MIT — use it, fork it, improve it.

## Contributing

Issues and PRs welcome, especially for other HPE Smart Array models/slots
or non-Debian distros.
