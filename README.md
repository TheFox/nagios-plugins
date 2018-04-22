# Nagios Plugins

A collection of my [Nagios](https://www.nagios.org/) plugins.

## Check Bitcoin Price Nagios Plugin

Script: [check_bitcoin_price.rb](check_bitcoin_price.rb)

A plugin for checking the Bitcoin price.

This plugin lets you check every crypto currency listed on [Coin Market Cap](https://coinmarketcap.com/). It uses the [Ticker (Specific Currency) API](https://coinmarketcap.com/api/) to the get the current price of your favourite crypto currency. You can choose every fiat currency listed on Coin Market Cap.

![](https://img.fox21.at/public/20180422/nagios_s.png)

### Usage

Since this plugin doesn't rely on a specific host you can add it to any existing host. Or you can just create a fake host like Google.

Here is an example **Commands** configuration:

```
# commands.cfg

define command{
    command_name    check_bitcoin_price_above
    command_line    $USER1$/check_bitcoin_price.rb --coin $ARG1$ --fiat $ARG2$ --warn $ARG3$ --critical $ARG4$ --above
}

define command{
    command_name    check_bitcoin_price_below
    command_line    $USER1$/check_bitcoin_price.rb --coin $ARG1$ --fiat $ARG2$ --warn $ARG3$ --critical $ARG4$ --below
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

Since this plugin doesn't rely on a specific host you can add it to any existing host. Or you can just create a fake host like Google.

Here is an example **Commands** configuration:

```
# commands.cfg

define command{
	command_name	check_bsto_series
	command_line	$USER1$/check_bsto_series.rb --series "$ARG1$" --saison $ARG2$ -w $ARG3$ -c $ARG4$ --lang $ARG5$
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
    servicegroups                   series_services
    check_command                   check_bsto_series!Family-Guy!15!19!20!de
}
```

## License

Copyright (C) 2018 Christian Mayer <https://fox21.at>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
