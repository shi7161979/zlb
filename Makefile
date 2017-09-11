# Copyright (c) 2015-2017, ANT-FINANCE CORPORATION. All rights reserved.

SHELL = /bin/bash

TARGET  = zlb
VERSION = $(shell cat VERSION)
GITCOMMIT = $(shell git log -1 --pretty=format:%h)
BUILD_TIME = $(shell date --rfc-3339 ns 2>/dev/null | sed -e 's/ /T/')

IMAGE_NAME = registry.cn-hangzhou.aliyuncs.com/zanecloud/zlb

image:
	docker build -t ${IMAGE_NAME} .
	docker tag ${IMAGE_NAME} ${IMAGE_NAME}:${VERSION}-${GITCOMMIT}
	docker tag ${IMAGE_NAME} ${IMAGE_NAME}:${VERSION}

run:	 
	docker run -it --rm  --net="host" -d  zlb
release:
	docker tag ${IMAGE_NAME}:${VERSION}-${GITCOMMIT} ${IMAGE_NAME}:${VERSION}
	docker tag ${IMAGE_NAME}:${VERSION}-${GITCOMMIT} ${IMAGE_NAME}
	docker push ${IMAGE_NAME}:${VERSION}-${GITCOMMIT}
	docker push ${IMAGE_NAME}:${VERSION}
	docker push ${IMAGE_NAME}

.PHONY: image release
