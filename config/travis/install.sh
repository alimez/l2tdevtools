#!/bin/bash
#
# Script to set up Travis-CI test VM.

L2TBINARIES_DEPENDENCIES="";

L2TBINARIES_TEST_DEPENDENCIES="funcsigs mock pbr six";

DPKG_PYTHON2_DEPENDENCIES="";

DPKG_PYTHON2_TEST_DEPENDENCIES="python-coverage python-funcsigs python-mock python-pbr python-six tox";

DPKG_PYTHON3_DEPENDENCIES="";

DPKG_PYTHON3_TEST_DEPENDENCIES="python3-mock python3-pbr python3-setuptools python3-six tox";

RPM_PYTHON2_DEPENDENCIES="";

RPM_PYTHON2_TEST_DEPENDENCIES="python2-funcsigs python2-mock python2-pbr python2-six";

RPM_PYTHON3_DEPENDENCIES="";

RPM_PYTHON3_TEST_DEPENDENCIES="python3-mock python3-pbr python3-six";

# Exit on error.
set -e;

if test ${TRAVIS_OS_NAME} = "osx";
then
	git clone https://github.com/log2timeline/l2tbinaries.git -b dev;

	mv l2tbinaries ../;

	for PACKAGE in ${L2TBINARIES_DEPENDENCIES};
	do
		echo "Installing: ${PACKAGE}";
		sudo /usr/bin/hdiutil attach ../l2tbinaries/macos/${PACKAGE}-*.dmg;
		sudo /usr/sbin/installer -target / -pkg /Volumes/${PACKAGE}-*.pkg/${PACKAGE}-*.pkg;
		sudo /usr/bin/hdiutil detach /Volumes/${PACKAGE}-*.pkg
	done

	for PACKAGE in ${L2TBINARIES_TEST_DEPENDENCIES};
	do
		echo "Installing: ${PACKAGE}";
		sudo /usr/bin/hdiutil attach ../l2tbinaries/macos/${PACKAGE}-*.dmg;
		sudo /usr/sbin/installer -target / -pkg /Volumes/${PACKAGE}-*.pkg/${PACKAGE}-*.pkg;
		sudo /usr/bin/hdiutil detach /Volumes/${PACKAGE}-*.pkg
	done

elif test -n "${FEDORA_VERSION}";
then
	CONTAINER_NAME="fedora${FEDORA_VERSION}";

	docker pull registry.fedoraproject.org/fedora:${FEDORA_VERSION};

	docker run --name=${CONTAINER_NAME} --detach -i registry.fedoraproject.org/fedora:${FEDORA_VERSION};

	docker exec ${CONTAINER_NAME} dnf install -y dnf-plugins-core;

	docker exec ${CONTAINER_NAME} dnf copr -y enable @gift/dev;

	if test ${TRAVIS_PYTHON_VERSION} = "2.7";
	then
		docker exec ${CONTAINER_NAME} dnf install -y git python2 ${RPM_PYTHON2_DEPENDENCIES} ${RPM_PYTHON2_TEST_DEPENDENCIES};
	else
		docker exec ${CONTAINER_NAME} dnf install -y git python3 ${RPM_PYTHON3_DEPENDENCIES} ${RPM_PYTHON3_TEST_DEPENDENCIES};
	fi

elif test ${TRAVIS_OS_NAME} = "linux" && test ${TARGET} != "jenkins";
then
	sudo rm -f /etc/apt/sources.list.d/travis_ci_zeromq3-source.list;

	if test ${TARGET} = "pylint";
	then
		sudo add-apt-repository ppa:gift/pylint3 -y;
	fi

	sudo add-apt-repository ppa:gift/dev -y;
	sudo apt-get update -q;

	if test ${TRAVIS_PYTHON_VERSION} = "2.7";
	then
		sudo apt-get install -y ${DPKG_PYTHON2_DEPENDENCIES} ${DPKG_PYTHON2_TEST_DEPENDENCIES};
	else
		sudo apt-get install -y ${DPKG_PYTHON3_DEPENDENCIES} ${DPKG_PYTHON3_TEST_DEPENDENCIES};
	fi
	if test ${TARGET} = "pylint";
	then
		sudo apt-get install -y pylint;
	fi
fi
