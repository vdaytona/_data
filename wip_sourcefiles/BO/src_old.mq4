#property copyright "blablabla"
#property link      "https://www.reddit.com/r/algoshitting"
#property version   "1.01"
//

input int    h1_value     = 24,
             h2_value     = 5, 
             trade_dur    = 15,
             //n            = 2,
             //n_periods  = 3,
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
             ma_shift            = 14,
             stoch_k             = 3,
             stoch_delay         = 3,
             stoch_d             = 1;
             
          
input double order_volume =  0.01,
             //kShort       =  0.45,
             //kLong        =  0.45,
             //corr_threshold = 0.66,
             stoch_testval = 0.01,
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
   string subfolder="Research";
   int filehandle = FileOpen(subfolder+"\\EURUSD_0101_.csv",FILE_READ|FILE_WRITE|FILE_CSV);
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
        if( probablyTZ(0) && 
            isTrending(HH_1, LL_1, 0) //&&
            //williams(0) 
            //maCheck()
            //ma_trend() //&&
            //heikin()
            //growthCheck()
            //RSI(0) 
            //momentumTest(0)
            //newLow(LL_1)
            //stableMA() //dobbeltsjekk logikk 
            ) 
         {  
            
            //rcontrol = open_order(rcontrol, 0);
            if(rcontrol == 0)
               open_order(0); //0 = short
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
         
         string terminal_data_path = TerminalInfoString(TERMINAL_DATA_PATH);  
         string subfolder="Research";
         int filehandle = FileOpen(subfolder+"\\log0101_.csv",FILE_READ|FILE_WRITE|FILE_CSV);
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
        //if(ticket > 0) temprate = Bid;
         break;
         
      /*implement hedge functionality.
      //fix   
         temptime = TimeCurrent();
         int duration1 = TimeCurrent() - temptime;
         while (duration1 <= trade_dur * 60) {
           //Sleep(1000);
         }
         int duration = TimeCurrent() - temptime;
         while(duration <= trade_dur*60)
         if(temprate >= Bid) { 
            rcontrol1 = 0;
         }
         return rcontrol1;
         break;
         */
         
      default:
         Print("Invalid trade mode.");
         break;
   }
}
/*
bool growthCheck () 
{
   //flawed
   if((iLow(NULL, 0, iLowest(NULL, 0, MODE_LOW, h1_value)) -
      iHigh(NULL, 0, iHighest(NULL, 0, MODE_HIGH, h1_value*n))) /
    (iLowest(NULL, 0, MODE_LOW, h1_value) - 
    iHighest(NULL, 0, MODE_HIGH, h1_value*n)) < m_min)
      return true;
   else return false;
}
*/
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

bool stableMA () 
{
   if((iMA(Symbol(), 0, 0, 0, MODE_SMA, PRICE_CLOSE, 2) <= iMA(Symbol(), 0, 0, 0, MODE_SMA, PRICE_CLOSE, 1) + ma_threshold*0.01) && 
       iMA(Symbol(), 0, 0, 0, MODE_SMA, PRICE_CLOSE, 2) >= iMA(Symbol(), 0, 0, 0, MODE_SMA, PRICE_CLOSE, 1) - ma_threshold*0.01)
      if(Bid - open_threshold*0.01 <= iMA(Symbol(), 0, 0, 0, MODE_SMA, PRICE_CLOSE, 1)) return true;
} //hva er forskjell på shift og ma_shift?

/*
bool RSI (int mode) 
{
   switch(mode) {
      case 0: 
         if(iRSI(Symbol(), 0, h_rsi, PRICE_HIGH, rsi_shift)) 
            return true;
         break;
      case 1:
         if(iRSI(Symbol(), 0, h_rsi, PRICE_LOW, rsi_shift)) 
            return true;
         break;
      default:
         Print("Invalid RSI mode.");
         break;
   }
}
*/
/*
void sbSleepForMS( int pviSleepForMS ) {

        if( !IsTesting() )
                Sleep(pviSleepForMS);
        else {
                //This section uses a while loop to simulate Sleep() during Backtest.
                int viSleepUntilTick    = GetTickCount() + pviSleepForMS;
                while( GetTickCount() < viSleepUntilTick ) {
                        //Do absolutely nothing. Just loop until the desired tick is reached.
                }
        }
}
*/
/*
bool maCheck ()
{
   double MA1 = iMA(Symbol(), 0, ma_period1, 0, MODE_SMA, PRICE_LOW, 1);
   double MA1_shift = iMA(Symbol(), 0, ma_period1, 0, MODE_SMA, PRICE_LOW, ma_shift);
   
   //if(MA2 > MA1) return true;
   
   //dy/dx
   if(((MA1-MA1_shift)/(ma_shift-1)) < ma_threshold) return true; //swap - (?)
   
}
*/
//HA1=iCustom(Symbol(),0,"Heiken_Ashi_Smoothed",MaMetod,MaPeriod,MaMetod2,MaPeriod2,2,i)
/*
bool momentumTest (int mode)
{
   switch(mode) {
      case 0:
         if(iMomentum(Symbol(), 0, h_momentum, PRICE_OPEN, 0) < 100) {
            int momentum_min;
            for(int i; i <= h_momentum; i++) {
               if(iClose(Symbol(), 0, i) < iClose(Symbol(), 0, i+1))
                  momentum_min++;
            }
         }
      case 1:
         if(iMomentum(Symbol(), 0, h_momentum, PRICE_OPEN, 0) > 100) {
            momentum_min = 0;
            for(i = 0; i <= h_momentum; i++) {
               if(iClose(Symbol(), 0, i) > iClose(Symbol(), 0, i+1))
                  momentum_min++;
            }
         }
      if(momentum_min >= momentum_max - momentum_diff)
         return true;
      else return false;
   }
}*/

/*
bool breakoutShort(float HH1, float LL1) 
{
   if((iClose(Symbol(), 0, 1) - iOpen(Symbol(), 0, 1)) > (HH1-LL1)*kShort)
      return true;
}
bool breakoutLong(float HH1, float LL1) 
{
   if(iClose(Symbol(), 0, 1) < iClose(Symbol(), 0, 2) - (HH1-LL1)*kLong)
      return true;
}
*/
/*
bool williamsShort () 
{
   if(iWPR(Symbol(), 0, h_williamsS, 1) > williams_thresholdS)
      return true;
   else return false;
}

bool williamsLong () 
{
   if(iWPR(Symbol(), 0, h_williamsL, 1) < williams_thresholdL)
      return true;
   else return false;
}
*/
/*
bool extremal_regression (
                          double HH_11, 
                          double LL_11,
                          double HH_21,
                          double LL_21)
{  
   
   double HH1_arr[], LL1_arr[],
          HH2_arr[], LL2_arr[];
          
   ArraySetAsSeries(HH1_arr[]);
   ArraySetAsSeries(HH2_arr[]);
   ArraySetAsSeries(LL1_arr[]);
   ArraySetAsSeries(LL2_arr[]);
          
   for(int x; x<(h1_value + h2_value)*n_periods; x++) {
      if(iHighest(Symbol(), 0, MODE_HIGH, h))
   }
   for(int i; i<=n_periods; i++){
      while(i == 1) HH1_arr[i] = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, i*h1_value);
      if(iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value) > HH1_arr[i+1];
   }
   
   double HH3 = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h2_value*3));
   double HH2 = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h2_value*2));
   double HH1 = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h2_value));
   
   if(HH3 > HH2 && HH2 > HH1) return true;
   /*
   if( (HH1 > HH2 && HH2 > HH3) &&
       (HH1 != HH2 && HH2 != HH3) ) {
      if( ((HH2-HH3)/
        (iHighest(Symbol(), 0, MODE_HIGH, h1_value*2) -
         iHighest(Symbol(), 0, MODE_HIGH, h1_value*3))) /
         ((HH1-HH2)/
        (iHighest(Symbol(), 0, MODE_HIGH, h1_value*1) -
         iHighest(Symbol(), 0, MODE_HIGH, h1_value*2))) < corr_threshold ) {
         return true;
         }
      else return false;
   }
   
}
*/
 /* if(iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value)) > iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value*2)) &&
      iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value*2))> iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value*3) {
      
      if((((iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value*2)) - 
          iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value*3)))  /
         (iHighest(Symbol(), 0, MODE_HIGH, h1_value*2) -
          iHighest(Symbol(), 0, MODE_HIGH, h1_value*3))) /
          
         ((iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value)) - 
          iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value*2))) /
         (iHighest(Symbol(), 0, MODE_HIGH, h1_value) -
          iHighest(Symbol(), 0, MODE_HIGH, h1_value*2)))) < corr_threshold1) {
         return true;
      }
      else return false;
         //usikker på om dette funker best long eller short...
   }*/

bool ma_trend ()
{
   double MA_L = iMA(Symbol(), 0, ma_period1, 0, MODE_SMA, PRICE_HIGH, 1);
   /*
   if(iLow(Symbol(), 0, 1) > MA_L) {
      if(//stoch_rep(2+stoch_delay) > 50 && stoch_rep(stoch_delay) < 50 && //kanskje stochrep(2*delay) skal være større, evt sett 2 som variabel.
         //stoch_rep(1) > 48 && stoch_rep(1) < 52 &&
         //iStochastic(Symbol(), 0, stoch_k, stoch_d, 0, MODE_SMA, PRICE_HIGH, 0, 1) < 52 &&
         iStochastic(Symbol(), 0, 1, 3, 0, MODE_SMA, PRICE_MEDIAN, 0, 1) > stoch_testval
         )
         return true;
   }
   */
   if(iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,0)>iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_SIGNAL,0)) return true;
}
/*
double stoch_rep (int stoch_shift)
{
   return iStochastic(Symbol(), 0, stoch_k, stoch_d, 0, MODE_SMA, PRICE_HIGH, 0, stoch_shift);
}
*
bool heikin () 
{

   //funker ikke
   double HAopen = iCustom(NULL,0,"Heiken Ashi", 2, iOpen(Symbol(), 0, 1));
   double HAclose = iCustom(NULL,0,"Heiken Ashi", 3, iClose(Symbol(), 0, 1));
   
   if(HAclose > HAopen) return true;
}
*/
bool newLow (double LL) 
{   
   if(LL >= iClose(Symbol(), 0, 2)) return true;
}

int candleType (int shift_ ) //(candleType == 1) = bullish, (candleType == 0) = bearish
{
   if((iOpen(Symbol(), 0, shift_) <= iClose(Symbol(), 0, shift_)) 
      return 1;
}

//------------------------------------------------------
// 01.01.2017 | "Oppdaget at dokumentasjon er lurt" | 1
//------------------------------------------------------
/*Backtestet EURUSD fra 2014.01.01 til 2016.11.27 med isTrending og probablyTZ. Beste resultat med tanke på trade-muligheter:

  01012017backtest.txt
  winrate            55.9% (+- 0.5%)
  pass               68	
  profit             18.81
  trades	            1311
  profit factor      1.05
  expected payoff	   0.01
  drawdown($)        29.85
  drawdown(%)        0.30%
  h1_value=140 	trade_dur=11
  
  Uviktige variabelverdier:
  h2_value=5 	h_williamsS=35 	h_williamsL=15 	williams_thresholdS=-6 	williams_thresholdL=-86 	ma_period1=7
  ma_period2=14 	ma_shift=14 	stoch_k=3 	stoch_delay=3 	stoch_d=1 	order_volume=0.01 	stoch_testval=0.01
  broker_payout=0.75 	m_min=0 	ma_threshold=-0.5 	open_threshold=1 	stake=100 	testmode=0*/

/*Hvis timeframe i i(Close/High/Low/Open) settes til 0 vil datakvaliteten gå ned som følger av lav 60-sec qual(25%).
  Kanskje også multipliseres h_value med timeframe siden den er ment for 1-min.
  Eks h_value = 100 testet i 5-min er faktisk h_value lik 100*5=500*/

/*Jobbet med testing av average true range ATR mot Bid for edge i divergence. Brukte moddet corr_stats.mq4                                                                
  Kan lagre data til fil i flere kolonner adskilt av komma(",") skrevet med ekvivalent til matlabs fprintf(fID,'%d\n', var)
  Unngår stor stor O = O(N^2) ved å ikke gjennomføre regresjon (least squares eller K-means(?)), tester kun for differanse og sparer R = O(N^2-n) optimaliseringstid*/
  
/*Muligheter for at en ATR-graf med shift har høy R^2 i sammenlignet med normalisert pris. Kanskje en edge i deltaverdier her.*/
                              
/*Se etter github-widget for MT4, - eller 5, hvis det er mulig å porte .mq4 -> .mq5 eller kjøre .mq4 direkte i MT5. Evt. laste opp dokumenter til github direkte fra sourcelibrary. Trenger backup.*/

//------------------------------------------------------
// 02.01.2017 | "Ny TZ-ide og GitHub-integrasjon" | 2
//------------------------------------------------------
/*Mulig strategi. Vent til confirmed TZ. Hvis hTZ, vent til pTZ(allerede lavere enn hTZ) erstattes med ny pTZ. Åpne put order(BO). 
  Ser lovende ut fra grafene. Vurder automatisering.
  
  Logikk bak er statistisk bias for hTZ etter lTZ vice versa. Vet også at sanne TZ har relativt lav sannsynlighet for å oppstå. 
  Kan være lurt å finne ut hvor sannsynlig det er at en hpTZ oppstår etter konsekutive lpTZ. Finn også tall på hvor mange konsekutive som er normalen el.*/

/*Kan være lurt å partisjonere hovedprogrammet, altså importere funksjoner foran skrive dem i hovedfil (om mulig i mql4~)*/

/*Mulig strategi. Bruk realtime værdata og strømpriser til å valuere crude brent eller heating oil. Kommer sannsynligvis til å 
  fungere dårlig inntil oljen går inn ranging-marked (mulig 85usd 4. kvartal 2017).*/
  
/*Startet GitHub-integrasjon. Mangler fortsatt mesteparten av kildekoden.*/

//------------------------------------------------------
// xx.xx.2017 | "Tittel" | n.te
//------------------------------------------------------
/**/

/**/