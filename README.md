# dnsproxy-systemd
A systemd service for [AdguardTeam/dnsproxy](https://github.com/AdguardTeam/dnsproxy) to provide DNS.

Especially for Ubuntu, it can run alongside systemd-resolved.

The **adguard-dnsproxy-setup.service** uses an argument of **`linux-amd64`** in its `ExecStart` line.

Refer to assets in [AdguardTeam/dnsproxy Releases](https://github.com/AdguardTeam/dnsproxy/releases) for other OS architectures.

> Examples:
>
> - `linux-386` for i386 / x86
> - `linux-arm64` for aarch64 / arm64
> - `linux-arm6` for armv6l / armhf

## Install

After cloning this repository, run the command below to download and start up this DNS proxy server.

```shell
make
```

Using `sudo` is optional since the Makefile already checks for admin access.

Admin access is need to be permitted to bind IP addresses for listening.

> If you want to run the exact targets, run **`make install start`**.

> If you are not in the **`dnsproxy-systemd`** git folder, you may run **`make -C dnsproxy-systemd`** if you have cloned into the current directory.

### Requirement(s)

**Python** is needed for the helper script, _dnsproxy-helper.py_, to work.

#### Using YAML in Python

Python lacks built-in support for the YAML data format.

The helper script checks for either the **`PyYAML`** or **`ruamel.yaml`** Python package.

> Usually, **PyYAML** is already installed.
>
> **ruamel.yaml** will be preferred by the helper script.
>
> No need to install both packages.
>
> The file is not explicit about which version of YAML it is.

- **PyYAML** (YAML 1.1 support)

  - Package on Debian based distros, e.g. Ubuntu

    **`python3-yaml`**

  - Package on RPM based distros, e.g. Fedora

    **`python3-pyyaml`**

  - Package on pacman based distros, e.g. Arch Linux

    **`python-yaml`**

- **ruamel.yaml** (YAML 1.2 support)

  - Package on Debian based distros, e.g. Ubuntu
  
    **`python3-ruamel.yaml`**
  
  - Package on RPM based distros, e.g. Fedora
  
    **`python3-ruamel-yaml`**
  
  - Package on pacman based distros, e.g. Arch Linux
  
    **`python-ruamel-yaml`**

### Customization

The Makefile has 2 variables to customize, BINDIR and CONFDIR.

```shell
make BINDIR=/opt/adguard CONFDIR=/etc/adguard
```

If you change their values, be sure the chosen directory is _root-owned_.

Due to certain _file conflicts_, `/etc` and `/usr/sbin` are some of the directories not allowed.

## `dnsproxy.yml` file
Refer to the options in [Adguard/dnsproxy main.go](https://github.com/AdguardTeam/dnsproxy/blob/master/main.go) for yaml configuration.

The **`listen-addrs`** option is required.

Make sure any IP addresses in this option are not already used on port 53.

Check for IP address on port 53 with this command.

```shell
sudo lsof -Pni:53
```

> This command will need `sudo` privileges.

## UDP Receive Buffer Size

Linux and BSD may encounter errors for any QUIC or UDP transfers, especially DNS over QUIC.

This is solved by setting the maximum buffer size to a high enough level.

It can be done by using `sysctl -w` or permanently to `/etc/sysctl.conf` as shown below.

### Linux

```shell
sudo sh -c 'echo "net.core.rmem_max=26214400" >> /etc/sysctl.conf'
```

### BSD

```shell
sudo sh -c 'echo "kern.ipc.maxsockbuf=30146560" >> /etc/sysctl.conf'
```

[UDP Receive Buffer Size · lucas-clemente/quic-go Wiki](https://github.com/lucas-clemente/quic-go/wiki/UDP-Receive-Buffer-Size)
