#!/usr/bin/env bash

# if [[ -z "${TEST}" ]]; then
# 	echo "FAILED"
# 	exit 1
# fi

./check_imdb.rb -t tt0203259 -s
./check_imdb.rb -t tt4158110 -s
