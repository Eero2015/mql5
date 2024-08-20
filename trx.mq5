//+------------------------------------------------------------------+
//|                                                          trx.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+


#include <../../Include/Trade/Trade.mqh>
#include <../../Include/Trade/PositionInfo.mqh>
#include <../../Include/Trade/AccountInfo.mqh>
#include <../../Include/Trade/HistoryOrderInfo.mqh>
#include <../../Include/Trade/OrderInfo.mqh>
#include <../../Include/Trade/DealInfo.mqh>
//#include <../../Include/Expert/Expert.mqh>
ulong input expert_magic = 123456;

CTrade mtrade;
CPositionInfo _position;
CHistoryOrderInfo history;
COrderInfo orders;
CDealInfo deals;
CAccountInfo accountInfo;
//CExpert expert;
//---

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES _period = PERIOD_H4;
string chart_symbol = Symbol();
double s_point = SymbolInfoDouble(chart_symbol, SYMBOL_POINT);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBuyFvg(MqlRates& _arr[])
  {
   return _arr[0].high < _arr[2].low ? true : false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSellFvg(MqlRates& _arr[])
  {
   return _arr[0].low > _arr[2].high ? true : false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isConsolidation(MqlRates& _arr[])
  {
   return !(_arr[0].low > _arr[2].high) && !(_arr[0].high < _arr[2].low) ? true : false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isIndicatorAboveZero()
  {
   double _dArr[];
   bufferDataFunct(_dArr);
   return ArraySize(_dArr) > 0 && _dArr[0] > 0 && _dArr[1] > 0 && _dArr[2] > 0 ? true : false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isIndicatorBelowZero()
  {
   double _dArr[];
   bufferDataFunct(_dArr);
   return _dArr[0] < 0 && _dArr[1] < 0 && _dArr[2] < 0 ? true : false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isCandleCloseAbove(MqlRates& _arr[], double& _highest)
  {
   return isBuyFvg(_arr) && (_arr[0].close < _highest) && (_arr[1].close > _highest || _arr[2].close > _highest) ?
          true : false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isCandleCloseBelow(MqlRates& _arr[], double& _lowest)
  {
   return isSellFvg(_arr) && (_arr[0].close > _lowest) && (_arr[1].close < _lowest || _arr[2].close < _lowest) ?
          true : false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isInVicinity(MqlRates& _arr[], double& refVal)
  {
   return (_arr[0].high >= refVal && _arr[0].low < refVal) ||
          (_arr[0].low <= refVal && _arr[0].high > refVal) ?
          true : false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isPriceRetracing(MqlRates& _arr[])
  {
   return (_arr[0].high < _arr[2].low &&  _arr[2].close < _arr[1].high) ||
          (_arr[0].low > _arr[2].high && _arr[2].close > _arr[1].low) ?
          true : false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void detPointMultiplier(
   double& sym_point,
   double& multiplier
)
  {
   double none = 1.0;
   double one = 0.1;
   double two = 0.01;
   double three = 0.001;
   double four = 0.0001;
   double five = 0.00001;
   double six = 0.000001;
   double seven = 0.0000001;
   double eight = 0.00000001;
   double nine = 0.000000001;
   if(sym_point == one)
     {
      multiplier = 10.0;
     }
   if(sym_point == two)
     {
      multiplier = 100.0;
     }
   if(sym_point == three)
     {
      multiplier = 1000.0;
     }
   if(sym_point == four)
     {
      multiplier = 10000.0;
     }
   if(sym_point == five)
     {
      multiplier = 100000.0;
     }
   if(sym_point == six)
     {
      multiplier = 1000000.0;
     }
   if(sym_point == seven)
     {
      multiplier = 10000000.0;
     }
   if(sym_point == eight)
     {
      multiplier = 100000000.0;
     }
   if(sym_point == nine)
     {
      multiplier = 1000000000.0;
     }
   if(sym_point == none)
     {
      multiplier = 1.0;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void bufferDataFunct(double& dataArr[])
  {
   int crtrx = iTriX(chart_symbol, _period, 14, PRICE_MEDIAN);
   int prev_trxVal  = CopyBuffer(crtrx, 0, 0, 3, dataArr);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void initTime(datetime& _time)
  {
   datetime time[];
   int c = CopyTime(chart_symbol, _period, 0, 1, time);
   if(c > 0)
      _time = time[0];
  }
//trx increasing function

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void mtradeFunc()
  {
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO)
     {
      ExpertRemove();
     }
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool strictAdd(double& arr[], double& elem)
  {
   int arr_size = ArraySize(arr);
   if(arr_size > 0)
     {
      if(arr[ArraySize(arr) - 1] != elem)
        {
         ArrayResize(arr, ArraySize(arr) + 1);
         int minusOne = ArraySize(arr) - 1;
         arr[minusOne] = elem;
         return true;
        }
     }
   if(arr_size == 0)
     {
      ArrayResize(arr, ArraySize(arr) + 1);
      int minusOne = ArraySize(arr) - 1;
      arr[minusOne] = elem;
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool strictAdd(ulong& arr[], ulong& elem)
  {
   int arr_size = ArraySize(arr);
   if(arr_size > 0)
     {
      if(arr[ArraySize(arr) - 1] != elem)
        {
         ArrayResize(arr, ArraySize(arr) + 1);
         int minusOne = ArraySize(arr) - 1;
         arr[minusOne] = elem;
         return true;
        }
     }
   if(arr_size == 0)
     {
      ArrayResize(arr, ArraySize(arr) + 1);
      int minusOne = ArraySize(arr) - 1;
      arr[minusOne] = elem;
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool strictAdd(datetime& arr[], datetime& elem)
  {
   int arr_size = ArraySize(arr);
   if(arr_size > 0)
     {
      if(arr[ArraySize(arr) - 1] != elem)
        {
         ArrayResize(arr, ArraySize(arr) + 1);
         int minusOne = ArraySize(arr) - 1;
         arr[minusOne] = elem;
         return true;
        }
     }
   if(arr_size == 0)
     {
      ArrayResize(arr, ArraySize(arr) + 1);
      int minusOne = ArraySize(arr) - 1;
      arr[minusOne] = elem;
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void addMqlDataToArr(MqlRates& rateArr[],
                     double& highsArr[],
                     double& lowsArr[],
                     datetime& l_time[],
                     datetime& h_time[])
  {
   for(int i = 0; i < ArraySize(rateArr); i++)
     {
      strictAdd(highsArr, rateArr[i].high);
      strictAdd(lowsArr, rateArr[i].low);
      strictAdd(l_time, rateArr[i].time);
      strictAdd(h_time, rateArr[i].time);
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void highestLowestVal(MqlRates& _rates[],
                      double& _highest,
                      double& _lowest)
  {
   double highs[], lows[];
   datetime h_time[], l_time[];
   if(isBuyFvg(_rates))
     {
      _highest = _rates[1].high > _rates[2].high ? _rates[2].high : _rates[1].high;
      _lowest = _rates[0].low > _rates[1].low ? _rates[1].low : _rates[0].low;
     }
   if(isSellFvg(_rates))
     {
      _highest = _rates[0].high > _rates[1].high ? _rates[1].high : _rates[0].high;
      _lowest = _rates[1].low > _rates[2].low ? _rates[2].low : _rates[1].low;
     }
   if(!isBuyFvg(_rates) && !isSellFvg(_rates))
     {
      addMqlDataToArr(_rates, highs, lows, l_time, h_time);
      _highest = highs[ArrayMaximum(highs)];
      _lowest = lows[ArrayMinimum(lows)];
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool detectTrig(
   MqlRates& _trgArr[],
   double & _trg,
   double & _trgSl,
   datetime & _trgTime,
   double _refVal = 0)
  {
   double highest, lowest;
   highestLowestVal(_trgArr, highest, lowest);
   if(isBuyFvg(_trgArr))
     {
      _trg = isPriceRetracing(_trgArr) ? _trgArr[2].low : _trgArr[1].high;
      _trgSl = lowest;
      _trgTime = isPriceRetracing(_trgArr) ? _trgArr[2].time : _trgArr[1].time;
      return true;
     }
   if(isSellFvg(_trgArr))
     {
      _trg = isPriceRetracing(_trgArr) ? _trgArr[2].high : _trgArr[1].low;
      _trgSl = highest;
      _trgTime = isPriceRetracing(_trgArr) ? _trgArr[2].time : _trgArr[1].time;
      return true;
     }
   if(!isBuyFvg(_trgArr) && !isSellFvg(_trgArr) && _refVal != 0 && isInVicinity(_trgArr, _refVal))
     {
      _trg = _trgArr[0].high;
      _trgSl = _refVal;
      _trgTime = _trgArr[0].time;
     }
   return false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void modifyBuyPositions()
  {
   int total = PositionsTotal();
   MqlRates h4[], rate[];
   CopyRates(chart_symbol, _period, 2, 3, h4);
   CopyRates(chart_symbol, _period, 1, 1, rate);
   if(total > 0)
     {
      double sl, tp, sl_Arr[];
      for(int i = 0; i < total; i++)
        {
         ulong ticket = PositionGetTicket(i);
         long type = PositionGetInteger(POSITION_TYPE);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double stoploss = PositionGetDouble(POSITION_SL);
         if(type == POSITION_TYPE_BUY)
           {
            strictAdd(sl_Arr, stoploss);
            if(ArraySize(sl_Arr) > 0)
              {
               double min_stoploss = sl_Arr[ArrayMinimum(sl_Arr)];
               double max_stoploss = sl_Arr[ArrayMaximum(sl_Arr)];
               double avoidZeroSl = stoploss > 0 ? stoploss : min_stoploss;
               if(max_stoploss >= openPrice && avoidZeroSl < max_stoploss)
                 {
                  sl = max_stoploss;
                  tp = 0.0;
                  mtrade.PositionModify(ticket, sl, tp);
                 }
               if(h4[0].high < h4[2].low && rate[0].close > h4[2].high)
                 {
                  if(h4[2].low >= openPrice && h4[2].low > avoidZeroSl)
                    {
                     sl = h4[2].low;
                     tp = 0.0;
                     mtrade.PositionModify(ticket, sl, tp);
                    }
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void modifySellPositions()
  {
   int total = PositionsTotal();
   MqlRates h4[], rate[];
   CopyRates(chart_symbol, _period, 2, 3, h4);
   CopyRates(chart_symbol, _period, 1, 1, rate);
   if(total > 0)
     {
      double sl, tp, sl_Arr[];
      for(int i = 0; i < total; i++)
        {
         ulong ticket = PositionGetTicket(i);
         long type = PositionGetInteger(POSITION_TYPE);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double stoploss = PositionGetDouble(POSITION_SL);
         if(type == POSITION_TYPE_SELL)
           {
            strictAdd(sl_Arr, stoploss);
            if(ArraySize(sl_Arr) > 0)
              {
               double min_stoploss = sl_Arr[ArrayMinimum(sl_Arr)];
               double max_stoploss = sl_Arr[ArrayMaximum(sl_Arr)];
               double avoidZeroSl = stoploss > 0 ? stoploss : max_stoploss;
               if(min_stoploss <= openPrice && min_stoploss < avoidZeroSl)
                 {
                  sl = min_stoploss;
                  tp = 0.00;
                  mtrade.PositionModify(ticket, sl, tp);
                 }
               if(h4[0].low > h4[2].high && rate[0].close < h4[2].low)
                 {
                  if(h4[2].high <= openPrice && h4[2].high < avoidZeroSl)
                    {
                     sl = h4[2].high;
                     tp = 0.0;
                     mtrade.PositionModify(ticket, sl, tp);
                    }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeBuyPositions()
  {
   int total = PositionsTotal();
   if(total > 0)
     {
      for(int i = 0; i < total; i++)
        {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket))
           {
            long type = PositionGetInteger(POSITION_TYPE);
            if(type == POSITION_TYPE_BUY)
              {
               mtrade.PositionClose(ticket);
              }
           }
        }
     }
  }//---

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeSellPositions()
  {
   int _total = PositionsTotal();
   if(_total > 0)
     {
      for(int i = 0; i < _total; i++)
        {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket))
           {
            long type = PositionGetInteger(POSITION_TYPE);
            if(type == POSITION_TYPE_SELL)
              {
               mtrade.PositionClose(ticket);
              }
           }
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void freeHistorryArr(
   datetime & his_arr[],
   datetime & t_tm
)
  {
   datetime time1[];
   CopyTime(chart_symbol, _period, 1, 1, time1);
   if(init_time < time1[0])
     {
      if(HistorySelect(t_tm, time1[0]))
        {
         int totalPositions = PositionsTotal();
         int o_orders = HistoryOrdersTotal();
         if(ArraySize(his_arr) > 0 && totalPositions == 0 && o_orders > 0)
           {
            ArrayFree(his_arr);
            initTime(init_time);
           }
        }
     }
  }
//---
//--



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool addPositions(int& t_counts, bool& _buy, bool& _sell, datetime& _hisArr[])
  {
   double buyTrig, buySl, sellTrig, sellSl;
   datetime buyTrigTime, sellTrigTime;
   MqlRates h4[];
   CopyRates(chart_symbol, _period, 1, 3, h4);
   int totalPositions = PositionsTotal();
   t_counts = ArraySize(_hisArr) > 0 && totalPositions > 0  ? ArraySize(_hisArr) + 1 : 1;
   if(ArraySize(_hisArr) > 0)
     {
      if(_buy && isBuyFvg(h4) && detectTrig(h4, buyTrig, buySl, buyTrigTime, 0.00) &&
         buyTrigTime != _hisArr[ArraySize(_hisArr) - 1] && totalPositions < t_counts)
        {
         return  buyFunct(buyTrig, buySl, buyTrigTime, _hisArr);
        }
      if(_sell && isSellFvg(h4) && detectTrig(h4, sellTrig, sellSl, sellTrigTime, 0.00) &&
         sellTrigTime != _hisArr[ArraySize(_hisArr) - 1] && totalPositions < t_counts)
        {
         return sellFunct(sellTrig, sellSl, sellTrigTime, _hisArr);
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool buyFunct(double & _buyTrig, double & _buySl, datetime & buyTrigTime, datetime & _hisArr[])
  {
   double bid, ask, volume;
   bid = SymbolInfoDouble(chart_symbol, SYMBOL_BID);
   ask = SymbolInfoDouble(chart_symbol, SYMBOL_ASK);
   volume = SymbolInfoDouble(chart_symbol, SYMBOL_VOLUME_MIN);
   return isIndicatorBelowZero() && (bid <= _buyTrig) &&
          (mtrade.Buy(volume, chart_symbol, ask, 0.00, 0.00, string(_buySl))) &&
          strictAdd(_hisArr, buyTrigTime) ? true : false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool sellFunct(double & _sellTrig, double & _sellSl, datetime & _sellTrigTime, datetime & _hisArr[])
  {
   double ask, bid, volume;
   bid = SymbolInfoDouble(chart_symbol, SYMBOL_BID);
   ask = SymbolInfoDouble(chart_symbol, SYMBOL_ASK);
   volume = SymbolInfoDouble(chart_symbol, SYMBOL_VOLUME_MIN);
   return isIndicatorAboveZero() && (ask >= _sellTrig) &&
          (mtrade.Sell(volume, chart_symbol, ask, 0.00, 0.00, string(_sellSl))) &&
          strictAdd(_hisArr, _sellTrigTime) ? true : false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void topDownAnalyser(
   datetime & _hisArr[],
   bool & _buy,
   bool & _sell)
  {
   int totalMonthlyBars = iBars(chart_symbol, PERIOD_MN1);
   if(totalMonthlyBars >= 7)
     {
      MqlRates monthly[], c_Arr[], h4[];
      CopyRates(chart_symbol, PERIOD_MN1, 1, 3, monthly);
      CopyRates(chart_symbol, PERIOD_MN1, 4, 3, c_Arr);
      CopyRates(chart_symbol, PERIOD_H4, 1, 3, h4);
      double ask, bid, volume;
      ask = SymbolInfoDouble(chart_symbol, SYMBOL_ASK);
      bid = SymbolInfoDouble(chart_symbol, SYMBOL_BID);
      volume = SymbolInfoDouble(chart_symbol, SYMBOL_VOLUME_MIN);
      double highest, lowest, buyTrig, buySl, sellTrig, sellSl;
      datetime buyTrigTime, sellTrigTime;
      highestLowestVal(c_Arr, highest, lowest);
      //-- if c_arr is consolidation and is followed by an fvg
      if(isConsolidation(c_Arr))
        {
         //-- if a monthly buy fvg
         if(isBuyFvg(monthly) && isCandleCloseAbove(monthly, highest))
           {
            _buy = isPriceRetracing(monthly) && isCandleCloseAbove(h4, monthly[2].low) &&
                   detectTrig(h4, buyTrig, buySl, buyTrigTime, 0.00) &&
                   buyFunct(buyTrig, buySl, buyTrigTime, _hisArr) ? true : false;
            _buy = (!isPriceRetracing(monthly) && detectTrig(h4, buyTrig, buySl, buyTrigTime, highest)) &&
                   buyFunct(buyTrig, buySl, buyTrigTime, _hisArr) ?
                   true : false;
           }
         //-- if a monthly sell fvg
         if(isSellFvg(monthly) && isCandleCloseBelow(monthly, lowest))
           {
            _sell = isPriceRetracing(monthly) && isCandleCloseBelow(h4, monthly[2].high) &&
                    detectTrig(h4, sellTrig, sellSl, sellTrigTime, 0.00) &&
                    sellFunct(sellTrig, sellSl, sellTrigTime, _hisArr) ? true : false;
            _sell = !isPriceRetracing(monthly) && detectTrig(h4, sellTrig, sellSl, sellTrigTime, lowest) &&
                    sellFunct(sellTrig, sellSl, sellTrigTime, _hisArr) ?
                    true : false;
           }
        }
      //-- if c_arr is a consolidation or a buy or a sell fvg and is followed by consolidation
      if((isBuyFvg(c_Arr) || isSellFvg(c_Arr) || isConsolidation(c_Arr)) && isConsolidation(monthly))
        {
         if(isCandleCloseAbove(monthly, highest))
           {
            _buy = isPriceRetracing(monthly) && isCandleCloseAbove(h4, monthly[2].low) &&
                   detectTrig(h4, buyTrig, buySl, buyTrigTime, 0.00) &&
                   buyFunct(buyTrig, buySl, buyTrigTime, _hisArr) ? true : false;
            _buy = (!isPriceRetracing(monthly) && detectTrig(h4, buyTrig, buySl, buyTrigTime, highest)) &&
                   buyFunct(buyTrig, buySl, buyTrigTime, _hisArr) ?
                   true : false;
           }
         if(isCandleCloseBelow(monthly, lowest))
           {
            _sell = isPriceRetracing(monthly) && isCandleCloseBelow(h4, monthly[2].high) &&
                    detectTrig(h4, sellTrig, sellSl, sellTrigTime, 0.00) &&
                    sellFunct(sellTrig, sellSl, sellTrigTime, _hisArr) ? true : false;
            _sell = !isPriceRetracing(monthly) && detectTrig(h4, sellTrig, sellSl, sellTrigTime, lowest) &&
                    sellFunct(sellTrig, sellSl, sellTrigTime, _hisArr) ?
                    true : false;
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void twoMonthSAnalyser()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double  pointMultiplier, neg_turnTrigg, pos_turnTrigg, neg_turnSl, pos_turnSl,
        buySls[], sellSls[], trxData[], negTrxTurn[], posTrxTurn[], firstTrades[];
datetime init_time, neg_turnTime, pos_turnTime, historyTime[], negTrxTurnTime[], posTrxTurnTime[];
int order_counts, trades_counts;
bool isBuySignal, isSellSignal;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   mtradeFunc();
   initTime(init_time);
   topDownAnalyser(historyTime, isBuySignal, isSellSignal);
   detPointMultiplier(s_point, pointMultiplier);
   Print(isBuySignal, "  ", isSellSignal);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   freeHistorryArr(historyTime, init_time);
   topDownAnalyser(historyTime, isBuySignal, isSellSignal);
   addPositions(trades_counts, isBuySignal, isSellSignal, historyTime);
   modifyBuyPositions();
   modifySellPositions();
   closeBuyPositions();
   closeSellPositions();
   mtradeFunc();
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction & trans,
                        const MqlTradeRequest & request,
                        const MqlTradeResult & result)
  {
//---
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long & lparam,
                  const double & dparam,
                  const string & sparam)
  {
//---
  }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string & symbol)
  {
//---
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
/*
void reverseTrade(string& chart_symbol,
                  ENUM__periodS& _period,
                  int& count,
                  double& negTurnArr[],
                  double& posTurnArr[],
                  datetime& his_Arr[])
  {
   MqlRates rate[];
   double ask = chart_symbolInfoDouble(chart_symbol, chart_symbol_ASK);
   double bid = chart_symbolInfoDouble(chart_symbol, chart_symbol_BID);
   double volume = chart_symbolInfoDouble(chart_symbol, chart_symbol_VOLUME_MIN);
   int totalPositons = PositionsTotal();
   count = ArraySize(his_Arr) > 0 ? ArraySize(his_Arr) + 1 : 1;
   if(ArraySize(negTurnArr) > 0)
     {
      double trigger = negTurnArr[ArrayMaximum(negTurnArr)];
      CopyRates(chart_symbol, _period, 1, 2, rate);
      if(rate[0].close < trigger && rate[1].close > trigger)
        {
         if(totalPositons < count + 1)
           {
            if(ask > trigger && bid < trigger)
              {
               if(mtrade.Buy(volume, chart_symbol, ask, 0.00, 0.00, string(rate[0].low)))
                 {
                  strictAdd(his_Arr, rate[1].time);
                 }
              }
           }
        }
     }
   if(ArraySize(posTurnArr) > 0)
     {
      double trigger = posTurnArr[ArrayMinimum(posTurnArr)];
      CopyRates(chart_symbol, _period, 1, 2, rate);
      if(rate[0].close > trigger && rate[1].close < trigger)
        {
         if(totalPositons < count + 1)
           {
            if(bid < trigger && ask > trigger)
              {
               if(mtrade.Sell(volume, chart_symbol, bid, 0.00, 0.00, string(rate[0].high)))
                 {
                  strictAdd(his_Arr, rate[0].time);
                 }
              }
           }
        }
     }
  }
*/
/* 
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void openBuyPositions(
   double& dataArr[],
   double& _ftrades[],
   int& t_counts,
   datetime & init_t,
   datetime & his_arr[])
  {
// trxIncreasing(pos_turnTrigg, pos_turnSl, neg_turnTrigg, neg_turnSl, neg_turnTime, pos_turnTime);
   datetime time[];
   MqlRates rate[];
   CopyRates(chart_symbol, _period, 1, 3, rate);
   CopyTime(chart_symbol, _period, 1, 1, time);
   int totalPositions = PositionsTotal();
   t_counts = ArraySize(his_arr) == 0 && totalPositions == 1 ?
              ArraySize(his_arr) + 2 : ArraySize(his_arr) + 1;
   double point = Point();
   double volume = SymbolInfoDouble(chart_symbol, SYMBOL_VOLUME_MIN);
   double ask = SymbolInfoDouble(chart_symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(chart_symbol, SYMBOL_BID);
   if(init_t < time[0])
     {
      if(pos_turnTime == rate[2].time)
        {
         //---
         if(ArraySize(his_arr) >= 1)
           {
            if(pos_turnTrigg > 0 && pos_turnSl > 0 && pos_turnTime != his_arr[ArraySize(his_arr) - 1])
              {
               if(totalPositions < t_counts)
                 {
                  if(rate[2].close <= rate[1].high)
                    {
                     if(rate[2].close >= rate[2].open)
                       {
                        if(ask <= rate[2].open)
                          {
                           if(mtrade.Buy(volume, chart_symbol, ask, 0.00, 0.00, string(pos_turnSl)))
                             {
                              strictAdd(his_arr, pos_turnTime);
                             }
                          }
                       }
                     if(rate[2].close <= rate[2].open)
                       {
                        if(ask <= rate[2].close)
                          {
                           if(mtrade.Buy(volume, chart_symbol, ask, 0.00, 0.00, string(pos_turnSl)))
                             {
                              strictAdd(his_arr, pos_turnTime);
                             }
                          }
                       }
                    }
                  if(rate[2].close > rate[1].high)
                    {
                     if(mtrade.Buy(volume, chart_symbol, ask, 0.00, 0.00, string(pos_turnSl)))
                       {
                        strictAdd(his_arr, pos_turnTime);
                       }
                    }
                 }
              }
           }
        }
     }
  }
*/

/*
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//-- decreasing trx function
void trxDecreasing(
   double& dataArr[],
   double & dec_trigg,
   double & dec_sl,
   datetime & dec_time)
  {
   if(ArraySize(dataArr) > 0)
     {
      double first = dataArr[0];
      double second = dataArr[1];
      double last = dataArr[ArraySize(dataArr) - 1];
      if((second > 0) && (last > 0) && (first > 0))
        {
         MqlRates neg_increase[];
         CopyRates(chart_symbol, _period, 1, 3, neg_increase);
         bool s_fvg = neg_increase[0].low > neg_increase[2].high;
         if(s_fvg)
           {
            dec_trigg = neg_increase[2].high;
            dec_sl = neg_increase[1].high < neg_increase[0].high ?
                     neg_increase[1].high : neg_increase[0].high;
            dec_time = neg_increase[2].time;
           }
        }
     }
  }
*/
//+------------------------------------------------------------------+
/*

            if((c_Arr[0].low <= c_Arr[2].high) || (c_Arr[0].high >= c_Arr[2].low) || (c_Arr[0].high < c_Arr[2].low))
              {
               if(monthly[0].low > lowest && (monthly[1].close < lowest || monthly[2].close < lowest))
                 {
                  if(monthly[1].low < monthly[2].close)
                    {
                     CopyRates(chart_symbol, PERIOD_H4, 1, 3, h4);
                     if(
                        (h4[0].low > h4[2].high) && (h4[0].low > monthly[0].low) &&
                        (h4[1].close < monthly[2].high || h4[2].close < monthly[2].high))
                       {
                        if((first > 0) && (second > 0) && (last > 0) && (last < first))
                          {
                           _buy = false;
                           _sell = true;
                           if(h4[1].low < h4[2].close)
                             {
                              if(bid >= h4[2].high && PositionsTotal() == 0)
                                {
                                 if(mtrade.Sell(volume, chart_symbol, bid, 0.00, 0.00, string(highest)))
                                   {
                                    strictAdd(his_arr, highest_time);
                                   }
                                }
                             }
                           if(h4[1].low > h4[2].close)
                             {
                              if(bid >= h4[1].low && PositionsTotal() == 0)
                                {
                                 if(mtrade.Sell(volume, chart_symbol, bid, 0.00, 0.00, string(highest)))
                                   {
                                    strictAdd(his_arr, highest_time);
                                   }
                                }
                             }
                          }
                       }
                    }
                  if(monthly[1].low > monthly[2].close)
                    {
                     if(
                        (h4[0].high >= monthly[1].low) && (h4[0].low < monthly[1].low) &&
                        (first > 0) && (second > 0) && (last > 0))
                       {
                        _buy = false;
                        _sell = true;
                        if(bid >= h4[0].low && PositionsTotal() == 0)
                          {
                           if(mtrade.Sell(volume, chart_symbol, bid, 0.00, 0.00, string(highest)))
                             {
                              strictAdd(his_arr, highest_time);
                             }
                          }
                       }
                    }
                 }
              }

void detectPattern(string& chart_symbol,
                   ENUM__periodS& _period,
                   double& dataArr[],
                   datetime& b_ptrn_time_arr[],
                   datetime&br_ptrn_time_arr[],
                   bool& bulls_patterns,
                   bool & bears_Pattern)
  {
//-- reversal patterns
   MqlRates rate[], c_rate[];
   double highs[], lows[];
   CopyRates(chart_symbol, _period, 1, 4, rate);
   CopyRates(chart_symbol, _period, 1, 1, c_rate);
   addMqlDataToArr(rate, highs, lows);
//--- candles type
   bool firstBullish, firstBearish, secondBullish, secondBearish, thirdBullish, thirdBearish, fourthBearish, fourthBullish;
   firstBearish = rate[0].open > rate[0].close;
   secondBearish = rate[1].open > rate[1].close;
   thirdBearish = rate[2].open > rate[2].close;
   fourthBearish = rate[3].open > rate[3].close;
//---
   firstBullish = rate[0].open < rate[0].close;
   secondBullish = rate[1].open < rate[1].close;
   thirdBullish = rate[2].open < rate[2].close;
   fourthBullish = rate[3].open < rate[3].close;
//--widths of each of the candle
   double firstWidth, secondWidth, thirdWidth, firstRange, secondRange, thirdRange, brUpperWick, brLowerWick, bUppperWick, bLowerWick;
   firstWidth = MathAbs(NormalizeDouble(rate[0].open - rate[0].close, _Digits));
   secondWidth = MathAbs(NormalizeDouble(rate[1].open - rate[1].close, _Digits));
   thirdWidth =  MathAbs(NormalizeDouble(rate[2].open - rate[2].close, _Digits));
   firstRange = MathAbs(NormalizeDouble(rate[0].high - rate[0].low, _Digits));
   secondRange = MathAbs(NormalizeDouble(rate[1].high - rate[1].low, _Digits));
   thirdRange = MathAbs(NormalizeDouble(rate[2].high - rate[2].low, _Digits));
   brUpperWick = MathAbs(NormalizeDouble(rate[2].high - rate[2].open, _Digits));
   brLowerWick = MathAbs(NormalizeDouble(rate[2].close - rate[2].low, _Digits));
   bUppperWick = MathAbs(NormalizeDouble(rate[2].open - rate[2].low, _Digits));
   bLowerWick = MathAbs(NormalizeDouble(rate[2].high - rate[2].close, _Digits));
//--- reversal patterns definition
//--- more than one candle pattern
   bool bullishEngulfing, bearishEngulfing, morningStar, eveningStar, blackSoldiers, whiteCrows, doji,
        dragonFly, graveStone, hammer, shootingStar, br_piercingLine, b_piercingLine, tweezersTop, tweezersBottom;
//---
//---
   bullishEngulfing = secondBearish && thirdBullish && (rate[2].open <= rate[1].close) && (rate[2].close > rate[1].open) && (rate[1].high < rate[3].low);
//---
   bearishEngulfing = secondBullish && thirdBearish && (rate[2].open >= rate[1].close) && (rate[2].close < rate[1].open) && (rate[1].low > rate[3].high);
//---
   morningStar = secondBearish && fourthBullish && (rate[0].low > rate[2].high) && (rate[3].close >= rate[0].low);
//---
   eveningStar = secondBullish && fourthBearish && (rate[0].high < rate[2].low) && (rate[3].close <= rate[0].high);
//---
//---
   dragonFly = (thirdWidth <= (0.1 * thirdRange)) && (bLowerWick > bUppperWick) && thirdBullish;
//---
   graveStone = (thirdWidth <= (0.1 * thirdRange)) && (brUpperWick > brLowerWick) && thirdBearish;
//---
   hammer =  thirdBullish && (thirdWidth <= (0.3 * bLowerWick)) && (bLowerWick > bUppperWick);
//---
   shootingStar = thirdBearish && (thirdWidth <= (0.3 * brUpperWick)) && (brUpperWick > brLowerWick);
//---
   br_piercingLine = secondBullish && thirdBearish && (rate[2].close < (0.5 * secondWidth)) &&
                     (rate[1].close == rate[2].open) && (rate[2].close < rate[1].open);
//---
   b_piercingLine = secondBearish && thirdBullish && (rate[2].close > (0.5 * secondWidth)) &&
                    (rate[1].close == rate[2].open) && (rate[2].close < rate[1].open);
//---
   whiteCrows = firstBullish && secondBullish && thirdBullish && (firstWidth == secondWidth)  &&
                (firstWidth == thirdWidth) && (secondWidth == thirdWidth) &&
                (rate[0].close < rate[1].close < rate[2].close);
//---
   blackSoldiers = firstBearish && secondBearish && thirdBearish && (firstWidth == secondWidth)  && (firstWidth == thirdWidth) &&
                   (secondWidth == thirdWidth) &&
                   (rate[0].close > rate[1].close > rate[2].close);
//---
   tweezersTop  = (secondWidth == thirdWidth) && secondBullish && thirdBearish && (rate[1].close >= rate[2].open);
//---
   tweezersBottom = (secondWidth == thirdWidth) && secondBearish && thirdBullish && (rate[1].close <= rate[2].open);
//---
   double highest = highs[ArrayMaximum(highs)];
   double lowest = lows[ArrayMinimum(lows)];
   if(ArraySize(dataArr) > 0)
     {
      double thirdtrx = dataArr[2];
      double secondtrx = dataArr[1];
      double firsttrx = dataArr[0];
      double last = dataArr[ArraySize(dataArr) - 1];
      if(last < 0)
        {
         //-- possible reversal bullish
         if(firsttrx > secondtrx)
           {
            if(bullishEngulfing /*|| morningStar || whiteCrows || dragonFly || hammer || tweezersBottom || b_piercingLine/)
              {
               Print("");
               Print("sexond trx : ", secondtrx, "   third trx :", thirdtrx);
               Print("...........");
               //bears_Pattern = false;
               //bulls_patterns = true;
               //strictAdd(b_ptrn_time_arr, rate[2].time);
               Print(" ");
               Print("BULLISH REVERSAL :  buy .. buy .. ");
               Print("..time :  ", rate[2].time,  " ..stoploss : ", lowest);
               Print("................................................");
               Print(" bullish engulfing : ", bullishEngulfing/*, " morning star : " ,morningStar, " white crows : ", whiteCrows/);
               //Print(" dragon fly : ",dragonFly, " hammer : ", hammer, " tweezer bottom : ", tweezersBottom, "  piercing line : ", b_piercingLine);
               Print("");
              }
           }
         //-- continuation bearish
         if(firsttrx < secondtrx)
           {
            if(bearishEngulfing /*|| eveningStar || blackSoldiers || graveStone || shootingStar || tweezersTop || br_piercingLine/)
              {
               Print("");
               Print("sexond trx : ", secondtrx, "   third trx :", thirdtrx);
               Print("...........");
               //bears_Pattern = true;
               //bulls_patterns = false;
               //strictAdd(br_ptrn_time_arr, rate[2].time);
               Print(" ");
               Print("BEARISH CONTINUATION :   sell... sell .. sell .. ");
               Print("................................................");
               Print(" bearish engulfing : ", bearishEngulfing/*, " evening star : " ,eveningStar, " black soldiers : ", blackSoldiers/);
               //Print(" grave stone : ",graveStone, " stone star : ", shootingStar, " tweezer top : ", tweezersTop, "  br piercing line : ", br_piercingLine);
               Print("..time :  ", rate[2].time, " stoploss : ", highest);
              }
           }
        }
      //---
      if(last > 0)
        {
         if(firsttrx < secondtrx)
           {
            if(bearishEngulfing /*|| eveningStar || blackSoldiers || graveStone || shootingStar || tweezersTop || br_piercingLine/)
              {
               Print("");
               Print("sexond trx : ", secondtrx, "   third trx :", thirdtrx);
               Print("...........");
               //bears_Pattern = true;
               //bulls_patterns = false;
               //strictAdd(br_ptrn_time_arr, rate[2].time);
               Print(" ");
               Print("BEARISH REVERSAL :   sell... sell .. sell .. ");
               Print("................................................");
               Print(" bearish engulfing : ", bearishEngulfing/*, " evening star : " ,eveningStar, " black soldiers : ", blackSoldiers/);
               //Print(" grave stone : ",graveStone, " stone star : ", shootingStar, " tweezer top : ", tweezersTop, "  br piercing line : ", br_piercingLine);
               Print("..time :  ", rate[2].time, " stoploss : ", highest);
              }
           }
         if(firsttrx > secondtrx)
           {
            if(bullishEngulfing /*|| morningStar || whiteCrows || dragonFly || hammer || tweezersBottom || b_piercingLine/)
              {
               Print("");
               Print("sexond trx : ", secondtrx, "   third trx :", thirdtrx);
               Print("...........");
               //bears_Pattern = false;
               //bulls_patterns = true;
               //strictAdd(b_ptrn_time_arr, rate[2].time);
               Print(" ");
               Print("BULLISH CONTINUATION :  buy .. buy .. ");
               Print("................................................");
               Print(" bullish engulfing : ", bullishEngulfing/*, " morning star : " ,morningStar, " white crows : ", whiteCrows/);
               //Print(" dragon fly : ",dragonFly, " hammer : ", hammer, " tweezer bottom : ", tweezersBottom, "  piercing line : ", b_piercingLine);
               Print("..time :  ", rate[2].time,  " ..stoploss : ", lowest);
               Print("");
              }
           }
        }
     }
  }
*/
//+------------------------------------------------------------------+
/*
                  if(profit > threeTimes && ((openPrice + threeTimes * multiplier) > avoiZeroStoploss))
                    {
                     sl = openPrice + threeTimes * multiplier;
                     tp = 0.00;
                     mtrade.PositionModify(ticket, sl, tp);
                    }
                  //---
                  if(profit > fiveTimes && ((openPrice + fiveTimes * multiplier) > avoiZeroStoploss))
                    {
                     sl = openPrice + fiveTimes * multiplier;
                     tp = 0.00;
                     mtrade.PositionModify(ticket, sl, tp);
                    }
                  //---
                  if(profit > tenTimes && ((openPrice + tenTimes * multiplier) > avoiZeroStoploss))
                    {
                     sl = openPrice + tenTimes * multiplier;
                     tp = 0.00;
                     mtrade.PositionModify(ticket, sl, tp);
                    }
                  //---
                  if(profit > twentyTimes && ((openPrice + twentyTimes * multiplier) > avoiZeroStoploss))
                    {
                     sl = openPrice + twentyTimes * multiplier;
                     tp = 0.00;
                     mtrade.PositionModify(ticket, sl, tp);
                    }
                  //---
                  if(profit > thirtytimes && ((openPrice + thirtytimes * multiplier) > avoiZeroStoploss))
                    {
                     sl = openPrice + thirtytimes * multiplier;
                     tp = 0.00;
                     mtrade.PositionModify(ticket, sl, tp);
                    }
                  //---
                  if(profit > fiftytimes && ((openPrice + fiftytimes * multiplier) > avoiZeroStoploss))
                    {
                     sl = openPrice + fiftytimes * multiplier;
                     tp = 0.00;
                     mtrade.PositionModify(ticket, sl, tp);
                    }
                  //---
                  if(profit > hundredtimes && ((openPrice + hundredtimes * multiplier) > avoiZeroStoploss))
                    {
                     sl = openPrice + hundredtimes * multiplier;
                     tp = 0.00;
                     mtrade.PositionModify(ticket, sl, tp);
                    }
                  //---*/
//+------------------------------------------------------------------+
/*double oneTimes = 1;
double threeTimes = 3;
double fiveTimes = 5;
double tenTimes = 10;
double twentyTimes = 20;
double thirtytimes = 30;
double fiftytimes = 50;
double hundredtimes = 100;*/
/*
                 if(high < openPrice && high < avoidZeroStoploss)
                   {
                    sl = high;
                    tp = 0.00;
                    mtrade.PositionModify(ticket, sl, tp);
                   }
                 //---
                 //---
                 if(profit > threeTimes && ((openPrice - threeTimes * multiplier) < avoidZeroStoploss))
                   {
                    sl = openPrice - threeTimes * multiplier;
                    tp = 0.00;
                    mtrade.PositionModify(ticket, sl, tp);
                   }
                 //---
                 if(profit > fiveTimes && ((openPrice - fiveTimes * multiplier) < avoidZeroStoploss))
                   {
                    sl = openPrice - fiveTimes * multiplier;
                    tp = 0.00;
                    mtrade.PositionModify(ticket, sl, tp);
                   }
                 //---
                 if(profit > tenTimes && ((openPrice - tenTimes * multiplier) < avoidZeroStoploss))
                   {
                    sl = openPrice - tenTimes * multiplier;
                    tp = 0.00;
                    mtrade.PositionModify(ticket, sl, tp);
                   }
                 //---
                 if(profit > twentyTimes && ((openPrice - twentyTimes * multiplier) < avoidZeroStoploss))
                   {
                    sl = openPrice - twentyTimes * multiplier;
                    tp = 0.00;
                    mtrade.PositionModify(ticket, sl, tp);
                   }
                 //---
                 if(profit > thirtytimes && ((openPrice - thirtytimes * multiplier) < avoidZeroStoploss))
                   {
                    sl = openPrice - thirtytimes * multiplier;
                    tp = 0.00;
                    mtrade.PositionModify(ticket, sl, tp);
                   }
                 //---
                 if(profit > fiftytimes && ((openPrice - fiftytimes * multiplier) < avoidZeroStoploss))
                   {
                    sl = openPrice - fiftytimes * multiplier;
                    tp = 0.00;
                    mtrade.PositionModify(ticket, sl, tp);
                   }
                 //---
                 if(profit > hundredtimes && ((openPrice - hundredtimes * multiplier) < avoidZeroStoploss))
                   {
                    sl = openPrice - hundredtimes * multiplier;
                    tp = 0.00;
                    mtrade.PositionModify(ticket, sl, tp);
                   }*/
/*
void tester(double& dataArr[])
  {
   TesterHideIndicators(false);
   MqlRates rate[], m_rate[], w_rate[];
   int m_count = iBars(chart_symbol(), PERIOD_MN1) - 1;
   int w_count = iBars(chart_symbol(), PERIOD_W1) - 1;
   CopyRates(chart_symbol(), PERIOD_MN1, 1, m_count, m_rate);
   CopyRates(chart_symbol(), PERIOD_W1, 1, w_count, w_rate);
   CopyRates(chart_symbol(), PERIOD_H4, 1, 3, rate);
   if(ArraySize(m_rate) > 0 && ArraySize(dataArr) > 0)
     {
      for(int i = 0; i < ArraySize(m_rate); i++)
        {
         if(
            (rate[0].close <= m_rate[i].high && rate[0].high >= m_rate[i].high) &&
            (rate[1].close <= m_rate[i].high && rate[1].high >= m_rate[i].high) &&
            (rate[2].close <= m_rate[i].high && rate[2].high >= m_rate[i].high)
         )
           {
            //
            Print("....resistance...");
            Print(" rate : ", rate[0].time, "  m_rate : ", m_rate[i].time, " ...index i  :", i);
            Print("..h4 high  :   ", rate[0].high, "... m high :  ", m_rate[i].high);
            Print("");//
           }
         if(
            (rate[0].close <= m_rate[i].high && rate[2].close > m_rate[i].high) &&
            (rate[0].high < rate[2].low) &&
            (dataArr[0] < 0 && dataArr[1] < 0 && dataArr[2] < 0) &&
            (dataArr[2] > dataArr[0])
         )
           {
            Print("....resistance broken...");
            Print(" rate : ", rate[0].time, "  m_rate : ", m_rate[i].time, " ...index i  :", i);
            Print("..h4 high  :   ", rate[0].high, "... m high :  ", m_rate[i].high);
            Print("");
           }
         if(
            (rate[0].close >= m_rate[i].high && rate[0].low <= m_rate[i].high) &&
            (rate[1].close >= m_rate[i].high && rate[1].low <= m_rate[i].high) &&
            (rate[2].close >= m_rate[i].high && rate[2].low <= m_rate[i].high)
         )
          {
            //
             Print("....resistance broken...");
             Print(" rate : ", rate[0].time, "  m_rate : ", m_rate[i].time, " ...index i  :", i);
             Print("..h4 high  :   ", rate[0].low, "... m high :  ", m_rate[i].high);
             Print("");
             //
           }
         if(rate[1].close >= m_rate[i].high && rate[2].close < m_rate[i].high)
           {
            //
             Print("....support broken...");
             Print(" rate : ", rate[0].time, "  m_rate : ", m_rate[i].time, " ...index i  :", i);
             Print("..h4 high  :   ", rate[0].high, "... m high :  ", m_rate[i].high);
             Print("");
             //
           }
         //
         if(
            (rate[0].close <= m_rate[i].low && rate[0].high >= m_rate[i].low) &&
            (rate[1].close <= m_rate[i].low && rate[1].high >= m_rate[i].low) &&
            (rate[2].close <= m_rate[i].low && rate[2].high >= m_rate[i].low)
         )
           {
            //
            Print("....resistance...");
            Print(" rate : ", rate[0].time, "  m_rate : ", m_rate[i].time, " ...index i  :", i);
            Print("..h4 high  :   ", rate[0].high, "... m high :  ", m_rate[i].low);
            Print("");//
           }
         if(rate[1].close <= m_rate[i].high && rate[2].close > m_rate[i].low)
           {
            //
             Print("....resistance broken...");
             Print(" rate : ", rate[0].time, "  m_rate : ", m_rate[i].time, " ...index i  :", i);
             Print("..h4 high  :   ", rate[0].high, "... m high :  ", m_rate[i].low);
             Print("");
             //
           }
         if(
            (rate[0].close >= m_rate[i].low && rate[0].low <= m_rate[i].low) &&
            (rate[1].close >= m_rate[i].low && rate[1].low <= m_rate[i].low) &&
            (rate[2].close >= m_rate[i].low && rate[2].low <= m_rate[i].low)
         )
           {
            //
             Print("... support...");
             Print("....resistance broken...");
             Print(" rate : ", rate[0].time, "  m_rate : ", m_rate[i].time, " ...index i  :", i);
             Print("..h4 high  :   ", rate[0].low, "... m high :  ", m_rate[i].low);
             Print("");
             //
           }
         if(rate[1].close >= m_rate[i].high && rate[2].close < m_rate[i].low)
           {
            //
             Print("....support broken...");
             Print(" rate : ", rate[0].time, "  m_rate : ", m_rate[i].time, " ...index i  :", i);
             Print("..h4 high  :   ", rate[0].high, "... m high :  ", m_rate[i].low);
             Print("");
             //
           }
        }
     }
//
   if(ArraySize(w_rate) > 0)
     {
      //for(int i = 0; i < ArraySize(w_rate); i++)
      // {
      /*
       if(
          (rate[0].close <= w_rate[i].high && rate[0].high >= w_rate[i].high) &&
          (rate[1].close <= w_rate[i].high && rate[1].high >= w_rate[i].high) &&
          (rate[2].close <= w_rate[i].high && rate[2].high >= w_rate[i].high)
       )
         {
          //
          Print("");
          Print(" rate : ", rate[0].time, "  w_rate : ", w_rate[i].time, " ...index i  :", i);
          Print("..h4 high :  ", rate[0].high, "  ... w high : ", w_rate[i].high);
          Print("");
         }
         /
      //  }
     }
  }


*/
//+------------------------------------------------------------------+
//
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
