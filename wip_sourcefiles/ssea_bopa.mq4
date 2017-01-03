//+------------------------------------------------------------------+
//|                                                    ssea_bopa.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
input int h_value, 
          bars_limit,
          trade_dur;
input double k_value,
             k1_value,
             order_volume;
//global variables
int put_winctr, put_lossctr, call_winctr, call_lossctr;

int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectDelete("put_winctr"); 
   ObjectDelete("put_lossctr"); 
   ObjectDelete("call_winctr");
   ObjectDelete("call_lossctr"); 
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   double LL = iHigh(NULL, 0, iHighest(NULL, 0, MODE_HIGH, h_value));
   double HH = iLow(NULL, 0, iLowest(NULL, 0, MODE_LOW, h_value));
   MqlRates mrate[];
   double p_close[];
   double Threshold = k1_value*(HH-LL);
   ArraySetAsSeries(p_close, true);
   p_close[0] = mrate[1].close;
   
   DrawText("put_winctr", "Put wins: " + IntegerToString(put_winctr), 2);
   DrawText("put_lossctr", "Put losses: " + IntegerToString(put_lossctr), 4);
   DrawText("call_winctr", "Call wins: " + IntegerToString(call_winctr), 6);
   DrawText("call_lossctr", "Call losses: " + IntegerToString(call_lossctr), 8);
   
   if(OrdersTotal() == 0) {
      if(HH-p_close[0] < Threshold) { //PUT
         OrderSend(NULL, OP_SELL, order_volume, Bid, 0, 0, 0, NULL, 0, trade_dur, clrRed);
         if(p_close[-trade_dur] < p_close[0]) put_winctr++;
         else put_lossctr++;
      }
      else if(p_close[0]-LL < Threshold) { //CALL
         OrderSend(NULL, OP_BUY, order_volume, Bid, 0, 0, 0, NULL, 0, trade_dur, clrRoyalBlue);
         if(p_close[-h_value] > p_close[0]) call_winctr++;
         else call_lossctr++;
      }
   }
}
//+------------------------------------------------------------------+
void DrawText(string str_name,
              string str,
              int y_dist)
{
   ObjectCreate(str_name, OBJ_LABEL, 0, 0, 0);
   ObjectSetText(str_name, str, 10, "Courier new");
   ObjectSet(str_name, OBJPROP_CORNER, 0);
   ObjectSet(str_name, OBJPROP_XDISTANCE, 10);
   ObjectSet(str_name, OBJPROP_YDISTANCE, 10*y_dist);
}