# Makefile for building a container with the scripts in the src directory,
# BLAST+ and the GCP SDK
#
# Author: Christiam Camacho
# Created: Thu Jun 11 13:24:39 2020

SHELL=/bin/bash
.PHONY: all pre-check check clean build publish

IMG?=christiam/blast
VERSION?=2.10.5

all: build check

build: pre-check
	(cd docker && ln -f ../src/*.p[ly] .)
	docker build --build-arg version=${VERSION} -t ${IMG}:${VERSION} docker
	docker tag ${IMG}:${VERSION} ${IMG}:latest
	${RM} docker/*.p[ly]

publish: build
	docker push ${IMG}:${VERSION}
	docker push ${IMG}:latest

clean:
	-docker image rm ${IMG} ${IMG}:${VERSION}
	${RM} docker/*.p[ly]

pre-check:
	perl -c src/update_blastdb.pl 
	python3 -m py_compile src/download-blastdb.py
	./test/t.sh

check:
	docker run --rm ${IMG}:${VERSION} update_blastdb.pl --version
	docker run --rm ${IMG}:${VERSION} download-blastdb.py --help
	test/tdocker.sh ${IMG} ${VERSION}

# Setup timing tests
DB?=swissprot
MOL_TYPE?=prot
setup-timing-tests:
	bin/setup-timing-test.sh ${DB} ${MOL_TYPE} ${IMG} ${VERSION}
	#cp --backup=numbered -v cmds.tab timing.ini ${HOME}/timing/etc

setup-instances:
	bin/setup-instances.sh ${DB} ${MOL_TYPE} ${IMG} ${VERSION}

check-instances:
	bin/check-instances.sh ${IMG} ${VERSION}
