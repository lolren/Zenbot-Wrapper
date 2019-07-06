# Zenbot-Wrapper
This is a bash script to wrap around the trading bot Zenbot, The script is easy to understand, to modify and acts faster as the zenbot
The requirements are: 
1.The coinmarketcap  python api - https://github.com/barnumbirr/coinmarketcap . This is used just for getting some prices, to determine the value 
of our coin, to know if the bot begin with a sale or a buy action! can make it optional in the future!
2. The Binance python api, from - https://github.com/toshima/binance since they are both under GPL licence, i`ve included them in my repo.
3. Of course Zenbot. The role of this is to execute the buy and sale commands! it can be downloaded and istalled from : https://github.com/DeviaVir/zenbot


How to install?

The first thing is to install zenbot! The author has a simple tutorial on his page. I reccomend ubuntu or ubuntu server and Virtualbox!
you need to put api and secret for binance in the file binance/binancebridge.py. at the moment, binance is the only one suported!
after, download my bot, point the path to the zenbot folder zenbotpath="/home/x/zenbot" and, set the paramethers you want and you are good to go!

requirements :
bc  python-requests-cache python-requests


How to run?
like any other bash script: chmod +X bot.sh
sudo ./bot.sh 
why run as sudo ( unfortunately, sudo is a requirement for coinmarketcap apy. Also, the bot creates a ramdisk to put some files, required, in /mnt/lpmbot. These are text files with prices.

why i created the script? i-ve played a lot with Zenbot. for some reason, you set the parameters, and its laggy, meaning that it waits till it makes the transaction with the parameters you give! 
