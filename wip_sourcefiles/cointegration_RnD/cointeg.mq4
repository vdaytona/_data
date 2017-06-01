#property copyright " "
#property link      "github.com/saturdayquant"
#property version   "1.00"

input int save_mod  = 1, //set to 1 for realtime
          period    = 50,
          skew      = 25,
          ordertype = 0;
          
input double tp               = 0.005,
             sl               = 0.005,
             ratio_delta      = 0.175,
             risk             = 0.00005,
             order_volume     = 0.01;

input bool toggle_storing     = false,
           toggle_volumecalc  = false,
           toggle_sign        = true;

//http://www.myfxbook.com/forex-market/correlation
//EURUSD-EURCAD: 92.8% correlation
//GBPSGD-GBPUSD: 97.7% correlation
//GBPCAD-GBPUSD: 96.3% correlation

input string other_symbol = "EURCAD"; //implies EURUSD as primary symbol

string SUBFOLDER = "Research/mean_reversion_rnd";
int filehandle;
double delta_val,
      this_close, other_close, open_rate,
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
    
        this_close = iClose(Symbol(), 0, 0);
        other_close = iClose(other_symbol, 0, 0);
        if(this_close == other_close) other_close = this_close + 0.0001; //?
        delta_val = MathAbs(other_close - this_close);
        
        double this_high = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, period));
        double other_high = iHigh(other_symbol, 0, iHighest(other_symbol, 0, MODE_HIGH, period));

        double this_low = iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, period));
        double other_low = iLow(other_symbol, 0, iLowest(other_symbol, 0, MODE_LOW, period));
        
        double this_ratio = (this_close - this_low)/(this_high - this_low);
        double other_ratio = (other_close - other_low)/(other_high - other_low);
        
              
        if(OrdersTotal() == 0) {
            if((this_ratio <= 0.95 || this_ratio >= 0.05) && (other_ratio <= 0.95 || other_ratio >= 0.05)) {
                switch(toggle_sign) {
                    case true:
                        if(this_ratio - other_ratio >= ratio_delta && iHighest(Symbol(), 0, MODE_HIGH, period) >= skew 
                                                                   && iLowest(Symbol(), 0, MODE_LOW, period) >= skew) {
                            open_order(ordertype);
                            open_rate = Bid;
                            Print("other ratio: ", other_ratio);
                            Print("this ratio: ", this_ratio);
                        }
                        break;
                    case false:
                        if(this_ratio - other_ratio <= ratio_delta && iHighest(Symbol(), 0, MODE_HIGH, period) >= skew 
                                                                   && iLowest(Symbol(), 0, MODE_LOW, period) >= skew) {
                            open_order(ordertype);
                            open_rate = Ask;
                            Print("other ratio: ", other_ratio);
                            Print("this ratio: ", this_ratio);
                        }
                        break;
                    default:
                        Print("Invalid perspective\n");
                        break;
                }
            }
        }
        
        if(toggle_storing) {
            if(filehandle != INVALID_HANDLE) {
                FileSeek(filehandle, 0, SEEK_END); 
                FileWrite(filehandle, this_ratio, other_ratio);
                FileFlush(filehandle);
            }
        }
        for(int pos = OrdersTotal() - 1; pos >= 0 ; pos--) { 
            if(OrderSelect(pos, SELECT_BY_POS)    /*&&
               OrderMagicNumber() == Magic.Number*/ &&
               OrderSymbol()      == Symbol()) {

                if(MathAbs(this_ratio - other_ratio) < 0.05 || Bid - (open_rate - tp + 2*tp*double(ordertype)) <= 0.0002) {
                    if(!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3))
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
            int ticket = OrderSend(Symbol(), OP_SELL, order_volume_(), Bid, 3, Bid+sl, 0, 0, 0);
            break;
        case 1:
            ticket = OrderSend(Symbol(), OP_BUY, order_volume_(), Ask, 3, Ask-sl, 0, 0, 0);
            //ticket = OrderSend(Symbol(), OP_BUY, order_volume, Ask, 3, Ask-sl, 0, 0, 0);
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

double order_volume_()
{
    if(toggle_volumecalc) return AccountEquity()*risk;
    else return order_volume;
}