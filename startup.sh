#!/bin/bash

bundler exec jekyll build && bash -c 'cd _site && python3 -m http.server --bind 0.0.0.0 4000'