GO ?= go
GOFMT ?= gofmt "-s"
PACKAGES ?= $(shell $(GO) list ./...)
VETPACKAGES ?= $(shell $(GO) list ./... | grep -v /examples/)
GOFILES := $(shell find . -name "*.go")

# ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
TESTFOLDER := $(shell $(GO) list ./... | grep -E 'process|model|flow|session|store|fs|http|connector|wasm|v8' | grep -v 'wamr')
TESTTAGS ?= ""

.PHONY: test
test:
	echo "mode: count" > coverage.out
	for d in $(TESTFOLDER); do \
		$(GO) test -tags $(TESTTAGS) -v -covermode=count -coverprofile=profile.out -coverpkg=$$(echo $$d | sed "s/\/test$$//g") $$d > tmp.out; \
		cat tmp.out; \
		if grep -q "^--- FAIL" tmp.out; then \
			rm tmp.out; \
			exit 1; \
		elif grep -q "build failed" tmp.out; then \
			rm tmp.out; \
			exit 1; \
		elif grep -q "setup failed" tmp.out; then \
			rm tmp.out; \
			exit 1; \
		elif grep -q "runtime error" tmp.out; then \
			rm tmp.out; \
			exit 1; \
		fi; \
		if [ -f profile.out ]; then \
			cat profile.out | grep -v "mode:" >> coverage.out; \
			rm profile.out; \
		fi; \
	done

.PHONY: bench
bench:
	for d in $(TESTFOLDER); do \
		$(GO) test -run Benchmark -v -bench=. -benchtime=5s -benchmem $$d; \
	done

.PHONY: fmt
fmt:
	$(GOFMT) -w $(GOFILES)

.PHONY: fmt-check
fmt-check:
	@diff=$$($(GOFMT) -d $(GOFILES)); \
	if [ -n "$$diff" ]; then \
		echo "Please run 'make fmt' and commit the result:"; \
		echo "$${diff}"; \
		exit 1; \
	fi;

vet:
	$(GO) vet $(VETPACKAGES)

.PHONY: lint
lint:
	@hash golint > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u golang.org/x/lint/golint; \
	fi
	for PKG in $(PACKAGES); do golint -set_exit_status $$PKG || exit 1; done;

.PHONY: misspell-check
misspell-check:
	@hash misspell > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/client9/misspell/cmd/misspell; \
	fi
	misspell -error $(GOFILES)

.PHONY: misspell
misspell:
	@hash misspell > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/client9/misspell/cmd/misspell; \
	fi
	misspell -w $(GOFILES)

.PHONY: tools
tools:
	go install golang.org/x/lint/golint@latest; \
	go install github.com/client9/misspell/cmd/misspell@latest;

.PHONY: plugin
plugin: 
	rm -rf $(HOME)/data/gou-unit/plugins
	rm -rf $(HOME)/data/gou-unit/logs
	mkdir -p $(HOME)/data/gou-unit/plugins
	mkdir -p $(HOME)/data/gou-unit/logs
	GOOS=linux GOARCH=amd64 go build -o $(HOME)/data/gou-unit/plugins/user ./app/plugins/user
	chmod +x $(HOME)/data/gou-unit/plugins/user
	ls -l $(HOME)/data/gou-unit/plugins
	ls -l $(HOME)/data/gou-unit/logs
	$(HOME)/data/gou-unit/plugins/user 2>&1 || true
plugin-mac: 
	rm -rf ./app/plugins/user/dist
	go build -o ./app/plugins/dist/user ./app/plugins/user
	chmod +x ./app/plugins/dist/user

.PHONY: migrate
migrate:
	$(GO) test -tags $(TESTTAGS) -run TestModelMigrate$