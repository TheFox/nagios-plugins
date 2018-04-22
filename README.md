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
# google.cfg

define host{
    use                     generic-host
    host_name               google
    alias                   Google
    address                 www.google.com
    hostgroups              all
}

define service{
    use                             generic-service
    host_name                       google
    service_description             BTC Above
    check_command                   check_bitcoin_price_above!bitcoin!EUR!6800!7000
}

define service{
    use                             generic-service
    host_name                       google
    service_description             ETH Below
    check_command                   check_bitcoin_price_below!ethereum!EUR!400!320
}
```

## License

Copyright (C) 2018 Christian Mayer <https://fox21.at>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
