PORT ?= 10083
PROCFILE ?= Procfile.dev

.PHONY: start

start:
	@bundle exec rails db:prepare
	@if command -v overmind >/dev/null 2>&1; then \
		PORT=$(PORT) overmind start -f $(PROCFILE); \
	elif command -v foreman >/dev/null 2>&1; then \
		PORT=$(PORT) foreman start -f $(PROCFILE); \
	else \
		echo "Install overmind or foreman to run $(PROCFILE)" >&2; \
		exit 1; \
	fi
