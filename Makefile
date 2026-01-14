.PHONY: build clean test run

build:
	swift build -c release

test:
	swift test

run:
	swift run

clean:
	swift package clean
	rm -rf .build

xcode:
	open Package.swift
