bool s20170103 () 
//Må returnere shift til LL etter HH og gjøre funksjonen rekursiv. Altså ta inn shift og sette bryting av LL som egen condition
{
   if(Bid <= iLow(Symbol(), 0, (iLowest(Symbol(), 0, h1_value)) {
      int j = 1;
      while(iHigh(Symbol(), 0, j+1)
      
      if(/*iLowest(Symbol(), 0, MODE_LOW, h1_value) < iHighest(Symbol(), 0, MODE_HIGH, h1_value) &&*/
         iHighest(Symbol(), 0, MODE_HIGH, h1_value) >= h1_value -1 ) {
         for(int i = 1; i <= h1_value; i++) {
            if(iHigh(Symbol(), 0, i + iHighest(Symbol(), 0, MODE_HIGH, h1_value)) > 
               iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value))) {
               return false;
            }
            else if(iLow(Symbol(), 0, i + iLowest(Symbol(), 0, MODE_LOW, h1_value)) <
               iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, h1_value))) {
               return false;
            }
         }
         return true;
      }
      //else return false; //redundant
   }
}