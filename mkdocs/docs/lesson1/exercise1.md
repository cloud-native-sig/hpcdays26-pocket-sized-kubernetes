# Exercise 1 — Connecting to Your Nodes

Each table has a note with:

* Raspberry Pi IP addresses
* SSH login credentials
* WiFi credentials for the workshop router

You will also need to connect your laptop to our Router - `TP-Link_AP_2A5A_01`

!!! Warning
    While connected to the workshop router, your laptop will lose internet access. You might want to have [kubectl](https://kubernetes.io/docs/tasks/tools/) installed locally before connecting to the router.

## Verify SSH Access

Once you have connected to the router, as a group you should confirm you can
connect to each node:

```bash
ssh chef@192.168.x.xxx
hostname
exit
```

## Recommended: Configure Host Aliases

For convenience, you may want to add IP-hostname pairs to
`/etc/hosts/` on your own device:

```text
192.168.x.xxx    kmaster
192.168.x.yyy    kworker1
```

Then, you can simply `ssh <username>@kmaster` etc. instead of having to remember each IP address, as we do below.
Alternatively, configure SSH aliases in `~/.ssh/config`, e.g.

```text
Host kworker1
    HostName 192.168.x.yyy
    User chef
    IdentityFile ~/.ssh/id_ed25519
```

Then connect to the desired now with `ssh kworker1`

## Optional: Configure SSH Keys

To avoid repeatedly entering passwords you can setup SSH keys to make login more streamlined:

```bash
ssh-keygen -t ed25519
ssh-copy-id chef@kmaster
```

Repeat for each node if desired.

## Verify Node Interconnectivity

Check the worker nodes are reachable *from the control node:*

```bash
ssh chef@kmaster
ping -c3 192.168.x.yyy
```

## *Troubleshooting*

The Pis should be configured static IPs through our router's DHCP settings.
However, if a node is unreachable we will need to:

* Check the node is powered on
* Verify the IP address
* Confirm `sshd` is running
* Check a static IP has been configured using `nmcli` or `nmtui`.

If needed, ask one of the course facilitators to help by connecting the Raspberry Pi to a display and keyboard for debugging
