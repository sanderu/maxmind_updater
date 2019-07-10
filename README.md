# maxmind_updater
Keep local maxmind database up to date

Maxmind GeoLite2 database files gets updated continously.
City/Country every first Tuesday of the month.
ASN every Tuesday.

Scripts takes one argument (pretty selfexplanatory):
cc = City/Country
asn = ASN


Crontab entry:
Update City/Country DB every first Tuesday of the month (i.e. day 1-7 and Tuesday):
0  8   1-7 *   2   /bin/bash /path/to/update_maxmind.sh cc

Update ASN DB every Tuesday:
0  8   *   *   2   /bin/bash /path/to/update_maxmind.sh asn

