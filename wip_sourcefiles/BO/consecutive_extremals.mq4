 if((iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value)) == 
      iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, 2*h1_value))) &&
      iHighest(Symbol(), 0, MODE_HIGH, h1_value) >= h1_value -1) {
      if(Ask/*Bid*/ <= iHigh(Symbol(), 0, (iLowest(Symbol(), 0, MODE_LOW, h1_value))))
         return true;
         
int s20170111 (int mode)
{
    double extr_arr[n], //usikker på om det er double eller float. Hvis mqlrates gir doubles må typekonvertering gjennomføres. Double er kanskje tregere.
        HH = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h_value)),
        LL = iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, h_value)); //kanskje ulik h-verdi her(?)
    ArraySetAsSeries(extr_arr); //evt indekser på en smartere måte-
       
    switch(mode) {
        case 0:
            //1 - 2
            break;
        case 1:
            //3 - 4
            break;
        default:
            Print("Invalid mode on s20170111.");
            return;
    }
   
    if(iClose(Symbol(), 0, 1) == HH &&               //1
        HH > extr_arr[f-1]) {
        if(sizeof(extr_arr) >= n*sizeof(double x)) {
            for(int i; i<=sizeof(extr_arr)/sizeof(double y); i++) {
                if(extr_arr[i] > HH) return false; //evt break
            }
        }
    }                                                //2
}