# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

inherit eutils versionator

DESCRIPTION="Configurations Storage component of 1C ERP system"
HOMEPAGE="http://v8.1c.ru/"
DOWNLOADPAGE="http://ftp.linuxbuh.ru/1c83/server"

MY_PV="$(replace_version_separator 3 '-' )"
MY_PN="1c-enterprise83-crs"
SRC_URI="x86? ( $DOWNLOADPAGE/${MY_PN}_${MY_PV}_i386.tar.gz )"

LICENSE="1CEnterprise_en"
KEYWORDS="x86"
RESTRICT="mirror strip"

SLOT=$(get_version_component_range 1-2)


RDEPEND="~app-office/1c-enterprise83-common-${PV}:${SLOT}
	~app-office/1c-enterprise83-server-${PV}:${SLOT}"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_install() {
	dodir /opt
	mv "${WORKDIR}"/opt/* "${D}"/opt
}
