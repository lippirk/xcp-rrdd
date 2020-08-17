LIBEXECDIR ?= /opt/xensource/libexec
ETCDIR ?= /etc/xensource

.PHONY: release build install uninstall clean test doc format

release:
	dune build @install --profile=release

build:
	dune build @install

install:
	# rrdd
	install -D _build/install/default/bin/xcp-rrdd $(DESTDIR)$(SBINDIR)/xcp-rrdd
	# transport
	dune install rrd-transport
	install -D _build/install/default/bin/rrdreader $(DESTDIR)$(BINDIR)/rrdreader
	install -D _build/install/default/bin/rrdwriter $(DESTDIR)$(BINDIR)/rrdwriter
	# rrdd-plugin
	dune install rrdd-plugin
	# rrdd-plugins
	install -D -m 755 _build/install/default/bin/xcp-rrdd-iostat $(DESTDIR)$(LIBEXECDIR)/xcp-rrdd-plugins/xcp-rrdd-iostat
	install -D -m 755 _build/install/default/bin/xcp-rrdd-squeezed $(DESTDIR)$(LIBEXECDIR)/xcp-rrdd-plugins/xcp-rrdd-squeezed
	install -D -m 755 _build/install/default/bin/xcp-rrdd-xenpm $(DESTDIR)$(LIBEXECDIR)/xcp-rrdd-plugins/xcp-rrdd-xenpm
	install -D -m 644 bin/plugins/bugtool-plugin/rrdd-plugins.xml $(DESTDIR)$(ETCDIR)/bugtool/xcp-rrdd-plugins.xml
	install -D -m 644 bin/plugins/bugtool-plugin/rrdd-plugins/stuff.xml $(DESTDIR)$(ETCDIR)/bugtool/xcp-rrdd-plugins/stuff.xml
	install -D -m 755 bin/plugins/scripts/sysconfig-rrdd-plugins $(DESTDIR)/etc/sysconfig/xcp-rrdd-plugins
	install -D -m 644 bin/plugins/scripts/logrotate-rrdd-plugins $(DESTDIR)/etc/logrotate.d/xcp-rrdd-plugins

uninstall:
	dune uninstall --libdir=$(OPAM_LIBDIR)
	# rrdd
	rm -f $(DESTDIR)$(SBINDIR)/xcp-rrdd
	# transport
	rm -f $(DESTDIR)$(BINDIR)/rrdreader
	rm -f $(DESTDIR)$(BINDIR)/rrdwriter
	# rrdd-plugins
	rm -f $(DESTDIR)$(LIBEXECDIR)/xcp-rrdd-plugins/xcp-rrdd-iostat
	rm -f $(DESTDIR)$(LIBEXECDIR)/xcp-rrdd-plugins/xcp-rrdd-squeezed
	rm -f $(DESTDIR)$(LIBEXECDIR)/xcp-rrdd-plugins/xcp-rrdd-xenpm
	rm -f $(DESTDIR)$(ETCDIR)/bugtool/xcp-rrdd-plugins.xml
	rm -f $(DESTDIR)$(ETCDIR)/bugtool/xcp-rrdd-plugins/stuff.xml
	rm -f $(DESTDIR)/etc/sysconfig/xcp-rrdd-plugins
	rm -f $(DESTDIR)/etc/logrotate.d/xcp-rrdd-plugins

clean:
	dune clean

test:
	dune runtest --profile=release

# requires odoc
doc:
	dune build @doc --profile=release

gh-pages:
	bash .docgen.sh

format:
	dune build @fmt --auto-promote
