# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python2_7 )
USE_RUBY="ruby20 ruby21 ruby22 ruby24"

inherit autotools check-reqs flag-o-matic gnome2 pax-utils python-any-r1 ruby-single toolchain-funcs virtualx

MY_P="webkitgtk-${PV}"
DESCRIPTION="Open source web browser engine"
HOMEPAGE="http://www.webkitgtk.org/"
SRC_URI="http://www.webkitgtk.org/releases/${MY_P}.tar.xz"

LICENSE="LGPL-2+ BSD"
SLOT="3/25" # soname version of libwebkit2gtk-3.0
KEYWORDS="~alpha amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~x86-macos"

IUSE="aqua coverage debug +egl +geolocation gles2 gnome-keyring +gstreamer +introspection +jit +opengl spell wayland +webgl +X"
# bugs 372493, 416331
REQUIRED_USE="
	geolocation? ( introspection )
	gles2? ( egl )
	introspection? ( gstreamer )
	webgl? ( ^^ ( gles2 opengl ) )
	!webgl? ( ?? ( gles2 opengl ) )
	|| ( aqua wayland X )
"

# use sqlite, svg by default
# Aqua support in gtk3 is untested
# gtk2 is needed for plugin process support
# gtk3-3.10 required for wayland
# gtk3-3.20 is needed to ensure we get fixed theming:
# https://bugzilla.gnome.org/show_bug.cgi?id=757503
RDEPEND="
	dev-db/sqlite:3=
	>=dev-libs/glib-2.36:2
	>=dev-libs/icu-3.8.1-r1:=
	>=dev-libs/libxml2-2.6:2
	>=dev-libs/libxslt-1.1.7
	>=media-libs/fontconfig-2.5:1.0
	>=media-libs/freetype-2.4.2:2
	>=media-libs/harfbuzz-0.9.7:=[icu(+)]
	>=media-libs/libpng-1.4:0=
	media-libs/libwebp:=
	>=net-libs/libsoup-2.42:2.4[introspection?]
	virtual/jpeg:0=
	>=x11-libs/cairo-1.10:=[X?]
	>=x11-libs/gtk+-3.20.0:3[X?,aqua?,introspection?]
	>=x11-libs/pango-1.30.0

	>=x11-libs/gtk+-2.24.10:2

	egl? ( media-libs/mesa[egl] )
	geolocation? ( >=app-misc/geoclue-2.1.5:2.0 )
	gles2? ( media-libs/mesa[gles2] )
	gnome-keyring? ( app-crypt/libsecret )
	gstreamer? (
		>=media-libs/gstreamer-1.2:1.0
		>=media-libs/gst-plugins-base-1.2:1.0 )
	introspection? ( >=dev-libs/gobject-introspection-1.32.0:= )
	opengl? ( virtual/opengl )
	spell? ( >=app-text/enchant-0.22:= )
	wayland? ( >=x11-libs/gtk+-3.10:3[wayland] )
	webgl? (
		x11-libs/cairo[opengl]
		x11-libs/libXcomposite
		x11-libs/libXdamage )
	X? (
		x11-libs/libX11
		x11-libs/libXrender
		x11-libs/libXt )
"

# paxctl needed for bug #407085
# Need real bison, not yacc
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	${RUBY_DEPS}
	>=dev-lang/perl-5.10
	>=app-accessibility/at-spi2-core-2.5.3
	>=dev-libs/atk-2.8.0
	>=dev-util/gtk-doc-am-1.10
	>=dev-util/gperf-3.0.1
	>=sys-devel/bison-2.4.3
	>=sys-devel/flex-2.5.34
	|| ( >=sys-devel/gcc-4.7 >=sys-devel/clang-3.3 )
	sys-devel/gettext
	>=sys-devel/make-3.82-r4
	virtual/pkgconfig

	geolocation? ( dev-util/gdbus-codegen )
	introspection? ( jit? ( sys-apps/paxctl ) )
	test? (
		dev-lang/python:2.7
		dev-python/pygobject:3[python_targets_python2_7]
		x11-themes/hicolor-icon-theme
		jit? ( sys-apps/paxctl ) )
"

S="${WORKDIR}/${MY_P}"

CHECKREQS_DISK_BUILD="18G" # and even this might not be enough, bug #417307

pkg_pretend() {
	if [[ ${MERGE_TYPE} != "binary" ]] && is-flagq "-g*" && ! is-flagq "-g*0" ; then
		einfo "Checking for sufficient disk space to build ${PN} with debugging CFLAGS"
		check-reqs_pkg_pretend
	fi

	if [[ ${MERGE_TYPE} != "binary" ]] && ! test-flag-CXX -std=c++11; then
		die "You need at least GCC 4.7.x or Clang >= 3.3 for C++11-specific compiler flags"
	fi
}

pkg_setup() {
	# Check whether any of the debugging flags is enabled
	if [[ ${MERGE_TYPE} != "binary" ]] && is-flagq "-g*" && ! is-flagq "-g*0" ; then
		if is-flagq "-ggdb" && [[ ${WEBKIT_GTK_GGDB} != "yes" ]]; then
			replace-flags -ggdb -g
			ewarn "Replacing \"-ggdb\" with \"-g\" in your CFLAGS."
			ewarn "Building ${PN} with \"-ggdb\" produces binaries which are too"
			ewarn "large for current binutils releases (bug #432784) and has very"
			ewarn "high temporary build space and memory requirements."
			ewarn "If you really want to build ${PN} with \"-ggdb\", add"
			ewarn "WEBKIT_GTK_GGDB=yes"
			ewarn "to your make.conf file."
		fi
		einfo "You need to have at least 18GB of temporary build space available"
		einfo "to build ${PN} with debugging CFLAGS. Note that it might still"
		einfo "not be enough, as the total space requirements depend on the flags"
		einfo "(-ggdb vs -g1) and enabled features."
		check-reqs_pkg_setup
	fi

	[[ ${MERGE_TYPE} = "binary" ]] || python-any-r1_pkg_setup
}

src_prepare() {
	# intermediate MacPorts hack while upstream bug is not fixed properly
	# https://bugs.webkit.org/show_bug.cgi?id=28727
	use aqua && eapply "${FILESDIR}"/${PN}-1.6.1-darwin-quartz.patch

	# Leave optimization level to user CFLAGS
	# FORTIFY_SOURCE is enabled by default in Gentoo
	sed -e 's/-O[012]//g' \
		-e 's/-D_FORTIFY_SOURCE=2//g' \
		-i Source/autotools/SetupCompilerFlags.m4 || die

	# bug #459978, upstream bug #113397
	eapply "${FILESDIR}"/${PN}-1.11.90-gtk-docize-fix.patch

	# Debian patches to fix support for some arches
	# https://bugs.webkit.org/show_bug.cgi?id=129540
	eapply "${FILESDIR}"/${PN}-2.2.5-{hppa,ia64}-platform.patch
	# https://bugs.webkit.org/show_bug.cgi?id=129542
	eapply "${FILESDIR}"/${PN}-2.4.1-ia64-malloc.patch

	# Fix building on ppc (from OpenBSD, only needed on slot 3)
	# https://bugs.webkit.org/show_bug.cgi?id=130837
	eapply "${FILESDIR}"/${PN}-2.4.4-atomic-ppc.patch

	# Fix build with recent libjpeg, bug #481688
	# https://bugs.webkit.org/show_bug.cgi?id=122412
	eapply "${FILESDIR}"/${PN}-2.4.4-jpeg-9a.patch

	# Fix building with --disable-webgl, bug #500966
	# https://bugs.webkit.org/show_bug.cgi?id=131267
	eapply "${FILESDIR}"/${PN}-2.4.7-disable-webgl.patch

	# https://bugs.webkit.org/show_bug.cgi?id=156510
	eapply "${FILESDIR}"/${PN}-2.4.11-video-web-audio.patch

	# https://bugs.webkit.org/show_bug.cgi?id=159124#c1
	eapply "${FILESDIR}"/${PN}-2.4.9-gcc-6.patch

	AT_M4DIR=Source/autotools eautoreconf

	gnome2_src_prepare
}

src_configure() {
	#GCC 6.4 NULL pointer optiimization fix
	append-cxxflags $(test-flags-CXX -fno-delete-null-pointer-checks)
	# Respect CC, otherwise fails on prefix #395875
	tc-export CC

	# Arches without JIT support also need this to really disable it in all places
	use jit || append-cppflags -DENABLE_JIT=0 -DENABLE_YARR_JIT=0 -DENABLE_ASSEMBLER=0

	# It does not compile on alpha without this in LDFLAGS
	# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=648761
	use alpha && append-ldflags "-Wl,--no-relax"

	# Sigbuses on SPARC with mcpu and co., bug #???
	use sparc && filter-flags "-mvis"

	# https://bugs.webkit.org/show_bug.cgi?id=42070 , #301634
	use ppc64 && append-flags "-mminimal-toc"

	# Try to use less memory, bug #469942 (see Fedora .spec for reference)
	# --no-keep-memory doesn't work on ia64, bug #502492
	if ! use ia64; then
		append-ldflags "-Wl,--no-keep-memory"
	fi
	if ! $(tc-getLD) --version | grep -q "GNU gold"; then
		append-ldflags "-Wl,--reduce-memory-overheads"
	fi

	local ruby_interpreter=""

	if has_version "virtual/rubygems[ruby_targets_ruby24]"; then
		ruby_interpreter="RUBY=$(type -P ruby24)"
	elif has_version "virtual/rubygems[ruby_targets_ruby22]"; then
		ruby_interpreter="RUBY=$(type -P ruby22)"
	elif has_version "virtual/rubygems[ruby_targets_ruby21]"; then
		ruby_interpreter="RUBY=$(type -P ruby21)"
	else
		ruby_interpreter="RUBY=$(type -P ruby20)"
	fi

	# TODO: Check Web Audio support
	# should somehow let user select between them?
	#
	# * Aqua support in gtk3 is untested
	# * dependency-tracking is required so parallel builds won't fail
	gnome2_src_configure \
		$(use_enable aqua quartz-target) \
		$(use_enable coverage) \
		$(use_enable debug) \
		$(use_enable egl) \
		$(use_enable geolocation) \
		$(use_enable gles2) \
		$(use_enable gnome-keyring credential_storage) \
		$(use_enable gstreamer video) \
		$(use_enable gstreamer web-audio) \
		$(use_enable introspection) \
		$(use_enable jit) \
		$(use_enable opengl glx) \
		$(use_enable spell spellcheck) \
		$(use_enable webgl) \
		$(use_enable webgl accelerated-compositing) \
		$(use_enable wayland wayland-target) \
		$(use_enable X x11-target) \
		--with-gtk=3.0 \
		--enable-dependency-tracking \
		--disable-gtk-doc \
		${ruby_interpreter}
}

src_test() {
	# Tests expect an out-of-source build in WebKitBuild
	ln -s . WebKitBuild || die "ln failed"

	# Prevents test failures on PaX systems
	use jit && pax-mark m $(list-paxables Programs/*[Tt]ests/*) # Programs/unittests/.libs/test*

	# Tests need virtualx, bug #294691, bug #310695
	# Parallel tests sometimes fail
	virtx emake -j1 check
}

src_install() {
	DOCS="ChangeLog NEWS" # other ChangeLog files handled by src_install

	# https://bugs.webkit.org/show_bug.cgi?id=129242
	MAKEOPTS="${MAKEOPTS} -j1" gnome2_src_install

	newdoc Source/WebKit/gtk/ChangeLog ChangeLog.gtk
	newdoc Source/JavaScriptCore/ChangeLog ChangeLog.JavaScriptCore
	newdoc Source/WebCore/ChangeLog ChangeLog.WebCore

	# Prevents crashes on PaX systems, bug #522808
	use jit && pax-mark m "${ED}usr/bin/jsc-3" "${ED}usr/libexec/WebKitWebProcess"
	pax-mark m "${ED}usr/libexec/WebKitPluginProcess"
}
