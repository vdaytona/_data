#property copyright "me"
#property link      "https://github.com/saturdayquant/"
#property version   "2.0"

input int    h1_value         =  30,
             h1_ma            =   5,
             k1_value         =  60,
             k1_ma            =  25,
             trade_dur        =  15,
             wrate_lookback   = 100, //maximum 300 because of limited array bounds.
             ratio_multiplier =  75,
             cciint           = 150;
             //denom            =   5,
             //modulo_2         =  50,  
             //modulo           =  50;
input string ______________________;
                       
input double order_volume  =   0.01,
             bankroll      =5000.0,
             risk_q        =   0.5,
             //max_wrate     =   0.5,
             //ax_thres     =   0.0008,
             //ax_thres_min  =  -0.0008,
             k_delta_calc  =   0.80,
             //k_mini        =   0.000016,
             thres         =   0.01,
             broker_payout =   0.75,    
             wrate_target  =   0.57,
             stake         = 100.00;
input string _____________________;

input bool testmode = true,
           toggle_kcriterion = true;

int put_lossctr, put_winctr, call_lossctr, call_winctr, 
    tick_events, temp_tick, pos, 
    put_winctr_old, put_lossctr_old, call_winctr_old, call_lossctr_old, drawctr_old, put_drawctr, simulated, 
    current_order_type, slippage, simulated_mode, ctr_change, call_temp_ctr, put_temp_ctr,
    wrateOk_call, wrateOk_put,
    put_sum, call_sum, n_simulated_put, n_simulated_call, n_simulated_put_old, n_simulated_call_old, intoWalk;

int call_history[200], //wrate_lookback +1.
    put_history[200];
    
double put_wrate_history[200],
       call_wrate_history[200],
       put_avg_arr[6],
       call_avg_arr[6],
       put_median_arr[200],
       call_median_arr[200],
       yy[200],
       zz[200];

double payout, temprate, kc_stake,
       put_wrate_avg, call_wrate_avg, put_wrate_delta_sum, call_wrate_delta_sum, ax_put, ax_call, mode_wrate;
       
       double ax_thres = (0.05*MathPow(0.016, k_delta_calc))/(ratio_multiplier*k_delta_calc/wrate_lookback); //k_delta_calc*wrate_lookback*k_mini; //double ax_thres = 0.002*k_delta_calc;
       double ax_thres_min = -0.66*ax_thres; //~~0
       
datetime dt, dt2;

int OnInit() { 
    return(INIT_SUCCEEDED); 
}
//
void OnDeinit(const int reason) { 
    //testing log append, husk å bytt filnavn for hver backtest.
    if(put_lossctr + put_winctr > 0 && call_lossctr + call_winctr > 0) {
        double winrate_put = double(put_winctr)/((double)put_lossctr+(double)put_winctr);
        double winrate_call = double(call_winctr)/((double)call_lossctr+(double)call_winctr);
    }
    else {
        winrate_put = 0.0; 
        winrate_call = 0.0; //Flawed in some cases.
    }
    string terminal_data_path = TerminalInfoString(TERMINAL_DATA_PATH);  
    string subfolder="Research";//"C:\\Users\\Eier\\Documents\\GitHub\\_data\\research\\backtesting_data_custom";
    int filehandle = FileOpen(subfolder+"\\EURUSD_0602_.csv",FILE_READ|FILE_WRITE|FILE_CSV);
    if(filehandle!=INVALID_HANDLE) {
        FileSeek(filehandle,0,SEEK_END); 
        FileWrite(filehandle, payout+bankroll);
        FileFlush(filehandle);
        FileClose(filehandle);
    }
   
    Print("put losses: ", put_lossctr);
    Print("put wins: ", put_winctr);
    Print("call losses: ", call_lossctr);  
    Print("call wins: ", call_winctr);
    Print("draws: ", put_drawctr);
    Print("kelly criterion bankroll: ", bankroll+payout);
}

void OnTick()
{
    //presiser mer etter modus
    /*
    if(n_simulated_call + call_winctr + call_lossctr >= wrate_lookback) {
        
        if(call_wrate_avg >= wrate_target && ax_call >= ax_thres_min) { 
            wrateOk_call = 1; 
        }
        else if(ax_call >= ax_thres && call_avg_arr[5] > call_avg_arr[4]) {
            wrateOk_call = 1;
        }
        else if(ax_call <= -1.5*ax_thres && call_wrate_avg <= (1-wrate_target)) {
            wrateOk_call = 2;
        }
        if((n_simulated_call + call_winctr + call_lossctr) % modulo_2 == 0 && call_temp_ctr != n_simulated_call + call_winctr + call_lossctr) {
            call_temp_ctr = n_simulated_call + call_winctr + call_lossctr;

            //wrateOk_put = 1;
            ArrayCopy(yy, call_wrate_history, WHOLE_ARRAY-wrate_lookback+1, 0, wrate_lookback-1);
            ArraySort(yy, WHOLE_ARRAY, 0, MODE_ASCEND);
            double temp_median = yy[int(MathFloor(wrate_lookback/2))];//(call_wrate_history[ArrayMaximum(call_wrate_history, wrate_lookback-1, WHOLE_ARRAY-wrate_lookback+1)] + call_wrate_history[ArrayMinimum(call_wrate_history, wrate_lookback-1, WHOLE_ARRAY-wrate_lookback+1)])/2;//yy[int(MathFloor(wrate_lookback/2))]; //yy[50];
            
            //Print(temp_median);
            
            for(int x = 0; x <= 1; x++) {
                call_median_arr[x] = call_median_arr[x+1];
            }
            call_median_arr[2] = temp_median;
            
            Print("x1 ",call_median_arr[2]);
            Print("x2 ",call_median_arr[1]);
            Print("x3 ",call_median_arr[0]);
        }
        if(call_median_arr[2] >= call_median_arr[1]) {
            wrateOk_call = 1;
        }
        if(ArrayMinimum(call_wrate_history, wrate_lookback, WHOLE_ARRAY-wrate_lookback+1) > 
           ArrayMaximum(call_wrate_history, wrate_lookback, WHOLE_ARRAY-wrate_lookback+1) && 
           ArrayMinimum(call_wrate_history, wrate_lookback, WHOLE_ARRAY-wrate_lookback+1) > int(MathFloor(wrate_lookback/denom)) &&
           call_wrate_history[ArrayMinimum(call_wrate_history, wrate_lookback, WHOLE_ARRAY-wrate_lookback+1)] <= max_wrate) { //kanskje mindre, evt. parametriser 5.
            wrateOk_call = 1;
        }
        //if(call_wrate_history[wrate_lookback-1] > put_wrate_history[wrate_lookback-1])
            //wrateOk_call = 1;
    }
    else wrateOk_call = 0; 
    */
    /*
    if(n_simulated_put + put_winctr + put_lossctr >= wrate_lookback) { //commenting out w lookback produces trailing, but unaccurate wrate growth.
    
        if(MathAbs(call_wrate_history[wrate_lookback-1] - put_wrate_history[wrate_lookback-1]) >= asdfg && 
                   call_wrate_history[wrate_lookback-1] < put_wrate_history[wrate_lookback-1]) wrateOk_put = 1;
        else wrateOk_put = 0;
    
        if(put_wrate_avg >= wrate_target && ax_call >= ax_thres_min) { 
            wrateOk_put = 1; 
        }
        if(ax_put >= ax_thres && put_avg_arr[5] > put_avg_arr[4]) {
            wrateOk_put = 1;
        }/*
        else if(ax_put <= -1.5*ax_thres && put_wrate_avg <= (1-wrate_target)) {
            wrateOk_put = 2;
        }
    *//*
        if((n_simulated_put + put_winctr + put_lossctr) % modulo == 0 && put_temp_ctr != n_simulated_put + put_winctr + put_lossctr) {
            put_temp_ctr = n_simulated_put + put_winctr + put_lossctr;

            //wrateOk_put = 1;
            ArrayCopy(zz, put_wrate_history, WHOLE_ARRAY-wrate_lookback+1, 0, wrate_lookback-1);
            ArraySort(zz, WHOLE_ARRAY, 0, MODE_ASCEND);
            temp_median = zz[int(MathFloor(wrate_lookback/2))]; //(put_wrate_history[ArrayMaximum(put_wrate_history, wrate_lookback-1, WHOLE_ARRAY-wrate_lookback+1)] + put_wrate_history[ArrayMinimum(put_wrate_history, wrate_lookback-1, WHOLE_ARRAY-wrate_lookback+1)])/2;//yy[int(MathFloor(wrate_lookback/2))]; //yy[50];
          
            for(x = 0; x <= 1; x++) {
                put_median_arr[x] = put_median_arr[x+1];
            }
            put_median_arr[2] = temp_median;
            
            Print("1 ",put_median_arr[2]);
            Print("2 ",put_median_arr[1]);
            Print("3 ",put_median_arr[0]);
            
        }
        if(put_median_arr[2] >= put_median_arr[1]) {
            wrateOk_put = 1;
        }
        else {
            wrateOk_put = 0;
        }
        if(ArrayMinimum(put_wrate_history, wrate_lookback, WHOLE_ARRAY-wrate_lookback+1) > 
           ArrayMaximum(put_wrate_history, wrate_lookback, WHOLE_ARRAY-wrate_lookback+1) && 
           ArrayMinimum(put_wrate_history, wrate_lookback, WHOLE_ARRAY-wrate_lookback+1) > int(MathFloor(wrate_lookback/denom)) &&
           put_wrate_history[ArrayMinimum(put_wrate_history, wrate_lookback, WHOLE_ARRAY-wrate_lookback+1)] <= max_wrate) { //kanskje mindre, evt. parametriser 5.
            wrateOk_put = 1;
        }
        //if(call_wrate_history[wrate_lookback-1] < put_wrate_history[wrate_lookback-1])
            //wrateOk_put = 1;
    }
    else {
        wrateOk_put = 0;
    }*/
    
    /*
    put_winctr_old = put_winctr;
    put_lossctr_old = put_lossctr;
    call_winctr_old = call_winctr;
    call_lossctr_old = call_lossctr;
    drawctr_old = put_drawctr;
    n_simulated_call_old = n_simulated_call;
    n_simulated_put_old = n_simulated_put;
    */
    wrateOk_put  = 1;
    wrateOk_call = 1;
    
    if(Bars > h1_value + 1) { 
        if(OrdersTotal() == 0) { 
            if(s20170117_2(0)) {
                if(simulated == 0 &&
                  (put_lossctr + put_winctr + n_simulated_put <= wrate_lookback || 
                   wrateOk_put == 1) && TimeCurrent() - dt >= trade_dur*60) {          
                    open_order(0); //0 = short
                    simulated = 0;
                    n_simulated_put++;
                }
                else if(wrateOk_put == 2)
                    open_order(1); //kun en test.
                /*
                else {
                    open_order(2);
                    simulated = 1; //skru av simulated etter trade duration. ved å simulated == 0 som condition forsikrer at timecurrent - dt > trade duration
                    simulated_mode = 0;
                }
                */
                current_order_type = OP_SELL;
             
            }
            else if(s20170117_2(1)) {
                if(simulated == 0 &&
                  (call_lossctr + call_winctr + n_simulated_call <= wrate_lookback || 
                   wrateOk_call == 1) && TimeCurrent() - dt >= trade_dur*60) {
                    open_order(1); //1 = long
                    simulated = 0;
                }
                else if(wrateOk_call == 2)
                    open_order(0); //kun en test.
                /*
                else {
                    open_order(3);
                    simulated = 1; //kanskje snu til if, snu øverste til if else pga. hvis simulated == 1 bør ikke order executes. 
                    simulated_mode = 1;
                }
                */
                current_order_type = OP_BUY;
            }
        }
    }
    if(simulated == 1 && TimeCurrent() - dt >= trade_dur*60 ) {
        simulated = 0;
        switch(simulated_mode) {
            case 0:
                if(temprate > Bid) {
                    intoWalk = 1;
                    n_simulated_put++;
                }
                else intoWalk = 0;
       
                for(int i = 0; i < wrate_lookback-1; i++) {
                    put_history[i] = put_history[i+1];
                }
                put_history[wrate_lookback-1] = intoWalk;
                if(put_lossctr + put_winctr + n_simulated_put >= wrate_lookback) {
                    put_sum = 0;
                    
                    for(int m = 0; m < wrate_lookback; m++) {
                        put_sum += put_history[m];
                    }
                    
                    put_wrate_avg = double(put_sum)/double(wrate_lookback);
                    Print("put sim avg: ", put_wrate_avg);
                       
                    //acceleration arr test
                    for(i = 0; i <= 5-1; i++) {
                        put_avg_arr[i] = put_avg_arr[i+1];
                    }
                    put_avg_arr[5] = put_wrate_avg;
                }   
                break;
            case 1:
                if(temprate <= Bid) {
                    intoWalk = 1;
                    n_simulated_call++;
                }
                else intoWalk = 0;
                
                for(i = 0; i < wrate_lookback-1; i++) {
                    call_history[i] = call_history[i+1];
                }
                call_history[wrate_lookback-1] = intoWalk;
                if(call_lossctr + call_winctr + n_simulated_call>= wrate_lookback) {
                    call_sum = 0; 
                    
                    for(int n = 0; n < wrate_lookback; n++) {
                        call_sum += call_history[n];
                    }    
                    
                    call_wrate_avg = double(call_sum)/double(wrate_lookback);
                    Print("call sim avg: ", call_wrate_avg);
                
                    //acceleration arr test
                    for(i = 0; i <= 5-1; i++) {
                        call_avg_arr[i] = call_avg_arr[i+1];
                    }
                    call_avg_arr[5] = call_wrate_avg;   
                }
                break;
            default:
                Print("Invalid simulated trade mode. Possible arithmetic or time issue.");
                break;
        }
    }

    for(pos = OrdersTotal()-1; pos >= 0 ; pos--) { 
        if((OrderSelect(pos, SELECT_BY_POS)    /*&&
           OrderMagicNumber() == Magic.Number*/ &&
           OrderSymbol()      == Symbol()) || simulated == 1) {  
           
            int duration = TimeCurrent() - OrderOpenTime();
            if (duration >= trade_dur * 60 /*|| TimeCurrent() - dt >= trade_dur*60*/) {
       
                if(!OrderClose( OrderTicket(), OrderLots(), OrderClosePrice(), slippage))
                    Print("Order close error. -", GetLastError()); 
                if(temprate < OrderClosePrice()) {
                    if(current_order_type == OP_BUY) { 
                        call_winctr++; 
                        intoWalk = 1;
                        
                        for (i = 0; i < wrate_lookback-1; i++) {
                            call_history[i] = call_history[i+1];
                        }
                        call_history[wrate_lookback-1] = intoWalk;              
                    }
                    else if(current_order_type == OP_SELL) { 
                        put_lossctr++; 
                        intoWalk = 0;
                        
                        for (int j = 0; j < wrate_lookback-1; j++) {
                            put_history[j] = put_history[j+1];
                        }
                        put_history[wrate_lookback-1] = intoWalk;                 
                    }
                }
                else if(temprate == OrderClosePrice())
                    put_drawctr++;
                else {
                    if(current_order_type == OP_BUY) {
                        call_lossctr++;
                        intoWalk = 0;
                      
                        for (int k = 0; k < wrate_lookback-1; k++) {
                            call_history[k] = call_history[k+1];
                        }
                        call_history[wrate_lookback-1] = intoWalk;                   
                    }
                    else if(current_order_type == OP_SELL) { 
                        put_winctr++;
                        intoWalk = 1;
                        
                        for (int l = 0; l < wrate_lookback-1; l++) {
                            put_history[l] = put_history[l+1];
                        }
                        put_history[wrate_lookback-1] = intoWalk;
                    }
                }
            
                if(put_lossctr + put_winctr + n_simulated_put>= wrate_lookback) {
                    put_sum = 0;
                    
                    for(m = 0; m < wrate_lookback; m++) {
                        put_sum += put_history[m];
                    }
                    
                    put_wrate_avg = double(put_sum)/double(wrate_lookback);
                    //Print("put total wrate: ", put_wrate_avg);
                    
                    //acceleration arr test
                    for(i = 0; i <= 5-1; i++) {
                        put_avg_arr[i] = put_avg_arr[i+1];
                    }
                    put_avg_arr[5] = put_wrate_avg;
                }
                
                if(call_lossctr + call_winctr + n_simulated_call>= wrate_lookback) {
                    call_sum = 0; 
                    
                    for(n = 0; n < wrate_lookback; n++) {
                        call_sum += call_history[n];
                    }    
                    
                    call_wrate_avg = double(call_sum)/double(wrate_lookback);
                    //Print("call total wrate: ", call_wrate_avg);
                    
                    //acceleration arr test
                    for(i = 0; i <= 5-1; i++) { //arbitrary
                        call_avg_arr[i] = call_avg_arr[i+1];
                    }
                    call_avg_arr[5] = call_wrate_avg; 
                }
            }
        }
    }
    
    //flytt ned i funksjon for å spare plass
    if(put_lossctr_old      <     put_lossctr || 
       put_winctr_old       <      put_winctr || 
       drawctr_old          <     put_drawctr ||
       call_lossctr_old     <    call_lossctr ||
       call_winctr_old      <     call_winctr ||
       n_simulated_put_old  < n_simulated_put ||
       n_simulated_call_old < n_simulated_call) {
        if(put_lossctr_old       <  put_lossctr || 
           put_winctr_old        <   put_winctr)
            ctr_change = 2;
        else if(call_lossctr_old < call_lossctr ||
                call_winctr_old  <  call_winctr)
            ctr_change = 3;
        if(n_simulated_put_old  < n_simulated_put)
            ctr_change = 4;
        else if(n_simulated_call_old < n_simulated_call) //declare
            ctr_change = 5;
    }
    else ctr_change = 0;
    //
    if(testmode) { 
        switch(toggle_kcriterion) {
            case true:
                if(put_lossctr + put_winctr + call_lossctr + call_winctr >= wrate_lookback*2.5) {
                    if(ctr_change == 2 || ctr_change == 3) {
                        payout += 0; //redundant
                        if(ctr_change == 2) 
                            mode_wrate = put_wrate_history[wrate_lookback-1];
                        else if(ctr_change == 3) 
                            mode_wrate = call_wrate_history[wrate_lookback-1];
                        if(mode_wrate == 0) mode_wrate = 0.5;
                        
                        kc_stake = risk_q*(bankroll+payout)*(broker_payout*mode_wrate-(1-mode_wrate))/broker_payout;
                        kc_stake = risk_q*(bankroll+payout)*(broker_payout*mode_wrate-(1-mode_wrate))/broker_payout;
                        
                        if(put_lossctr_old != put_lossctr) {
                            payout += -kc_stake;
                        }
                        else if(put_winctr_old != put_winctr) {
                            payout += broker_payout*kc_stake;
                        }
                        else if(call_lossctr_old != call_lossctr) {
                            payout += -kc_stake;
                        }
                        else if(call_winctr_old != call_winctr) {
                            payout += broker_payout*kc_stake;
                        }
                    //}
                    }
                }
                else {
                    payout += 0; //redundant
                    if(put_lossctr_old != put_lossctr) {
                        payout += -stake;
                    }
                    else if(put_winctr_old != put_winctr) {
                        payout += broker_payout*stake;
                    }
                    else if(call_lossctr_old != call_lossctr) {
                        payout += -stake;
                    }
                    else if(call_winctr_old != call_winctr) {
                        payout += broker_payout*stake;
                    }
                }
                break;
            case false:
                if(ctr_change == 2 || ctr_change == 3) {
                    payout += 0; //redundant
                    if(put_lossctr_old != put_lossctr) {
                        payout += -stake;
                    }
                    else if(put_winctr_old != put_winctr) {
                        payout += broker_payout*stake;
                    }
                    else if(call_lossctr_old != call_lossctr) {
                        payout += -stake;
                    }
                    else if(call_winctr_old != call_winctr) {
                        payout += broker_payout*stake;
                    }
                }
                break;
            default:
                Print("Invalid testmode input: kelly criterion error");
                break;
        }
        //string terminal_data_path = TerminalInfoString(TERMINAL_DATA_PATH);  
        //int filehandle = FileOpen(terminal_data_path+"\\log2101_.csv",FILE_READ|FILE_WRITE|FILE_CSV);
        if(ctr_change == 2 || ctr_change == 3) { //(!)
            string subfolder="Research";//"C:\\Users\\Eier\\Documents\\GitHub\\_data\\research\\simulation_logs"; 
            int filehandle = FileOpen(subfolder+"\\log0206_2.csv",FILE_READ|FILE_WRITE|FILE_CSV);
            
            if(filehandle != INVALID_HANDLE) {
                FileSeek(filehandle, 0, SEEK_END); 
                FileWrite(filehandle, mode_wrate, payout+bankroll);//payout, put_median_arr[2], call_median_arr[2]); 
                FileFlush(filehandle);
                FileClose(filehandle);
            }
        }
    }
    
    //Commenting out below because of probably faulty calculation because of wrong array end. Also unnecessary
    if(ctr_change == 2 || ctr_change == 4) {
        //wrate logging array, put                 
        for(int q = 0; q < wrate_lookback-1; q++) {
            put_wrate_history[q] = put_wrate_history[q+1];
        }
        put_wrate_history[wrate_lookback-1] = put_wrate_avg;
        //double ax_calc = wrate_lookback - MathFloor(k_delta_calc*(double)wrate_lookback);
        //double ax_calc = 8;
        double ax_calc = wrate_lookback*k_delta_calc;
        /*
        put_wrate_delta_sum = 0;
        for(q = 1; q <= ax_calc; q++) {
            put_wrate_delta_sum += put_wrate_history[wrate_lookback-q] - put_wrate_history[wrate_lookback-q-1];
        }
        ax_put = put_wrate_delta_sum/ax_calc;
        //Print("ax put: ", ax_put);
        */
    }
    else if(ctr_change == 3 || ctr_change == 5) {
        //wrate logging array, call                 
        for(int r = 0; r < wrate_lookback-1; r++) {
            call_wrate_history[r] = call_wrate_history[r+1];
        }
        call_wrate_history[wrate_lookback-1] = call_wrate_avg;
        ax_calc = wrate_lookback*k_delta_calc;
        //ax_calc = 8;
        /*
        call_wrate_delta_sum = 0;
        for(q = 1; q <= ax_calc; q++) {
            call_wrate_delta_sum += call_wrate_history[wrate_lookback-q] - call_wrate_history[wrate_lookback-q-1];
        }
        ax_call = call_wrate_delta_sum/ax_calc; 
        //Print("ax call: ", ax_call);
        */
    }
    
    /*
    if(ctr_change == 2 || ctr_change == 4) {
        //wrate logging array, put                 
        for(int q = 0; q <= wrate_lookback-1; q++) {
            put_wrate_history[q] = put_wrate_history[q+1];
        }
        put_wrate_history[wrate_lookback] = put_wrate_avg;
        double ax_calc = wrate_lookback - MathFloor(k_delta_calc*(double)wrate_lookback); 
        put_wrate_delta_sum = 0;
        for(q = 0; q <= ax_calc; q++) {
            put_wrate_delta_sum += put_wrate_history[q+1] - put_wrate_history[q];
        }
        ax_put = put_wrate_delta_sum/ax_calc; 
        Print("ax put: ", ax_put);
        
    }
    else if(ctr_change == 3 || ctr_change == 5) { 
        //wrate logging array, call                 
        for(int r = 0; r <= wrate_lookback-1; r++) {
            call_wrate_history[r] = call_wrate_history[r+1];
        }
        call_wrate_history[wrate_lookback] = call_wrate_avg;
        ax_calc = wrate_lookback - MathFloor(k_delta_calc*(double)wrate_lookback); 
        call_wrate_delta_sum = 0;
        for(q = 0; q <= ax_calc; q++) {
            call_wrate_delta_sum += call_wrate_history[q+1] - call_wrate_history[q];
        }
        ax_call = call_wrate_delta_sum/ax_calc; 
        Print("ax call: ", ax_call);
    }
    */
    put_winctr_old = put_winctr;
    put_lossctr_old = put_lossctr;
    call_winctr_old = call_winctr;
    call_lossctr_old = call_lossctr;
    drawctr_old = put_drawctr;
    n_simulated_call_old = n_simulated_call;
    n_simulated_put_old = n_simulated_put;
    
    wrateOk_call = 0;
    wrateOk_put = 0;
    
}

void open_order (int mode) 
{       
    switch(mode) {
        case 0:
            int ticket = OrderSend(Symbol(), OP_SELL, order_volume, Bid, 0,0,0);
            if(ticket > 0) temprate = Bid;
            //script execute
            break;
        case 1:
            ticket = OrderSend(Symbol(), OP_BUY, order_volume, Ask, 0,0,0);
            if(ticket > 0) temprate = Bid; //ask?
            //script execute
            break;
        case 2: //no ticket/no script execute OP_SELL
            temprate = Bid;
            dt = TimeCurrent();
            break;
        case 3: //no ticket/no script execute OP_BUY
            temprate = Bid;
            dt = TimeCurrent();
            break;
        default:
            Print("Invalid trade mode.");
            break;
    }
}

bool s20170117_2 (int mode)
{
    double HH0 = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value, 1)), //mode 0
           LL0 = iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, h1_value, 1)),
           HH1 = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, k1_value, 1)), //mode 1
           LL1 = iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, k1_value, 1));
           
    switch(mode) {
        case 0:
            if(iMA(Symbol(), 0, h1_ma, 0, MODE_SMA, PRICE_MEDIAN, 1) > iMA(Symbol(), 0, h1_ma*2, 0, MODE_SMA, PRICE_MEDIAN, 1)) {           
                if(iClose(Symbol(), 0, 1) > HH0-(HH0-LL0)*thres) {
                    if(Bid <= HH0-(HH0-LL0)*thres) {
                        return true;
                    }
                    else break;
                }
            }
            break;
        case 1:
            if(iMA(Symbol(), 0, k1_ma, 0, MODE_SMA, PRICE_MEDIAN, 1) < iMA(Symbol(), 0, k1_ma*2, 0, MODE_SMA, PRICE_MEDIAN, 1)) {           
                if(iClose(Symbol(), 0, 1) < LL1+(HH1-LL1)*thres) {
                    if(Bid >= LL1+(HH1-LL1)*thres) { //Ask?
                        return true;
                    }
                    else break;
                }
            }
            break;
        default:
            Print("Invalid mode strat s20170117_2()");
            break;
    }
}

bool s20170205 (int mode)
{
    double HH0 = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value, 1)), //mode 0
           LL0 = iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, h1_value, 1)),
           HH1 = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, k1_value, 1)), //mode 1
           LL1 = iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, k1_value, 1));
           
    switch(mode) {
        case 0:
            if(iMA(Symbol(), 0, h1_ma, 0, MODE_SMA, PRICE_MEDIAN, 1) > iMA(Symbol(), 0, h1_ma*2, 0, MODE_SMA, PRICE_MEDIAN, 1 && 
               iStochastic(Symbol(), 0, 80, 20, 1, MODE_SMA, 0, MODE_MAIN, 0) >= 80)) {           
                if(iClose(Symbol(), 0, 1) > HH0-(HH0-LL0)*thres) {
                    if(Bid <= HH0-(HH0-LL0)*thres) {
                        return true;
                    }
                    else break;
                }
            }
            break;
        case 1:
            if(iMA(Symbol(), 0, k1_ma, 0, MODE_SMA, PRICE_MEDIAN, 1) < iMA(Symbol(), 0, k1_ma*2, 0, MODE_SMA, PRICE_MEDIAN, 1) /*&&
               iStochastic(Symbol(), 0, 80, 20, 1, MODE_SMA, 0, MODE_MAIN, 0) <= 50*/) {           
                if(iClose(Symbol(), 0, 1) < LL1+(HH1-LL1)*thres) {
                    if(Bid >= LL1+(HH1-LL1)*thres) { //Ask?
                        return true;
                    }
                    else break;
                }
            }
            break;
        default:
            Print("Invalid mode strat s20170117_2()");
            break;
    }
}

bool s20170205_2 (int mode)
{
    switch(mode) {
        case 0:
            if(iCCI(Symbol(), 0, h1_value, PRICE_TYPICAL, 0) >= cciint && 
               iClose(Symbol(), 0, 1) >= iBands(Symbol(), 0, h1_value, 2, 0, PRICE_TYPICAL, MODE_UPPER, 0) &&
               iStochastic(Symbol(), 0, 80, 20, 1, MODE_SMA, 0, MODE_MAIN, 0) >= 80 &&
               iRSI(Symbol(), 0, h1_value, PRICE_TYPICAL, 0) >= 70)
                return true;
            else break;
        case 1:
            if(iCCI(Symbol(), 0, h1_value, PRICE_TYPICAL, 0) <= -cciint && 
               iClose(Symbol(), 0, 1) <= iBands(Symbol(), 0, h1_value, 2, 0, PRICE_TYPICAL, MODE_LOWER, 0) &&
               iStochastic(Symbol(), 0, 80, 20, 1, MODE_SMA, 0, MODE_MAIN, 0) <= 10 &&
               iRSI(Symbol(), 0, h1_value, PRICE_TYPICAL, 0) <= 20)
                return true;
            else break;
    }
}