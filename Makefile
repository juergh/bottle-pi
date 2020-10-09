all:

deb:
	dpkg-buildpackage -us -uc

release:
	# Create a new changelog stanza
	tag=$$(git describe --abbrev=0) ; \
	minor=$${tag##*.} ; \
	version=$${tag#v} ; \
	version=$${version%.*}.$$(($${minor} + 1)) ; \
	head=$$(git log --format='%s' -1) ; \
	dch -v "$${version}" "$${head}" ; \
	git log --format='%s' "$${tag}..HEAD~1" | \
	while IFS= read -r subject ; do \
		dch -a "$${subject}" ; \
	done

	# Close the release
	dch -r --distribution unstable ''

	# Commit and tag the release
	source=$$(dpkg-parsechangelog -SSource) ; \
	version=$$(dpkg-parsechangelog -SVersion) ; \
	git commit -s -m "$${source} v$${version}" -- debian/changelog ; \
	git tag -s -m "$${source} v$${version}" "v$${version}"

publish:
	source=$$(dpkg-parsechangelog -SSource) ; \
	version=$$(dpkg-parsechangelog -SVersion) ; \
	deb=$${source}_$${version}_all.deb ; \
	scp "../$${deb}" rpi-master: ; \
	ssh rpi-master "sudo mv $${deb} /var/www/html/debian/pool ; \
	                cd /var/www/html/debian ; \
	                sudo ./update"
