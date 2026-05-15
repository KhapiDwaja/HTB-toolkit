# htb-toolkit

> One-shot pentest-tool installer for **Pop!OS / Ubuntu / Debian**, tailored to the HackTheBox Academy modules:
> *Active Directory Enumeration & Attacks · Password Attacks · Attacking Common Services · Pivoting, Tunneling & Port Forwarding* — plus a full red-team loadout on top.
>
> Forked & restructured from [`ericsherlock/pentools-install`](https://github.com/ericsherlock/pentools-install) — original credit to the upstream author. Rebuilt as a modular, idempotent, logged installer with a shell-env file that wires everything into your `.bashrc` / `.zshrc`.

⚠️ **Authorized use only.** Run this on an attack VM you control, used against environments you have written permission to test (HTB labs, your own lab, signed engagements).

---

## What you get

| Module | What it installs |
|---|---|
| `base` | build-essential, git, curl, python3 + pipx, golang, rust, krb5/ldap libs, openvpn |
| `recon` | nmap, masscan, rustscan, dnsrecon, enum4linux-ng, gobuster, ffuf, httpx, naabu, nuclei, subfinder, amass, theharvester, whatweb, wafw00f |
| `active-directory` | **impacket** (GetUserSPNs/secretsdump/ntlmrelayx/psexec/wmiexec/lookupsid/ticketer/raiseChild/smbserver), **netexec** (modern crackmapexec, alias provided), **certipy-ad**, **bloodhound.py** + BloodHound CE (Docker), kerbrute (built from source), windapsearch, ldapdomaindump, adidnsdump, mitm6, pywerview, bloodyAD, evil-winrm, Responder, PetitPotam, PrintNightmare PoC, PKINITtools, Inveigh & Rubeus (source for Windows side), ntlm_theft |
| `password-attacks` | hashcat, john-jumbo (ssh2john, office2john, keepass2john, zip2john, …), hydra, medusa, ncrack, crunch, cewl, hashid, mimipenguin, LaZagne, firefox_decrypt, username-anarchy, patator |
| `common-services` | smbclient/smbmap, snmp-check, onesixtyone, redis-tools, mariadb-client, postgresql-client, mssql-cli, ODAT (Oracle), tftp/ftp clients, swaks (SMTP), sipvicious, ipmitool, freerdp/rdesktop |
| `pivoting` | proxychains4, socat, sshuttle, **chisel** (binary), **ligolo-ng** (binaries), **ptunnel-ng** (built), wireguard-tools, plink |
| `web-app` | burpsuite, zaproxy, sqlmap, nikto, wfuzz, gobuster, feroxbuster, dirsearch, **ffuf**, **katana**, **dalfox**, wpscan, commix, arjun, paramspider, wayback/gau |
| `wireless` | aircrack-ng, reaver, bully, pixiewps, hcxtools, kismet, wifite, bettercap, bluez, macchanger (SDR optional with `INSTALL_SDR=1`) |
| `post-exploit` | metasploit-framework, exploitdb/searchsploit, radare2, gdb, binwalk, apktool, **PEASS-ng (linpeas/winpeas)**, LinEnum, lse, pspy, linux-exploit-suggester, GTFOBins/LOLBAS mirrors, PayloadsAllTheThings (Sliver C2 optional with `INSTALL_C2=1`) |
| `wordlists` | **SecLists** at `/usr/share/seclists` (also symlinked to `/opt/useful/seclists` to match your cheatsheets), rockyou.txt unpacked |

Everything that doesn't come from `apt` lands in **`/opt/htb-toolkit/`**, and a single `env.sh` is sourced from `~/.bashrc` (and `~/.zshrc` if present) to wire the PATH, aliases, and convenience functions.

---

## Quick start

```bash
git clone https://github.com/<your-fork>/htb-toolkit.git
cd htb-toolkit
chmod +x install.sh
sudo ./install.sh             # interactive menu

# or just install everything in one go:
sudo ./install.sh --all --no-confirm
```

Then open a new terminal (or `source ~/.bashrc`) and you're ready:

```bash
htb-info                       # show env state
htb-target 10.10.11.123        # set $RHOST
nxc smb $RHOST -u user -p pass
GetUserSPNs.py -dc-ip $RHOST DOMAIN/user
pyserve 8000                   # quick http server on your tun0 IP
smbserve SHARE .               # quick anonymous smb share
```

---

## Common commands

```bash
sudo ./install.sh --list                                  # show modules
sudo ./install.sh --module active-directory,password-attacks
sudo ./install.sh --dry-run --all                         # see what would happen
sudo ./install.sh --update                                # git-pull every cloned repo
```

Per-module env vars:

```bash
INSTALL_SDR=1 sudo ./install.sh --module wireless         # also install rtl-sdr / gqrx
INSTALL_C2=1  sudo ./install.sh --module post-exploit     # also install Sliver C2
```

---

## Uninstalling — `remove.sh`

A manifest-aware uninstaller. Every install writes to `/opt/htb-toolkit/.manifest`, and `remove.sh` reads it back so it only removes what *this toolkit* put on disk — nothing that was there before.

**Default behavior is a full nuke.** Running with no `--keep-*` flags removes everything: APT packages, pipx packages, `/opt/htb-toolkit`, go binaries, SecLists, env block, and the install log.

**`--yes` is mandatory** to actually delete anything. Without it, the script prints the removal plan and exits without touching the system. There is no interactive y/N prompt — too easy to misclick. If you want to see what will happen, use `--dry-run`.

```bash
# Preview only — prints plan, deletes nothing
sudo ./remove.sh

# Detailed preview with the same "(dry-run)" markers you'd see during real run
sudo ./remove.sh --dry-run

# FULL NUKE — removes EVERYTHING htb-toolkit installed
sudo ./remove.sh --yes

# Partial nuke — keep SecLists (saves 1.5GB redownload) and apt packages
sudo ./remove.sh --yes --keep-wordlists --keep-apt

# Interactive picker — still requires --yes to commit
sudo ./remove.sh --interactive --yes
```

`--keep-*` flags:

| Flag | Spares |
|---|---|
| `--keep-apt` | APT packages |
| `--keep-pipx` | pipx packages |
| `--keep-go` | `~/go/bin` binaries |
| `--keep-tools-dir` | `/opt/htb-toolkit` |
| `--keep-wordlists` | `/usr/share/seclists` + `/opt/useful` |
| `--keep-logs` | install log file |
| `--keep-rc` | env block in `~/.bashrc` / `~/.zshrc` |

The shell rc edit always uses a backup: `~/.bashrc` becomes `~/.bashrc.htb-backup` before the env block is removed, so you can revert by hand if anything goes sideways.

⚠️ `--yes` without any `--keep-*` flags really does remove `metasploit-framework`, `hashcat`, `john`, `nmap`, etc. via `apt-get remove --purge`. If you want those to stay, pass `--keep-apt`.

---

## What gets touched on your system

- **APT packages** — installed normally; uninstall script does **not** remove them (intentional, you may want them anyway)
- **`/opt/htb-toolkit/`** — every git-cloned tool and downloaded binary
- **`/opt/htb-toolkit/bin/`** — symlinks for tools we want on PATH (kerbrute, chisel, ligolo, linpeas, …)
- **`/usr/share/seclists/`** — SecLists (also symlinked at `/opt/useful/seclists/` to match HTB Academy paths)
- **`~/.local/bin/`** — pipx targets land here (impacket scripts, netexec, certipy, …)
- **`~/go/bin/`** — go-installed binaries (ffuf, httpx, nuclei, naabu, gobuster, …)
- **`~/.bashrc` and `~/.zshrc`** — a single sourced block, delimited by `# >>> htb-toolkit >>>` / `# <<< htb-toolkit <<<`
- **`/var/log/htb-toolkit-install.log`** — every command, output, and error

---

## Convenience functions (defined in `config/env.sh`)

| Function | What it does |
|---|---|
| `htb-target <ip>` | `export RHOST=<ip>` for use by other helpers |
| `tun0ip` | print your tun0 IP (HTB VPN) |
| `pyserve [port]` | quick HTTP server on tun0 |
| `smbserve [share] [dir]` | quick anonymous SMB share via impacket |
| `crack-ntlm <hash>` | `hashcat -m 1000 -a 0 <hash> $ROCKYOU` |
| `htb-info` | dump env state |

Aliases provided: `crackmapexec` → `nxc`, `kerbrute`, `chisel`, `ligolo-proxy`, `ligolo-agent`, `ptunnel-ng`, `mimipenguin`, `lazagne`, `firefox_decrypt`, `username-anarchy`, …

---

## Architecture

```
htb-toolkit/
├── install.sh               # entrypoint: CLI, menu, dispatch
├── remove.sh                # manifest-aware uninstaller
├── lib/
│   ├── colors.sh
│   ├── logger.sh
│   └── helpers.sh           # apt_install, pipx_install, git_clone, go_install, link_into_bin (all manifest-aware)
├── modules/
│   ├── 00-base.sh
│   ├── 10-recon.sh
│   ├── 20-active-directory.sh
│   ├── 30-password-attacks.sh
│   ├── 40-common-services.sh
│   ├── 50-pivoting.sh
│   ├── 60-web-app.sh
│   ├── 70-wireless.sh
│   ├── 80-post-exploit.sh
│   └── 90-wordlists.sh
└── config/
    └── env.sh               # sourced from ~/.bashrc and ~/.zshrc
```

At runtime, the installer writes `/opt/htb-toolkit/.manifest` — a tab-separated record of every package/clone/binary/symlink we created. `remove.sh` reads it back to do a clean, surgical uninstall.

Adding a new tool: open the right module file and add one line:

```bash
apt_install bloodhound-ce-python      # apt package
pipx_install impacket                 # python CLI via pipx
git_clone https://github.com/foo/bar  # source clone into /opt/htb-toolkit/bar
go_install github.com/x/y@latest      # go binary into ~/go/bin
```

Helpers are idempotent — they detect already-installed state and skip.

---

## Publishing your own fork

```bash
# 1. Create an empty repo on GitHub (e.g. 'htb-toolkit') — do NOT initialize it.
# 2. From the extracted folder:

cd htb-toolkit
git init -b main
git add .
git commit -m "Initial: htb-toolkit fork of ericsherlock/pentools-install"
git remote add origin https://github.com/<your-username>/htb-toolkit.git
git push -u origin main
```

Tip: since you're forking work from `ericsherlock/pentools-install` (MIT), keep the credit in the README and the LICENSE compatible. The MIT in this README satisfies that.

To install fresh on any Pop!OS box afterwards:

```bash
git clone https://github.com/<your-username>/htb-toolkit.git
cd htb-toolkit && sudo ./install.sh --all --no-confirm
```

---

## Acknowledgements

- Upstream: [ericsherlock/pentools-install](https://github.com/ericsherlock/pentools-install) (MIT)
- Tool descriptions: [Kali Tools](https://www.kali.org/tools/)
- HackTheBox Academy for the cheatsheets that informed the tool selection
- The authors of every tool installed by this repo

## License

MIT (matches upstream).
