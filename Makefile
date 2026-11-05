SALAM ?= $(shell command -v salam 2>/dev/null || echo $(HOME)/.salam/bin/salam)
SALAM_STD ?= $(HOME)/.salam/bin/std
BACKEND ?= c
OUT ?= build

export SALAM_STD

.PHONY: all build check test examples format format-check clean serve-site

all: check test

build:
	mkdir -p $(OUT)
	$(SALAM) build main.salam --output=$(OUT)/argon-demo --backend=$(BACKEND)

check:
	mkdir -p $(OUT)
	$(SALAM) build main.salam --output=$(OUT)/argon-check --backend=$(BACKEND)

test:
	$(SALAM) run tests/argon_test.salam --backend=$(BACKEND)

examples:
	$(SALAM) run examples/basic.salam --backend=$(BACKEND) -- --formal Ada
	$(SALAM) run examples/options.salam --backend=$(BACKEND) -- -i input.txt -f json -w 100 --force
	$(SALAM) run examples/subcommands.salam --backend=$(BACKEND) -- build --release -t wasm
	$(SALAM) run examples/validation.salam --backend=$(BACKEND) -- -n Ada -a 30 -c green

format:
	$(SALAM) format src/argon.salam main.salam examples tests

format-check:
	$(SALAM) format src/argon.salam main.salam examples tests --check

serve-site:
	$(SALAM) serve site --port=8000

clean:
	rm -rf $(OUT)
	rm -f argon_test
