# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

inherit eutils versionator unpacker


DESCRIPTION="Клиент 1C:Проедприятие 8.3 для GNU\LINUX"
HOMEPAGE="http://v8.1c.ru"

MY_PV="$(replace_version_separator 3 '-' )"
MY_PN="1c-enterprise83-client"
SRC_URI="abi_x86_64? ( ${MY_PN}_${MY_PV}_amd64.tar.gz )"


LICENSE="1CEnterprise_en"
KEYWORDS="amd64"
RESTRICT="fetch"

SLOT="0"

IUSE="nls"

RDEPEND="=app-office/1c-enterprise83-common-${PV}:${SLOT}
	=app-office/1c-enterprise83-server-${PV}:${SLOT}
	>=dev-libs/icu-4.6
	net-libs/webkit-gtk-linuxbuh-bin:3
	app-crypt/mit-krb5
	media-gfx/imagemagick
	net-print/cups
	x11-libs/libSM
	dev-libs/atk
	x11-libs/libXxf86vm
	>=sys-libs/e2fsprogs-libs-1.41
	>=x11-libs/cairo-1.0
	sys-libs/glibc:2.2
	>=sys-devel/gcc-3.4
	x11-libs/gtk+:2
	x11-libs/gdk-pixbuf:2
	dev-libs/glib:2
	net-libs/libsoup:2.4
	sys-libs/zlib
	>=dev-util/google-perftools-2.4
	app-office/linuxbuh-1c-installer"

DEPEND="${RDEPEND}"

S="${WORKDIR}"

pkg_nofetch() {
    einfo "Внимание !!!"
    einfo "Установите пакет linuxbuh-1c-installer"
    einfo "Скачайте дистрибутив платформы 1С:Предприятие 8.3 с помощью программы linuxbuh-1c-get-platform-client-gentoo и установите."
}

src_install() {
	cp -R "${WORKDIR}/opt" "${D}" || die "install failed!"
	cp -R "${WORKDIR}/usr" "${D}" || die "install failed!"

}

pkg_postinst() {

rm /usr/lib/libicui18n.so.63
rm /usr/lib/libicuuc.so.63
rm /usr/lib64/libicui18n.so.63
rm /usr/lib64/libicuuc.so.63

ln -s /usr/lib/libicui18n.so.65 /usr/lib/libicui18n.so.63
ln -s /usr/lib/libicuuc.so.65 /usr/lib/libicuuc.so.63
ln -s /usr/lib64/libicui18n.so.65 /usr/lib64/libicui18n.so.63
ln -s /usr/lib64/libicuuc.so.65 /usr/lib64/libicuuc.so.63

}

