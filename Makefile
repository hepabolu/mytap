html:
	markdown -F 0x1000 README.md > readme.html
	perl -ne 'BEGIN { $$prev = 0; $$lab = ""; print "<h1>Contents</h1>\n<ul>\n" } if (m{<h([123])\s+id="(?:`([^(]+)(?:[^"]+)|([^"]+))">((<code>[^(]+)?.+?)</h\1>}) { next if $$lab && $$lab eq $$5; $$lab = $$5; if ($$prev) { if ($$1 != $$prev) { print $$1 > $$prev ? $$1 - $$prev > 1 ? "<ul><li><ul>" : "<ul>\n" : $$prev - $$1 > 1 ? "</li></ul></li></ul></li>\n" : "</li></ul></li>\n"; $$prev = $$1; } else { print "</li>\n" } } else { $$prev = $$1; } print qq{<li><a href="#} . ($$2 || $$3) . q{">} . ($$5 ? "$$5()</code>" : $$4) . "</a>" } END { print "</li>\n</ul>\n" }' readme.html > toc.html
	perl -pi -e 'BEGIN { my %seen }; s{(<h[123]\s+id=")`([^(]+)[^"]+}{"$$1$$2" . ($$seen{$$2}++ || "")}ge;' readme.html
