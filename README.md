## public-dns-resolvers

Check a list of hosts for TCP or UDP DNS services. Not terribly invasive since each host comes from a public list and only receives two packets (one on UDP/53, one on TCP/53)

## What for eh?

Use this for gathering sample data for analysis related to DNS. Please don't use this for something nefarious, thanks. This will send two TCP SYN packets to each host in the resolver_candidates.lst file.

## Dependencies for Debian/Ubuntu
 
```
 $ sudo apt-get install bind9utils build-essential clang libpcap-dev
 $ git clone https://github.com/robertdavidgraham/masscan
 $ cd masscan
 $ make
 $ sudo make install
 $ sudo setcap CAP_NET_RAW+ep /usr/bin/masscan
```
