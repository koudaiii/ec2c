NAME := ec2c
VERSION := v0.1.1
REVISION := $(shell git rev-parse --short HEAD)

LDFLAGS := -ldflags="-s -w -X \"main.Version=$(VERSION)\" -X \"main.Revision=$(REVISION)\""

DIST_DIRS := find * -type d -exec

DOCKER_REPOSITORY := quay.io
DOCKER_IMAGE_NAME := $(DOCKER_REPOSITORY)/dtan4/ec2c
DOCKER_IMAGE_TAG ?= latest
DOCKER_IMAGE := $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

.DEFAULT_GOAL := bin/$(NAME)

bin/$(NAME): deps
	go build $(LDFLAGS) -o bin/$(NAME)

.PHONY: ci-docker-release
ci-docker-release: docker-build
	@docker login -e="$(DOCKER_QUAY_EMAIL)" -u="$(DOCKER_QUAY_USERNAME)" -p="$(DOCKER_QUAY_PASSWORD)" $(DOCKER_REPOSITORY)
	docker push $(DOCKER_IMAGE)

.PHONY: clean
clean:
	rm -rf bin/*
	rm -rf dist/*
	rm -rf vendor/*

.PHONY: cross-build
cross-build: deps
	for os in darwin linux windows; do \
		for arch in amd64 386; do \
			GOOS=$$os GOARCH=$$arch go build $(LDFLAGS) -o dist/$$os-$$arch/$(NAME); \
		done; \
	done

.PHONY: deps
deps: glide
	glide install

.PHONY: dist
dist:
	cd dist && \
	$(DIST_DIRS) cp ../LICENSE {} \; && \
	$(DIST_DIRS) cp ../README.md {} \; && \
	$(DIST_DIRS) tar -zcf $(NAME)-$(VERSION)-{}.tar.gz {} \; && \
	$(DIST_DIRS) zip -r $(NAME)-$(VERSION)-{}.zip {} \; && \
	cd ..

.PHONY: docker-build
docker-build:
ifeq ($(findstring ELF 64-bit LSB,$(shell file bin/$(NAME) 2> /dev/null)),)
	@echo "bin/$(NAME) is not a binary of Linux 64bit binary."
	@exit 1
endif
	docker build -t $(DOCKER_IMAGE) .

.PHONY: docker-push
docker-push:
	docker push $(DOCKER_IMAGE)

.PHONY: glide
glide:
ifeq ($(shell command -v glide 2> /dev/null),)
	curl https://glide.sh/get | sh
endif

.PHONY: install
install: deps
	go install $(LDFLAGS)

.PHONY: test
test: deps
	go test -v
