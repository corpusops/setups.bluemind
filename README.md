# playbooks for helping managing bluemind infrastructure

DISCLAIMER
============

**UNMAINTAINED/ABANDONED CODE / DO NOT USE**

Due to the new EU Cyber Resilience Act (as European Union), even if it was implied because there was no more activity, this repository is now explicitly declared unmaintained.

The content does not meet the new regulatory requirements and therefore cannot be deployed or distributed, especially in a European context.

This repository now remains online ONLY for public archiving, documentation and education purposes and we ask everyone to respect this.

As stated, the maintainers stopped development and therefore all support some time ago, and make this declaration on December 15, 2024.

We may also unpublish soon (as in the following monthes) any published ressources tied to the corpusops project (pypi, dockerhub, ansible-galaxy, the repositories).
So, please don't rely on it after March 15, 2025 and adapt whatever project which used this code.




- roles:
 	- `bluemind/vars`: variables
	- `bluemind/api`: configure un venv avec les binding python dans /srv
	- `bluemind/apt`: configure apt et la souscription
	- `bluemind/aptupgrade`: run aptupgrade
	- `bluemind/break`: breakpoint/pause
	- `bluemind/configure`: configure tout
		- `bluemind/confs`: bluemind conf files
		- `bluemind/crons`: bluemind crons
		- `bluemind/backups`: (de)active dataprotect
			- `bluemind/dataprotect`: dataprotect
		- `bluemind/disable_crons`: stop all crons
		- `bluemind/install`: install packages
		- `bluemind/filters`: install imapfilter crons
		- `bluemind/spamcollect`: install spamcollect cron
		- `bluemind/fixsslconf`: fix openssl.cnf
		- `bluemind/hosts`: add bm hosts to /etc/hosts
		- `bluemind/fw`: configure iptables
		- `bluemind/toggle_es_checks`: (d)enable es checks
		- `bluemind/layout`: files/directory layout
		- `bluemind/token`: load bm.tok as ansible var
	- `bluemind/migrate`:
	- `bluemind/teleport`: teleport data from one lxc to another
		- `bluemind/hardstop`:
		- `bluemind/presync`:
		- `bluemind/restart`: restart bm LXC
	- `bluemind/sync`: teleport bm data from one bm on to another bm host from within that another
	- `bluemind/upgrade`: upgrade bm to latest
	- `bluemind/upgrade4`:
		- `bluemind/reconsolidate`: reconsolidate spools
