bool s20170103_3 () 
{
   if((iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, h1_value)) == 
      iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, 2*h1_value))) &&
      iLowest(Symbol(), 0, MODE_LOW, h1_value) >= h1_value -1) {
      if(Bid >= iHigh(Symbol(), 0, (iHighest(Symbol(), 0, MODE_HIGH, h1_value))))
         return true;
   }
}

bool s20170103()//_2 () //MERK. Dette er s20170103_2, altså nr 2. VIKTIG
{
   if((iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value)) == 
      iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, 2*h1_value))) &&
      iHighest(Symbol(), 0, MODE_HIGH, h1_value) >= h1_value -1) {
      if(Bid <= iHigh(Symbol(), 0, (iLowest(Symbol(), 0, MODE_LOW, h1_value))))
         return true;
   }
}

bool s20170103_1 () 
//Definer HH og LL en gang og bruk om igjen for å spare prosesseringstid.
{
   int j = -1;
   int k;
   if(Bid <= iLow(Symbol(), 0, (iLowest(Symbol(), 0, MODE_LOW, h1_value)))) {
      while(j < h1_value) {
         j++;
         for(int i = 1; i <= h1_value; i++) {
            k = 0;
            if(iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value + j + i)) > 
               iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, h1_value + j))) {
               k++;
            } 
         }
         if(k +1 == h1_value) {
               if(iHighest(Symbol(), 0, MODE_HIGH, h1_value + j) == h1_value + j -1)
                  return true;
         }
      }  
   }
}}