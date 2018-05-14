#!/usr/bin/env bash

./check_imdb.rb -t tt0203259 -s
./check_imdb.rb -t tt4158110 -s

./check_bsto_series.rb -n Mr-Robot -s 3 -w 1 -c 2 -l de
./check_bsto_series.rb -n Mr-Robot -s 40 -w 1 -c 2 -l de
