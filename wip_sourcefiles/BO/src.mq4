#property copyright "blablabla"
#property link      "https://www.reddit.com/r/algoshitting"
#property version   "1.01"
//

input int    h1_value     = 30,
             h1_ma        = 5,
             k1_value     = 60,
             k1_ma        = 25,
             trade_dur    = 15,
             
             h2_value     = 5, 
             ATR_period   = 32, 
             //n          = 2,
             n_lookback  = 5,
             h_williamsS  = 55,
             h_williamsL  = 15,
             //h_momentum   = 10,
             //momentum_diff= 1,
             //momentum_max = 3,
             //h_rsi        = 10,
             //rsi_shift    = 1,
             williams_thresholdS = -2,
             williams_thresholdL = -86,
             ma_period1          = 7,
             ma_period2          = 14,
             ma_shift            = 14;
             
          
input double order_volume =  0.01,
             thres        = 0.01,
             ATR_max      = 0.0003,
             //kShort       =  0.45,
             //kLong        =  0.45,
             //corr_threshold = 0.66,
             broker_payout = 0.75,
             m_min         = 0,
             ma_threshold  = 1, //andel av symbol i prosent
             open_threshold = 1, //andel av symbol i prosent
             stake         = 100.0;

input bool testmode = true;

int put_winctr, put_lossctr, tick_events, temp_tick, 
    lossctr_old, winctr_old, drawctr_old, put_drawctr, rcontrol;
double payout, temprate;
datetime temptime;

int OnInit() { 
   
   return(INIT_SUCCEEDED); 
}
//
void OnDeinit(const int reason) { 
   //testing log append, husk å bytt filnavn for hver backtest.
   if(put_winctr + put_lossctr > 0) {
      double winrate = double(put_winctr)/((double)put_winctr+(double)put_lossctr);
   }
   else winrate = 0.0;
   string terminal_data_path = TerminalInfoString(TERMINAL_DATA_PATH);  
   string subfolder="Research";//"C:\\Users\\Eier\\Documents\\GitHub\\_data\\research\\backtesting_data_custom";
   int filehandle = FileOpen(subfolder+"\\EURUSD_1901_.csv",FILE_READ|FILE_WRITE|FILE_CSV);
   if(filehandle!=INVALID_HANDLE) {
      FileSeek(filehandle,0,SEEK_END); 
      FileWrite(filehandle, winrate );
      FileFlush(filehandle);
      FileClose(filehandle);
   }
   
   Print("wins: ", put_winctr);  
   Print("losses: ", put_lossctr);
   Print("draws: ", put_drawctr);
}

void OnTick()
{
   double HH_1 = iHigh(NULL, 0, iHighest(NULL, 0, MODE_HIGH, h1_value));
   double LL_1 = iLow(NULL, 0, iLowest(NULL, 0, MODE_LOW, h1_value));
   double HH_2 = iHigh(NULL, 0, iHighest(NULL, 0, MODE_HIGH, h2_value));
   double LL_2 = iLow(NULL, 0, iLowest(NULL, 0, MODE_LOW, h2_value));

   int slippage;
   
   lossctr_old = put_lossctr;
   winctr_old = put_winctr;
   
   if(Bars > h1_value + h2_value + 1) { 
     if(OrdersTotal() == 0) { 
        if( //probablyTZ(0) && 
            //isTrending(HH_1, LL_1, 0) //&&
            //williams(0) &&
            //maCheck() 
            //ma_trend() //&&
            //heikin()
            //growthCheck()
            //RSI(0) 
            //momentumTest(0)
            //newLow(LL_1)
            //stableMA() //dobbeltsjekk logikk
            //s20170103() && 
            //atrCheck()
            //s20170116_simple()
            //s20170116_2()
            s20170117_2(0)// commenting out only during long strat test.
            ) 
         {  
            
            //rcontrol = open_order(rcontrol, 0);
            if(rcontrol == 0)
               open_order(0); //0 = short
               //short script execute
            else rcontrol = open_rcontrol(0);
         }
         
       /*
         else if( probablyTZ(1) && 
             isTrending(HH_1, LL_1, 1) &&
             williams(1) ) 
         {  
          //ticket = OrderSend(Symbol(), OP_SELL, order_volume, Bid, 0,0,0);
            ticket = OrderSend(Symbol(), OP_BUY, order_volume, Ask, 0,0,0);
            //if(ticket > 0) temprate = Bid;
            return;
         }
         */
         else if(s20170117_2(1)) {
            if(rcontrol == 0) {
                open_order(1);
                //long script execute
            }
            else rcontrol = open_rcontrol(1);
         }
      
      }
   }
   
   
   
   for(int pos = OrdersTotal()-1; pos >= 0 ; pos--) { 
      if (OrderSelect(pos, SELECT_BY_POS) /*&&
          OrderMagicNumber() == Magic.Number*/ &&
          OrderSymbol()      == Symbol() )
      {  
         int duration = TimeCurrent() - OrderOpenTime();
         if (duration >= trade_dur * 60) {
            if(!OrderClose( OrderTicket(), OrderLots(), OrderClosePrice(), slippage))
               Print("Order close error. -", GetLastError());
            if(temprate < OrderClosePrice()) {
               put_lossctr++;
               rcontrol = 1;
            }
            else if(temprate == OrderClosePrice()) {
               put_drawctr++;
               rcontrol = 0;
            }
            else {
               put_winctr++;
               rcontrol = 0;
            }
         }
      }
   }
   
   if(testmode) {
      if(winctr_old < put_winctr || lossctr_old < put_lossctr || drawctr_old < put_drawctr) {
      
      //payout adjustion, martingale toggle
      
      //---
         payout += 0;
         if(winctr_old != put_winctr) {
            payout += broker_payout*stake;
         }
         else if(lossctr_old != put_lossctr) {
            payout -= stake;
         }
         
         //string terminal_data_path = TerminalInfoString(TERMINAL_DATA_PATH);  
         string subfolder="Research";//"C:\\Users\\Eier\\Documents\\GitHub\\_data\\research\\simulation_logs";
         int filehandle = FileOpen(subfolder+"\\log0401_.csv",FILE_READ|FILE_WRITE|FILE_CSV);
         if(filehandle != INVALID_HANDLE) {
            FileSeek(filehandle, 0, SEEK_END); 
            FileWrite(filehandle, payout);
            FileFlush(filehandle);
            FileClose(filehandle);
         }   
      }
   }
   
   lossctr_old = put_lossctr;
   winctr_old = put_winctr;
   drawctr_old = put_drawctr;
}   

int open_rcontrol (int mode)
{
   temprate = Bid;
   temptime = TimeCurrent();
   int duration1 = TimeCurrent() - temptime;
   if(duration1 <= trade_dur * 60) {
      if(temprate >= Bid) { 
         //rcontrol1 = 0;
         return 0;
      }
   }
   else open_rcontrol_cont(mode, temprate, duration1);
}

int open_rcontrol_cont (int mode, double temprate_, int duration_)
{
   if(duration_ <= trade_dur * 60) {
      if(temprate_ >= Bid) {
         return 0;
      }
   }
}

void open_order (int mode) 
{       
   switch(mode) {
      case 0:
         int ticket = OrderSend(Symbol(), OP_SELL, order_volume, Bid, 0,0,0);
         if(ticket > 0) temprate = Bid;
         break;
      case 1:
         ticket = OrderSend(Symbol(), OP_BUY, order_volume, Ask, 0,0,0);
         if(ticket > 0) temprate = Bid;
         break;
      default:
         Print("Invalid trade mode.");
         break;
   }
}

bool probablyTZ (int mode) //h1_value
{
   switch(mode) {
      case 0:
         if((iHighest(Symbol(), 0, MODE_HIGH, h1_value) == 1) &&
            (iClose(Symbol(), 0, 1) > iClose(Symbol(), 0, 2)))
            return true;
         break;
      case 1:
         if((iLowest(Symbol(), 0, MODE_LOW, h2_value) == 1) &&
            (iClose(Symbol(), 0, 1) < iClose(Symbol(), 0, 2)))
            return true;
      break;
      default:
         Print("Invalid pTZ mode");
         break;
   }
}   
   
bool isTrending (float HH1, //h1_value
                 float LL1,
                 int mode)
{
   switch(mode) {
      case 0:
         if(iHighest(Symbol(), 0, MODE_HIGH, h1_value) < iLowest(Symbol(), 0, MODE_LOW, h1_value)) //&&
         //iClose(Symbol(), 0, 1) < (HH1 - bear_threshold*(HH1-LL1)))
            return true;
         else return false;
       break;
       case 1:
         if(iHighest(Symbol(), 0, MODE_HIGH, h2_value) > iLowest(Symbol(), 0, MODE_LOW, h2_value)) //&&
         //iClose(Symbol(), 0, 1) < (HH1 - bear_threshold*(HH1-LL1)))
            return true;
         else return false;
       break;
       default:
         Print("Invalid isT mode.");
         break;     
   }
}
      
bool williams (int mode)
{
   switch(mode) {
      case 0:
         if(iWPR(Symbol(), 0, h_williamsS, 1) > williams_thresholdS)
            return true;
         else return false;
         break;
      case 1:
         if(iWPR(Symbol(), 0, h_williamsL, 1) < williams_thresholdL)
            return true;
         else return false;
         break;
      default:
         Print("Invalid williams mode.");
         break;
   }
}

bool atrCheck ()
{
   if(iATR(Symbol(), 0, ATR_period, 1) <= ATR_max) {
      if(iATR(Symbol(), 0, ATR_period, 1) <= iATR(Symbol(), 0, 2*ATR_period, 1))
         return true;
   }
}

bool s20170103_2 () //MERK. Dette er s20170103_2, altså nr 2. VIKTIG
{
   if((iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value)) == 
      iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, 2*h1_value))) &&
      iHighest(Symbol(), 0, MODE_HIGH, h1_value) >= h1_value -1) {
      if(Bid <= iHigh(Symbol(), 0, (iLowest(Symbol(), 0, MODE_LOW, h1_value))))
         return true;
   }
}

bool s20170103_3 () 
{
   if((iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, h1_value)) == 
      iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, 2*h1_value))) &&
      iLowest(Symbol(), 0, MODE_LOW, h1_value) >= h1_value -1) {
      if(iClose(Symbol(), 0, 1)/*Bid*/ >= iHigh(Symbol(), 0, (iHighest(Symbol(), 0, MODE_HIGH, h1_value))))
         return true;
   }
}

bool s20170116_simple ()
{
    if(iClose(Symbol(), 0, 1) == iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, n_lookback))) {
        if(iMA(Symbol(), 0, h1_value, 0, MODE_SMA, PRICE_MEDIAN, 0) == 
           iMA(Symbol(), 0, h1_value *2, 0, MODE_SMA, PRICE_MEDIAN, 0)) {
           return true;
        }
    }
}

bool s20170116_2 ()
{
    if(iMA(Symbol(), 0, h1_value, 0, MODE_SMA, PRICE_MEDIAN, 2) < iMA(Symbol(), 0, h1_value*2, 0, MODE_SMA, PRICE_MEDIAN, 2) &&
       iMA(Symbol(), 0, h1_value, 0, MODE_SMA, PRICE_MEDIAN, 1) > iMA(Symbol(), 0, h1_value*2, 0, MODE_SMA, PRICE_MEDIAN, 1))
       return true;
}

//insert s20170117() from laptop

bool s20170117_2 (int mode)
{
    double HH0 = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value, 0)),
           LL0 = iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, h1_value, 0)),
           HH1 = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, k1_value, 0)),
           LL1 = iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, k1_value, 0));
           
    switch(mode) {
        case 0:
            if(iMA(Symbol(), 0, h1_ma, 0, MODE_SMA, PRICE_MEDIAN, 0) > iMA(Symbol(), 0, h1_ma*2, 0, MODE_SMA, PRICE_MEDIAN, 0)) {           
                if(iClose(Symbol(), 0, 1) > HH0-(HH0-LL0)*thres) {
                    if(Bid <= HH0-(HH0-LL0)*thres) {
                        return true;
                    }
                    else break;
                }
            }
            break;
        case 1:
            if(iMA(Symbol(), 0, k1_ma, 0, MODE_SMA, PRICE_MEDIAN, 0) < iMA(Symbol(), 0, k1_ma*2, 0, MODE_SMA, PRICE_MEDIAN, 0)) {           
                if(iClose(Symbol(), 0, 1) < LL1+(HH1-LL1)*thres) {
                    if(Bid >= LL1+(HH1-LL1)*thres) {
                        return true;
                    }
                    else break;
                }
            }
            break;
        /*
        default:
            Print("Invalid mode strat s20170117_2()");
            break;
        */
    }
}