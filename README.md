
DISCLAIMER - ABANDONED/UNMAINTAINED CODE / DO NOT USE
=======================================================
While this repository has been inactive for some time, this formal notice, issued on **December 10, 2024**, serves as the official declaration to clarify the situation. Consequently, this repository and all associated resources (including related projects, code, documentation, and distributed packages such as Docker images, PyPI packages, etc.) are now explicitly declared **unmaintained** and **abandoned**.

I would like to remind everyone that this project’s free license has always been based on the principle that the software is provided "AS-IS", without any warranty or expectation of liability or maintenance from the maintainer.
As such, it is used solely at the user's own risk, with no warranty or liability from the maintainer, including but not limited to any damages arising from its use.

Due to the enactment of the Cyber Resilience Act (EU Regulation 2024/2847), which significantly alters the regulatory framework, including penalties of up to €15M, combined with its demands for **unpaid** and **indefinite** liability, it has become untenable for me to continue maintaining all my Open Source Projects as a natural person.
The new regulations impose personal liability risks and create an unacceptable burden, regardless of my personal situation now or in the future, particularly when the work is done voluntarily and without compensation.

**No further technical support, updates (including security patches), or maintenance, of any kind, will be provided.**

These resources may remain online, but solely for public archiving, documentation, and educational purposes.

Users are strongly advised not to use these resources in any active or production-related projects, and to seek alternative solutions that comply with the new legal requirements (EU CRA).

**Using these resources outside of these contexts is strictly prohibited and is done at your own risk.**

This project has been transfered to Makina Corpus <freesoftware-corpus.com> ( https://makina-corpus.com ). This project and its associated resources, including published resources related to this project (e.g., from PyPI, Docker Hub, GitHub, etc.), may be removed starting **March 15, 2025**, especially if the CRA’s risks remain disproportionate.

# playbooks for helping managing bluemind infrastructure

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
