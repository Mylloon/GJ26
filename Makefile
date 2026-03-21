all:


setup-git-hooks:
	mkdir -p .git/hooks
	cp githooks/pre-commit .git/hooks

format-gdfiles:
	gdformat $(wildcard **/*.gd)
