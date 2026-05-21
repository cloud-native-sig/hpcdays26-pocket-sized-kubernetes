# Exercise 1 — Connecting to Your Nodes

Each table has a note with:

* Raspberry Pi IP addresses
* SSH login credentials
* WiFi credentials for the workshop router

You will also need to connect to our Router - `TP-Link_AP_2A5A_01`

> While connected to the workshop router, your laptop will lose internet access. You might want to have [kubectl](https://kubernetes.io/docs/tasks/tools/) installed locally before connecting to the router.

## Verify SSH Access

Once you have connected to the router, as a group, you will need to confirm you can connect to each node:

```bash
ssh chef@192.168.x.xxx
hostname
exit
```

## Test Node Connectivity

From the control node, verify worker nodes are reachable:

```bash
ssh chef@kmaster
ping -c3 192.168.x.yyy
```

## Optional: Configure Host Aliases

For convenience, you may want to add IP-hostname pairs to
`/etc/hosts/` on your own device:

```text
192.168.x.xxx    kmaster
192.168.x.yyy    kworker1
```

Then you can simply `ssh <username>@kmaster` etc. instead of having
to remember all the IP addresses.

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

## Optional: Troubleshooting

We should have configured static IPs through our router's DHCP settings.
But, if a node is unreachable we will need to:

* Verify the IP address
* Check the node is powered on
* Confirm `sshd` is running
* Configured a static IPs using `nmcli` or `nmtui`.

If needed, ask one of the course facilitators to help by connecting the Raspberry Pi to a display and keyboard for debugging