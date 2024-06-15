# Forex Trading Strategies
In this repository I put the Forex trading codes in MQL4. The language is based on C, and runs on MetaTrader application. When loaded on top of a chart, it will monitor prices and send orders when conditions are all good. It also performs continuous trailing. Most of the settings of the indicators are configurable, and well docoumented in the code.

## Performance and Optimization through Backtest

Performance of the strategies based on RSI, MACD and Fair Value Gap indicators are explained and tested in the following:

1) [RSI and MACD combination](https://drsoli.com/index.php/2023/04/22/forex-01-diversification-with-rsi-and-macd-mql4-metatrader/)

2) My YouTube video on coding and back testing Fair Value Gap, and combining it with RSI and MACD.
[![coding and backtesting Fair Value Gap with MQL4 MetaTrader](https://i.ytimg.com/vi/1w5A0cl3uMk/hqdefault.jpg?sqp=-oaymwEmCOADEOgC8quKqQMa8AEB-AH-CYACugWKAgwIABABGHIgOig_MA8=&rs=AOn4CLBnINcbvhLHzy_WnXvoUhs_7XAqvA)](https://www.youtube.com/watch?v=1w5A0cl3uMk)

## RSI indicator
### Definition
The relative strength index (RSI) is a momentum indicator used in technical analysis. RSI measures the speed and magnitude of a security's recent price changes to evaluate overvalued or undervalued conditions in the price of that security. ([Investopedia](https://www.investopedia.com/terms/r/rsi.asp))

### RSI level trading
Over-bought and over-sold markets are two states derived from RSI indicator reaching above 70% or below 30%, respectively. These are signals for 

![RSI Level trading](https://github.com/saidplayer/ForexTradingStrategies/assets/85461502/a0ce5729-1c74-40bd-8e53-85ce6e9eb52e)


### RSI Divergence
This is a famous momentum trading indicator. The strong one indicator signals a BUY, when the price chart forms a lower low, while the RSI indicator shows a higher low, as in the figure below. The opposite is true for a SELL signal: when the price forms a higher high, while RSI forms a lower high.

![RSI divergence](https://github.com/saidplayer/ForexTradingStrategies/assets/85461502/6aafe9a8-d315-4d4c-b1ab-d52879a919d5)


