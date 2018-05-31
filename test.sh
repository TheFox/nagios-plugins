#!/usr/bin/env bash

./check_imdb.rb -t tt0203259 -s
./check_imdb.rb -t tt4158110 -s

./check_bsto_series.rb -n Mr-Robot -s 3 -w 1 -c 2 -l de
./check_bsto_series.rb -n Mr-Robot -s 40 -w 1 -c 2 -l de

./check_file_type.rb -f ./test.sh -r ASCII
./check_file_type.rb -f ./test.sh -r ASCIX
./check_file_type.rb -f ./not_found -r ASCIX -i

./check_git_commit_age.rb -r git@github.com:ansible/ansible.git -d /tmp/ansible -w 86400 -c 172800
