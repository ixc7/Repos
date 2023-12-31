#!/usr/bin/env bash

shfmt --write --indent 2 ./*.sh && bat ./*.sh
