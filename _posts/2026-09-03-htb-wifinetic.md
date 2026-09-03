---
title: "Writeup: Wifinetic on HTB"
layout: blog
categories:
  - write-ups
  - htb
  - wifinetic
---
In today's write-up, I'm covering the HackTheBox machine called 'Wifinetic'.

**DISCLAIMER**: This write-up does not include User/Root flags, nor does it reveal direct information like credentials. That said, following it will guide you to fully owning the target machine.

# Why I Chose It

As the name implies, this box has some WiFi shenanigans which is actually pretty rare for CTFs and similar activities. Therefore, I find that it's an interesting box to cover, despite the fact it's extremely easy and straightforward.

# Reconnaissance

For some reason, an all-ports scan of this machine was taking absurdly long, so I stuck to the 1000 most well-known ports (AKA Nmap's default scan).

Below were the results.

```
Host is up (0.15s latency).
Not shown: 997 closed tcp ports (reset)
PORT   STATE SERVICE
21/tcp open  ftp
22/tcp open  ssh
53/tcp open  domain
```

Digging a bit deeper, we find that the FTP server is `vsFTPd 3.0.3` which isn't immediately exploitable (after a while of checking service versions, you can come to memorize which ones have public CVEs; for instance, version `3.0.3` in this case is merely subsceptible to DoS attacks).

Logging anonymously into FTP was successful, and several files were available to download. It seems like the target company in question is looking to migrate to Debian from OpenWrt.

# Enumeration

The most fruitful file turned out to be `backup-OpenWrt-2023-07-26.tar`, since once its contents were extracted, they revealed a seemingly old or incomplete version of the target system's `/etc/` folder, including a `passwd` file.
Through this file, I was able to identify a user on the system called `netadmin`.

Inside the same folder, there's another directory called `config` which houses a file called `wireless`. Ita contained what seems to be a WiFi password for a corresponding access point.

![[wifi passwords.png|269]]

# Exploitation

Password reuse is a common exploitative vector on HTB machines, so I tried to SSH into the aforementioned `netadmin` user using this same password, and got in!

This netted me the User flag.

# Privilege Escalation

This box is evidently geared towards wireless attacks, so some wireless reconaissance is in order. My first go-to tool for this is `iw`.

`iw dev` reveals a couple interesting interfaces, one of which, `mon0`, can be used to carry out wireless attacks given that it's set to `monitor` mode.

Moreover, through the same output, we can tell our target is the one and only access point at `wlan0` because its `Type` is set to `AP`, meaning it's an access point. The output also reveals its `BSSID`.

With this information, we can consider a WPS PIN attack through a utility such as `reaver`.

When I want to see if a tool is available on a target machine, I usually immediately try to run the binary, such as through `reaver --help` in this case. And indeed, it is accessible.

Below is the command used.

```bash
reaver -i mon0 -b 02:00:00:00:00:00 -v
```

`mon0` is the aforementioned interface able to carry out this attack, `02:00:00:00:00:00` is the `BSSID` of our targeted access point (you can also find this `BSSID` via the `wash` utility provided through `reaver` but it did not work on this machine), and `-v` is for verbose output.

In just a few seconds, I got the password!

![[reaver output.png|489]]

Similar to our initial foothold, I used this password to try and SSH in as the `root` user.

This netted me the Root flag.

And thus, Wifinetic was hacked!

# Additional Notes

A decent amount of other information could've been gathered, like emails, by reading the other files accessible via FTP (you can download all of them via `mget *` by the way).

I don't always cover this extra information given that my CTF write-ups are (typically) centered around the direct path towards finding the flag, as opposed to thoroughly toying with the target. But do take note that if this were to be a real pen-test, you'd enumerate a lot more information about the target, instead of hyper-focusing on a `.txt` file.
