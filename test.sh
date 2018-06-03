#!/usr/bin/env bash

./check_bitcoin_price.rb -n bitcoin -f EUR -w 1000 -c 500 -b
./check_bsto_series.rb -n Mr-Robot -s 3 -w 1 -c 2 -l de
./check_bsto_series.rb -n Mr-Robot -s 40 -w 1 -c 2 -l de
./check_file_type.rb -f ./not_found -r ASCIX -i
./check_file_type.rb -f ./test.sh -r ASCII
./check_file_type.rb -f ./test.sh -r ASCIX
./check_gem_release.rb -n redcarpet -w 3.4.1 -c 3.5.0
./check_github_release.rb -n TheFox/nagios-plugins -w 1.0 -c 1.1
./check_git_commit_age.rb -r git@github.com:ansible/ansible.git -d tmp/ansible -w 1d -c 2d
./check_imdb.rb -t tt0203259 -s
./check_imdb.rb -t tt4158110 -s
