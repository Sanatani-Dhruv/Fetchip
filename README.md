
# 🛰️ fetchip
Fetch Public IP Addresses of yours and other by Command line

---

`fetchip` is a lightweight and flexible CLI tool to fetch and inspect public IP addresses — yours or any given one — with full support for:

- IPv4 and IPv6
- Detailed geo and ISP info
- Multi-source lookups
- Lookup history logging
- Clean table-style history output

---

## 🚀 Features

- ✅ Fetch your public IPv4/IPv6  
- ✅ Get full IP information (city, country, ISP, etc.)  
- ✅ Compare results across **multiple IP data APIs**  
- ✅ Lookup **any IP address**  
- ✅ Store and view **lookup history**  
- ✅ Simple CLI: `fetchip` from anywhere  
- ✅ Compatible with Linux & macOS  

---

## 📦 Installation

Run this in your terminal (Linux/macOS/Termux):

```
bash <(curl -s https://raw.githubusercontent.com/Sanatani-Dhruv/fetchip/main/install_fetchip.sh)
```

🛠️ The script will install dependencies like `jq`, `curl` if not present when running `fetchip` command.

---

## 💻 Usage

`fetchip [my|<IP>] [-a] [-m]`

#### Command	Description
- `fetchip` Show your public IP (IPv4 or IPv6)
- `fetchip my` Show both IPv4 and IPv6
- `fetchip my -a` Show detailed info from [Multi-Source APIs](#-multi-source-apis-used)
- `fetchip my -a -m`	Show info from multiple sources
- `fetchip <ip>`	Just print the given IP
- `fetchip <ip> -a`	Full info for that IP
- `fetchip <ip> -a -m`	Compare info from multiple APIs
- `fetchip history`	Show history of all lookups
- `fetchip clear`	Clear lookup history (with confirmation prompt)
- `fetchip -h / --help`	Show command reference
- `fetchip update / -u / --update` Update this script



## 🌐 Multi-Source APIs Used
When using the -m flag, fetchip will query multiple free public APIs:

- [api.ipify.org](https://api.ipify.org)
  
- [ipinfo.io](https://ipinfo.io)

- [ip-api.com](https://ip-api.com)

- [ipwho.is](https://ipwho.is)

- [ipapi.co](https://ipapi.co)

This ensures more accurate and redundant location results.

---

## 📜 History Log

All lookups done with `-a` are logged in a local file:

`~/.fetchip_history.log`

#### Use:

`fetchip history`

## Example output:


####📜 Lookup History:

```
Date & Time         IP Address     Location              Organization
------------------  -------------  ---------------------  ------------------
2025-06-22 14:12:45 8.8.8.8        Mountain View, US      Google LLC
2025-06-22 14:13:10 1.1.1.1        Sydney, AU             Cloudflare
```


#### To clear the history:

`fetchip clear`

You'll be prompted for confirmation before deletion.

## 🧼 Uninstall

To remove the tool:


```
rm -f ~/.local/bin/fetchip
rm -f ~/.fetchip_history.log
```


Remove any custom PATH entries from `~/.bashrc`, `~/.zshrc`, or shell config if added manually.



## 📄 License

MIT License

## 👨‍💻 Author
Made by Your Dhruv
- Not a Good Developer
- Copy Paster

> Contributions, pull requests, and ideas are welcome!

### Problems:

- If you Find One, Please let Us Notify!

### 🛠️ Solutions

- If you can find one, you can solve one!🫣
- Help Us Solve it🙂
