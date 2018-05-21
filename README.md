# Nagios Plugins

A collection of my [Nagios](https://www.nagios.org/) plugins.

## Check Bitcoin Price Nagios Plugin

Script: [check_bitcoin_price.rb](check_bitcoin_price.rb)

A plugin for checking the Bitcoin price.

This plugin lets you check every crypto currency listed on [Coin Market Cap](https://coinmarketcap.com/). It uses the [Ticker (Specific Currency) API](https://coinmarketcap.com/api/) to the get the current price of your favourite crypto currency. You can choose every fiat currency listed on Coin Market Cap.

![](https://img.fox21.at/public/20180501/nagios_btc_s.png)

### Usage

Since this plugin doesn't rely on a specific host you can add it to any existing host. Or you can just create a fake host like example.com.

Here is an example **Commands** configuration:

```
# commands.cfg

define command{
    command_name    check_bitcoin_price_above
    command_line    $USER1$/check_bitcoin_price.rb --coin $ARG1$ --fiat $ARG2$ -w $ARG3$ -c $ARG4$
}

define command{
    command_name    check_bitcoin_price_below
    command_line    $USER1$/check_bitcoin_price.rb --coin $ARG1$ --fiat $ARG2$ -w $ARG3$ -c $ARG4$ --below
}
```

Here is an example **Host** configuration:

```
# fake.cfg

define host{
    use                     generic-host
    host_name               fake
    alias                   FAKE
    address                 www.example.com
}

define service{
    use                             generic-service
    host_name                       fake
    service_description             BTC Above
    check_command                   check_bitcoin_price_above!bitcoin!EUR!6800!7000
}

define service{
    use                             generic-service
    host_name                       fake
    service_description             ETH Below
    check_command                   check_bitcoin_price_below!ethereum!EUR!400!320
}
```

## Check Burning Series Nagios Plugin

Script: [check_bsto_series.rb](check_bsto_series.rb)

There is this site called [Burning Series](https://bs.to) where you can watch and download TV series for free. The default language for new episodes is English. But the target language is German. They only offer English and German.

This plugin let you set a notifcation about new episodes on Burning Series for each series they host.

![](https://img.fox21.at/public/20180422/nagios_s.png)

### Usage

Since this plugin doesn't rely on a specific host you can add it to any existing host. Or you can just create a fake host like example.com.

Here is an example **Commands** configuration:

```
# commands.cfg

define command{
	command_name	check_bsto_series
	command_line	$USER1$/check_bsto_series.rb --series "$ARG1$" --season $ARG2$ -w $ARG3$ -c $ARG4$ --lang $ARG5$
}
```

Here is an example **Host** configuration:

```
# fake.cfg

define host{
    use                     generic-host
    host_name               fake
    alias                   FAKE
    address                 www.example.com
}

define service{
    use                             generic-service
    host_name                       fake
    service_description             Family Guy
    check_command                   check_bsto_series!Family-Guy!15!19!20!de
}
```

## Check Twitter Followers Nagios Plugin

Script: [check_twitter_followers.rb](check_twitter_followers.rb)

This script checks the Twitter Followers of any given user.

It has 3 different operation modes.

1. Check Twitter Followers Above
2. Check Twitter Followers Below
3. Collect Data

The 3. one always returns OK state. This is only for collecting data, for example to show in a graph. 1 and 2 are designed to send you a notifcation.

![](https://img.fox21.at/public/20180424/nagios_s.png)

### Usage

Here is an example **Commands** configuration:

```
# commands.cfg

define command{
	command_name	check_twitter_followers_onlydata
	command_line	$USER1$/check_twitter_followers.rb -u $ARG1$
}

define command{
	command_name	check_twitter_followers_above
	command_line	$USER1$/check_twitter_followers.rb -u $ARG1$ -w $ARG2$ -c $ARG3$ --above
}

define command{
	command_name	check_twitter_followers_below
	command_line	$USER1$/check_twitter_followers.rb -u $ARG1$ -w $ARG2$ -c $ARG3$
}
```

Here is an example **Host** configuration:

```
# fake.cfg

define host{
    use                     generic-host
    host_name               fake
    alias                   FAKE
    address                 www.example.com
}

define service{
    use                             generic-service,graphed-service
    host_name                       fake
    service_description             Twitter Followers wikileaks
    servicegroups                   twitter_services
    check_command                   check_twitter_followers_onlydata!wikileaks
}

define service{
    use                             generic-service,graphed-service
    host_name                       fake
    service_description             Twitter Followers briankrebs
    servicegroups                   twitter_services
    check_command                   check_twitter_followers_below!briankrebs!222000!200000
}
```

## Check Ethereum JSON-RPC Nagios Plugin

Script: [check_ethereum_rpc.rb](check_ethereum_rpc.rb)

This script lets you check every value provided by the [Ethereum JSON-RPC API](https://github.com/ethereum/wiki/wiki/JSON-RPC).

When you use [go-ethereum](https://github.com/ethereum/go-ethereum) (geth) you have to add `--rpc` to the cli options to activate the RPC.

![](https://img.fox21.at/public/20180428/nagios_s.png)

### Usage

Here is an example **Commands** configuration:

```
# commands.cfg

define command{
	command_name check_ethereum_rpc_above
	command_line $USER1$/check_ethereum_rpc.rb -H $ARG1$ -p $ARG2$ -w $ARG3$ -c $ARG4$ $ARG5$ $ARG6$
}

define command{
	command_name check_ethereum_rpc_below
	command_line $USER1$/check_ethereum_rpc.rb -H $ARG1$ -p $ARG2$ -w $ARG3$ -c $ARG4$ $ARG5$ $ARG6$
}
```

Here is an example **Host** configuration:

```
# server1.cfg

define host{
    use                     generic-host
    host_name               server1
    alias                   Server1
    address                 server1.dev
}

define service{
    use                             generic-service,graphed-service
    host_name                       server1
    service_description             Ethereum Sync 3m
    check_command                   check_nrpe_ethereum_rpc_above!127.0.0.1!8545!2999999!3000000!eth_syncing!currentBlock
}

define service{
    use                             generic-service,graphed-service
    host_name                       server1
    service_description             Ethereum Block 6m
    check_command                   check_nrpe_ethereum_rpc_above!127.0.0.1!8545!5990000!6000000!eth_syncing!highestBlock
}
```

## Check IMDb Nagios Plugin

Script: [check_imdb.rb](check_imdb.rb)

This script can be used to check the end of a TV series on [IMDb](https://www.imdb.com/). You either provide the full URL to the IMDb page or only the Title ID.

For example, the full URL to *Family Guy* is <https://www.imdb.com/title/tt0182576/>. The last part of the URL, `tt0182576`, would be the Title ID.

![](https://img.fox21.at/public/20180501/nagios_imdb_s.png)

![](https://img.fox21.at/public/20180501/nagios_imdb_bb_s.png)

### Usage

Since this plugin doesn't rely on a specific host you can add it to any existing host. Or you can just create a fake host like example.com.

Here is an example **Commands** configuration:

```
# commands.cfg

define command{
	command_name	check_imdb_series
	command_line	$USER1$/check_imdb.rb --title $ARG1$ --series
}
```

Here is an example **Host** configuration:

```
# fake.cfg

define host{
    use                     generic-host
    host_name               fake
    alias                   FAKE
    address                 www.example.com
}

define service{
    use                             generic-service
    host_name                       fake
    service_description             Family Guy
    check_command                   check_imdb_series!tt0182576
}
```

## Check GitHub Release Nagios Plugin

Script: [check_github_release.rb](check_github_release.rb)

This script can be used to check a release of a GitHub Repository.

## Usage

Since this plugin doesn't rely on a specific host you can add it to any existing host. Or you can just create a fake host like example.com.

Here is an example **Commands** configuration:

```
# commands.cfg

define command{
	command_name	check_github_release
	command_line	$USER1$/check_github_release.rb --name $ARG1$ -w $ARG2$ -c $ARG3$
}
```

Here is an example **Host** configuration:

```
# fake.cfg

define host{
    use                     generic-host
    host_name               fake
    alias                   FAKE
    address                 www.example.com
}

define service{
    use                             generic-service
    host_name                       fake
    service_description             GitHub: ethereum/go-ethereum
    check_command                   check_github_release!1.8.9!1.9
}
```

## License

Copyright (C) 2018 Christian Mayer <https://fox21.at>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
