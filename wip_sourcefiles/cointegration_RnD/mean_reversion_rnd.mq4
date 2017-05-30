#property copyright " "
#property link      "github.com/saturdayquant"
#property version   "1.00"

input int save_mod  = 1, //set to 1 for realtime
          ma_period = 50;
          
input double w1_threshold_max = 0.002, 
             w1_threshold_min = 0.49,
             w2_threshold_max = 0.51,
             w2_threshold_min = 0.49,
             tp               = 0.005,
             sl               = 0.005,
             order_volume     = 0.01;

input bool toggle_storing = False;

//http://www.myfxbook.com/forex-market/correlation
//EURUSD-EURCAD: 92.8% correlation
//GBPSGD-GBPUSD: 97.7% correlation
//GBPCAD-GBPUSD: 96.3% correlation

input string other_symbol = "EURCAD"; //implies EURUSD as primary symbol

string SUBFOLDER = "Research/mean_reversion_rnd";
int filehandle;
float delta_val,
      this_close, other_close, this_sma, other_sma, pair_avg, 
      w1, 
      w2, 
      first_close = iClose(Symbol(), 0, 1); //attempt at eliminating zero division at first loop

//+------------------------------------------------------------------+
int OnInit() {
    if(toggle_storing) {
        string FILENAME = "\\" + TimeToStr(TimeCurrent(), TIME_DATE) + ".csv";
        filehandle = FileOpen(SUBFOLDER + FILENAME, FILE_READ|FILE_WRITE|FILE_CSV); 
    }
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    if(toggle_storing) {
        FileClose(filehandle);
    }
}
//+------------------------------------------------------------------+
void OnTick() {
    if(TimeCurrent() % save_mod == 0) {
    
        this_close = iClose(Symbol(), 0, 1);
        other_close = iClose(other_symbol, 0, 1);
        if(this_close == other_close) other_close = this_close + 0.0001;
        delta_val = MathAbs(other_close - this_close);
        
        pair_avg = (this_close + other_close)/2;
        this_sma = iMA(Symbol(), 0, ma_period, 0, MODE_SMA, PRICE_MEDIAN, 0);
        other_sma = iMA(other_symbol, 0, ma_period, 0, MODE_SMA, PRICE_MEDIAN, 0);
        
        /*
        Print("delta ", delta_val);
        Print("pair avg ", pair_avg);
        Print("sma", this_sma);
        */
        
        w1 = (pair_avg - this_sma)/delta_val;
        w2 = (other_sma - pair_avg)/delta_val;
       
            
        if(OrdersTotal() == 0) {
            if(w1 >= w1_threshold_max
                /*
              (MathMin(this_sma, this_close)*MathMax(other_sma, other_close) - MathMin(other_sma, other_close)*MathMax(this_sma, this_close))
             /(MathMax(this_sma, this_close)*MathMax(other_sma, other_close)) < w1_threshold_max */) {
                open_order(1);
                Print("w1: ", w1);
                Print("w2: ", w2);
                double open_bid = Bid;
            }
            //for hedge
            else if(w1 <= w1_threshold_min) {
            }
            
            if(w2 >= w1_threshold_max) {
                open_order(0);
            }
            //for hedge
            else if(w2 <= w2_threshold_min) {
            }
        }
        
        if(toggle_storing) {
            if(filehandle != INVALID_HANDLE) {
                FileSeek(filehandle, 0, SEEK_END); 
                FileWrite(filehandle, this_close, other_close, delta_val);
                FileFlush(filehandle);
            }
        }
        for(int pos = OrdersTotal()-1; pos >= 0 ; pos--) { 
            if(OrderSelect(pos, SELECT_BY_POS)    /*&&
               OrderMagicNumber() == Magic.Number*/ &&
               OrderSymbol()      == Symbol()) {  

                if(Bid <= open_bid + tp && 1==2) {
                    if(!OrderClose( OrderTicket(), OrderLots(), OrderClosePrice(), 3))
                        Print("Order close error. -", GetLastError());
                }
            }
        }
    }
}

void open_order (int mode) 
{       
    switch(mode) { 
        case 0:
            int ticket = OrderSend(Symbol(), OP_SELL, order_volume, Bid, 3, Bid+sl, Bid-tp, 0, 0);
            
            break;
        case 1:
            ticket = OrderSend(Symbol(), OP_BUY, order_volume, Ask, 3, Ask-sl, Ask+tp, 0, 0);

            break;
        case 2:
            ticket = OrderSend(other_symbol, OP_SELL, order_volume, Bid, 0,0,0);

            break;
        case 3:
            ticket = OrderSend(other_symbol, OP_BUY, order_volume, Ask, 0,0,0);
            
            break;
        default:
            Print("Invalid trade mode.");
            break;
    }
}