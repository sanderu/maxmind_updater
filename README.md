# maxmind_updater
Keep local maxmind database up to date

Maxmind GeoLite2 database files gets updated continously (every Tuesday).


Scripts takes one argument (pretty selfexplanatory):

cc = City/Country

asn = ASN

all = ASN/City/Country


Crontab entry (examples):

If you only want to update City/Country DB every Tuesday of the month:

0  15   *   *   2   /bin/bash /path/to/update_maxmind.sh cc


Update all DBs every Tuesday:

30  15  *   *   2   /bin/bash /path/to/update_maxmind.sh all


## REGISTRATION NEEDED!
Due to GDPR/CCPA MaxMind changed their EULA as per December 30th 2019 requiring

you to register at their website to be able to download the databases.

Registration is free.

You will have to generate a license key to use within the script:

Account -> Services -> My License Key -> Generate Key

