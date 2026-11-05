SALAM ?= $(shell command -v salam 2>/dev/null || echo $(HOME)/.salam/bin/salam)
SALAM_STD ?= $(HOME)/.salam/bin/std
OUT ?= build

export SALAM_STD

.PHONY: all build check test examples format format-check clean serve-site

all: check test

build:
	mkdir -p $(OUT)
	$(SALAM) build main.salam --output=$(OUT)/argon-demo

check:
	mkdir -p $(OUT)
	$(SALAM) build main.salam --output=$(OUT)/argon-check

test:
	$(SALAM) run tests/argon_test.salam

examples:
	$(SALAM) run examples/basic.salam -- --formal Ada
	$(SALAM) run examples/options.salam -- -i input.txt -f json -w 100 --force
	$(SALAM) run examples/subcommands.salam -- build --release -t wasm
	$(SALAM) run examples/validation.salam -- -n Ada -a 30 -c green

format:
	$(SALAM) format src/argon.salam main.salam examples tests

format-check:
	$(SALAM) format src/argon.salam main.salam examples tests --check

serve-site:
	$(SALAM) serve site --port=8000

clean:
	rm -rf $(OUT)
	rm -f argon_test
