//+------------------------------------------------------------------+
//|                                 DrSoli_RSI_MACD_FairValueGap.mq4 |
//|                                                         DrSoli   |
//|                                                                  |
//+------------------------------------------------------------------+
#property               copyright         "DrSoli"
#property               link              "www.drsoli.com"
#property               version           "1.00"
#property               strict


// Settings
input int               x1                   = 0; //-------------Trade settings--------------
input int               MaxOpenTrades        = 2; // RSI Shift
input double            LotSize              = 0.1; // Min RSI change to consider  (%)

input int               x1                   = 0; //-------------RSI Divergence--------------
input int               RSI_Shift            = 2; // RSI Shift
input double            RSI_MindRSI          = 6; // Min RSI change to consider  (%)
input bool              RSI_CheckRSILevel    = True; // Check RSI Level (%)
input int               RSI_Lim              = 65; // Min RSI Level to consider (%)
input double            RSI_MindPrice        = 1; // RSI_MindPrice  (ATR)
input double            RSI_SLMax            = 0.008; // Stop Loss Max (normalized 0-1)
input double            RSI_StopLoss         = 300; // Stop Loss (Points)
input double            RSI_TakeProfit       = 500; // Take Profit  (Points)
input int               RSI_MinTrail         = 2; // Minimum Trailing (*ATR)
input double            RSI_WeakStrong       = 1; //Strong and/or Weak divergence (0:S&W 1:S 2:W)


input int               x2                   = 0; //--------------MACD Crossing---------------
input int               MACD_FastEMA         = 12; // MACD Fast EMA period
input int               MACD_SlowEMA         = 26; // MACD Slow EMA period
input int               MACD_SignalEMA       = 10; // MACD Signal EMA period
input double            MACD_SLMargin        = 0.5; // Stop Loss Margin (normalized 0-1)
input double            MACD_TakeProfit      = 1500;
input int               MACD_EMAPeriod       = 4;
input int               MACD_Direction       = 2; //0:Short&Long 1:Long 2:Short
input int               MACD_MinTrail        = 4; // MinTrail (ATR)
double macd_main_0, macd_main, macd_signal_0, macd_signal, rsi_value, ema_value;

double LotSize;

input int               x4                         = 0; //--------------Fair Value Gap-------------
input double            FVG_GapTarget              = 0.6;
input double            FVG_MinCdl                 = 1.5;
input double            FVG_MaxCdl                 = 2.5;
input double            FVG_MinGap                 = 0.4;
input double            FVG_MaxGap                 = 2.0;
input double            FVG_SLMargin               = 3;
input double            FVG_SLMax                  = 0.015;
input double            FVG_TP                     = 2000;
input bool              FVG_RSICheck               = True;
input int               FVG_LongShort              = 2; //FVG_LongShort 0:LS  1:L  2:S
input int               FVG_MinTrail               = 4;
input int               FVG_MaxOrders              = 1;
input int               FVG_Expiry                 = 8;
input bool              FVG_Compounding            = False;
int                     FVG_Shifts                 = 1;
double                  FVG_OpenPrice, FVG_StopLoss, FVG_TakeProfit;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

//---
   IsNewBar();
   return(INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   // Trail orders if there are any
   if (OrdersTotal() > 0)
   {
      TrailOpenOrders(RSI_MinTrail,MACD_MinTrail,MACDD_MinTrail);
   }

   // Stop here if there are already max open orders
   if (OrdersTotal() > MaxOpenTrades)
      return;

   // Stop here if the tick is not a new candle
   if (!IsNewBar()) return;

   
   // If you want the lot size based on your account balance
   //LotSize = NormalizeDouble(0.1 + 1*MathMax(0, (AccountBalance()-100000)/10000), 2);
   
   
// Now let's start checking indicators
   
   RSI_P_divergence();
   // I deactivated Negative RSI due to bad performance!
//   RSI_N_divergence();

   MACD_CrossOver();
   // I deactivated Positive RSI due to bad performance!
//   MACDD_P_divergence();
   MACDD_N_divergence();
   
   FairValueGap();
  }


//------------------ Custom functions ------------------------------//

//------------------ Verify New Candle Close -----------------------//
bool  IsNewBar()
  {
   static datetime LastTime = 0;
   bool result = (LastTime != Time[0]);
   if(result)
      LastTime = Time[0];
   return(result);
  }



void RSI_P_divergence()
{
   if (OrdersTotal() > 0)
   {
   for (int i = 0; i < OrdersTotal(); i++)
   {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() == 100)
         return;
    }
   }

   int      Price_peak2i = -1;
   double   RSI_peak1v, RSI_peak2v;

   if (ArrayMaximum(High, 7, MathMax(RSI_Shift - 3,1)) != RSI_Shift) return;

   for (int i = RSI_Shift + 4; i < 30; i++)
   {
      if (i == ArrayMaximum(High, 7, i-3))
      {
         Price_peak2i = i;
         break;
      }
   }
   if (Price_peak2i == -1) return;

   RSI_peak1v = MathMax(iRSI(NULL, 0, 14, PRICE_HIGH, RSI_Shift - 1),MathMax(iRSI(NULL, 0, 14, PRICE_HIGH, RSI_Shift),iRSI(NULL, 0, 14, PRICE_HIGH, RSI_Shift + 1)));
   RSI_peak2v = MathMax(iRSI(NULL, 0, 14, PRICE_HIGH, Price_peak2i - 1),MathMax(iRSI(NULL, 0, 14, PRICE_HIGH, Price_peak2i),iRSI(NULL, 0, 14, PRICE_HIGH, Price_peak2i + 1)));


      if ((RSI_WeakStrong == 0 || RSI_WeakStrong == 1) &&
          High[RSI_Shift] >  High[Price_peak2i] && RSI_peak1v < RSI_peak2v &&
         (High[RSI_Shift] >= High[Price_peak2i] + iATR(NULL,0,10,0) * RSI_MindPrice || RSI_peak2v - RSI_peak1v >= RSI_MindRSI) &&
         ((RSI_peak2v > RSI_Lim)|| !RSI_CheckRSILevel))
      {
//         Print("Strong");
         ObjectCreate    (0, "RSI_PSD" + (string)Time[0], OBJ_TREND, 0, Time[Price_peak2i], High[Price_peak2i], Time[RSI_Shift], High[RSI_Shift]);
         ObjectSetInteger(0, "RSI_PSD" + (string)Time[0], OBJPROP_RAY_RIGHT, False);
         ObjectSetInteger(0, "RSI_PSD" + (string)Time[0], OBJPROP_COLOR, clrBlue);

         double SL = MathMin(High[ArrayMaximum(High,6,0)] + Point * RSI_StopLoss, Ask * (1 + RSI_SLMax));
         int ticket = OrderSend(NULL, OP_SELL, LotSize, Bid, 3, SL, Ask - Point * RSI_TakeProfit, "", 100);
      }

      if ((RSI_WeakStrong == 0 || RSI_WeakStrong == 2) &&
          High[RSI_Shift] < High[Price_peak2i] && RSI_peak1v > RSI_peak2v &&
         (High[RSI_Shift] <= High[Price_peak2i] - iATR(NULL,0,10,0) * RSI_MindPrice || RSI_peak1v - RSI_peak2v >= RSI_MindRSI) &&
         ((RSI_peak2v > RSI_Lim) || !RSI_CheckRSILevel))
      {
//         Print("Weak");
         ObjectCreate    (0, "RSI_PWD" + (string)Time[0], OBJ_TREND, 0, Time[Price_peak2i], High[Price_peak2i], Time[RSI_Shift], High[RSI_Shift]);
         ObjectSetInteger(0, "RSI_PWD" + (string)Time[0], OBJPROP_RAY_RIGHT, False);
         ObjectSetInteger(0, "RSI_PWD" + (string)Time[0], OBJPROP_COLOR, clrYellow);

         double SL = MathMin(High[ArrayMaximum(High,6,0)] + Point * RSI_StopLoss, Ask * (1 + RSI_SLMax));
         int ticket = OrderSend(NULL, OP_SELL, LotSize, Bid, 3, SL, Ask - Point * RSI_TakeProfit, "", 100);

      }
}


void RSI_N_divergence()
{
   if (OrdersTotal() > 0)
   {
   for (int i = 0; i < OrdersTotal(); i++)
   {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() == 100)
         return;
    }
   }
   int      Price_deep2i = -1;
   double   RSI_deep1v, RSI_deep2v;

   if (ArrayMinimum(Low, 7, MathMax(RSI_ShiftN - 3,1)) != RSI_ShiftN) return;

   for (int i = RSI_ShiftN + 4; i < 30; i++)
   {
      if (i == ArrayMinimum(Low, 7, i-3))
      {
         Price_deep2i = i;
         break;
      }
   }
   if (Price_deep2i == -1) return;

   RSI_deep1v = MathMin(iRSI(NULL, 0, 14, PRICE_LOW, RSI_ShiftN - 1),MathMin(iRSI(NULL, 0, 14, PRICE_LOW, RSI_ShiftN),iRSI(NULL, 0, 14, PRICE_LOW, RSI_ShiftN + 1)));
   RSI_deep2v = MathMin(iRSI(NULL, 0, 14, PRICE_LOW, Price_deep2i - 1),MathMin(iRSI(NULL, 0, 14, PRICE_LOW, Price_deep2i),iRSI(NULL, 0, 14, PRICE_LOW, Price_deep2i + 1)));


      if ((RSI_WeakStrongN == 0 || RSI_WeakStrongN == 1) &&
          Low[RSI_ShiftN] <  Low[Price_deep2i] && RSI_deep1v > RSI_deep2v &&
         (Low[RSI_ShiftN] <= Low[Price_deep2i] + iATR(NULL,0,10,0) * RSI_MindPriceN || RSI_deep1v - RSI_deep2v >= RSI_MindRSIN) &&
         ((RSI_deep2v < 100 - RSI_LimN) || !RSI_CheckRSILevelN))
      {
//         Print("Strong");
         ObjectCreate    (0, "RSI_NSD" + (string)Time[0], OBJ_TREND, 0, Time[Price_deep2i], Low[Price_deep2i], Time[RSI_ShiftN], Low[RSI_ShiftN]);
         ObjectSetInteger(0, "RSI_NSD" + (string)Time[0], OBJPROP_RAY_RIGHT, False);
         ObjectSetInteger(0, "RSI_NSD" + (string)Time[0], OBJPROP_COLOR, clrBlue);

         double SL = MathMin(Low[ArrayMinimum(Low,6,0)] - Point * RSI_StopLossN, Bid * (1 - RSI_SLMaxN));
         int ticket = OrderSend(NULL, OP_BUY, LotSize, Ask, 3, SL, Bid + Point * RSI_TakeProfitN, "", 100);
      }

      if ((RSI_WeakStrongN == 0 || RSI_WeakStrongN == 2) &&
          Low[RSI_ShiftN] >  Low[Price_deep2i] && RSI_deep1v < RSI_deep2v &&
         (Low[RSI_ShiftN] >= Low[Price_deep2i] + iATR(NULL,0,10,0) * RSI_MindPriceN || RSI_deep2v - RSI_deep1v >= RSI_MindRSIN) &&
         ((RSI_deep2v < 100 - RSI_LimN) || !RSI_CheckRSILevelN))
      {
//         Print("Weak");
         ObjectCreate    (0, "RSI_NWD" + (string)Time[0], OBJ_TREND, 0, Time[Price_deep2i], Low[Price_deep2i], Time[RSI_ShiftN], Low[RSI_ShiftN]);
         ObjectSetInteger(0, "RSI_NWD" + (string)Time[0], OBJPROP_RAY_RIGHT, False);
         ObjectSetInteger(0, "RSI_NWD" + (string)Time[0], OBJPROP_COLOR, clrYellow);

         double SL = MathMin(Low[ArrayMinimum(Low,6,0)] - Point * RSI_StopLossN, Bid * (1 - RSI_SLMaxN));
         int ticket = OrderSend(NULL, OP_BUY, LotSize, Ask, 3, SL, Bid + Point * RSI_TakeProfitN, "", 100);
      }
}




void MACD_CrossOver()
{
   if (OrdersTotal() > 0)
   {
   for (int i = 0; i < OrdersTotal(); i++)
   {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() == 200)
         return;
    }
   }
    // Get the MACD values for the current bar
    macd_main     = iMACD(NULL, 0, MACD_FastEMA, MACD_SlowEMA, MACD_SignalEMA, PRICE_CLOSE, MODE_MAIN,   1);
    macd_signal   = iMACD(NULL, 0, MACD_FastEMA, MACD_SlowEMA, MACD_SignalEMA, PRICE_CLOSE, MODE_SIGNAL, 1);
    macd_main_0   = iMACD(NULL, 0, MACD_FastEMA, MACD_SlowEMA, MACD_SignalEMA, PRICE_CLOSE, MODE_MAIN,   2);
    macd_signal_0 = iMACD(NULL, 0, MACD_FastEMA, MACD_SlowEMA, MACD_SignalEMA, PRICE_CLOSE, MODE_SIGNAL, 2);


    // Get the EMA value for the current bar
    ema_value = iMA(NULL, 0, MACD_EMAPeriod, 0, MODE_EMA, PRICE_CLOSE,0);
    
    int ticket;
    // Check for trade signals
    if (macd_main > macd_signal && macd_main_0 < macd_signal_0 && macd_main < 0 && Ask < ema_value && (MACD_Direction == 0 || MACD_Direction == 1))
    {
        double SL = NormalizeDouble(MathMin(MathMin(Low[2],Low[1]),Low[0]) - MACD_SLMargin * iATR(NULL,0,10,0),2);
        // Open a buy trade
        ticket = OrderSend(Symbol(), OP_BUY, NormalizeDouble(LotSize,2), Ask, 3, SL, Bid + MACD_TakeProfit * Point, "Buy", 200);
        if (ticket > 0)
        {
            Print("Buy order opened successfully");
        }
        else
        {
            Print("Error opening buy order: ", GetLastError());
        }
    }
    else if (macd_main < macd_signal && macd_main_0 > macd_signal_0 && macd_main > 0 && Bid > ema_value && (MACD_Direction == 0 || MACD_Direction == 2) )
    {
        double SL = NormalizeDouble(MathMax(MathMax(High[2],High[1]),High[0]) + MACD_SLMargin * iATR(NULL,0,10,0),2);
        // Open a sell trade
        ticket = OrderSend(Symbol(), OP_SELL, NormalizeDouble(LotSize,2), Bid, 3, SL, Ask - MACD_TakeProfit * Point, "Sell", 200);
        if (ticket > 0)
        {
            Print("Sell order opened successfully");
        }
        else
        {
            Print("Error opening sell order: ", GetLastError());
        }
    }
}



void MACDD_P_divergence()
{
   if (OrdersTotal() > 0)
   {
   for (int i = 0; i < OrdersTotal(); i++)
   {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() == 300)
         return;
    }
   }
   int      Price_peak2i = -1;
   double   MACDD_peak1v, MACDD_peak2v;
   double   MACDD[3];

   if (ArrayMaximum(High,7, MathMax(MACDD_Shift - 3,1)) != MACDD_Shift) return;

   for (int i = MACDD_Shift + 4; i < 30; i++)
   {
      if (i == ArrayMaximum(High, 7, i-3))
      {
         Price_peak2i = i;
         break;
      }
   }
   if (Price_peak2i == -1) return;

   MACDD_peak1v = MathMax(iMACD(NULL, 0, 12, 26, 9, PRICE_HIGH, MODE_MAIN, MACDD_Shift - 1),       MathMax(iMACD(NULL, 0, 12, 26, 9, PRICE_HIGH, MODE_MAIN, MACDD_Shift),       iMACD(NULL, 0, 12, 26, 9, PRICE_HIGH, MODE_MAIN, MACDD_Shift + 1)));
   MACDD_peak2v = MathMax(iMACD(NULL, 0, 12, 26, 9, PRICE_HIGH, MODE_MAIN, Price_peak2i - 1),MathMax(iMACD(NULL, 0, 12, 26, 9, PRICE_HIGH, MODE_MAIN, Price_peak2i),iMACD(NULL, 0, 12, 26, 9, PRICE_HIGH, MODE_MAIN, Price_peak2i + 1)));


      if ((MACDD_WeakStrong != 2) &&
          High[MACDD_Shift] >  High[Price_peak2i] && MACDD_peak1v < MACDD_peak2v &&
         (High[MACDD_Shift] >= High[Price_peak2i] + iATR(NULL,0,10,0) * MACDD_MindPrice || MACDD_peak2v - MACDD_peak1v >= MindMACDD * iATR(NULL,0,10,0)) &&
         (MACDD_peak2v > MACDD_Lim * iATR(NULL,0,10,0) || !CheckMACDDLevel))
      {
//         Print("Strong");
         ObjectCreate    (0, "MACDD_PSD" + (string)Time[0], OBJ_TREND, 0, Time[Price_peak2i], High[Price_peak2i], Time[MACDD_Shift], High[MACDD_Shift]);
         ObjectSetInteger(0, "MACDD_PSD" + (string)Time[0], OBJPROP_RAY_RIGHT, False);
         ObjectSetInteger(0, "MACDD_PSD" + (string)Time[0], OBJPROP_COLOR, clrBlue);

         double SL = MathMin(High[ArrayMaximum(High,6,0)] + Point * MACDD_StopLoss, Ask * (1 + MACDD_SLMax));
         int ticket = OrderSend(NULL, OP_SELL, LotSize, Bid, 3, SL, Ask - Point * MACDD_TakeProfit, "", 300);
      }

      if ((MACDD_WeakStrong != 1) &&
          High[MACDD_Shift] < High[Price_peak2i] && MACDD_peak1v > MACDD_peak2v &&
         (High[MACDD_Shift] <= High[Price_peak2i] - iATR(NULL,0,10,0) * MACDD_MindPrice || MACDD_peak1v - MACDD_peak2v >= MindMACDD * iATR(NULL,0,10,0)) &&
         (MACDD_peak2v > MACDD_Lim * iATR(NULL,0,10,0) || !CheckMACDDLevel))
      {
//         Print("Weak");
         ObjectCreate    (0, "MACDD_PWD" + (string)Time[0], OBJ_TREND, 0, Time[Price_peak2i], High[Price_peak2i], Time[MACDD_Shift], High[MACDD_Shift]);
         ObjectSetInteger(0, "MACDD_PWD" + (string)Time[0], OBJPROP_RAY_RIGHT, False);
         ObjectSetInteger(0, "MACDD_PWD" + (string)Time[0], OBJPROP_COLOR, clrYellow);

         double SL = MathMin(High[ArrayMaximum(High,6,0)] + Point * MACDD_StopLoss, Ask * (1 + MACDD_SLMax));
         int ticket = OrderSend(NULL, OP_SELL, LotSize, Bid, 3, SL, Ask - Point * MACDD_TakeProfit, "", 300);
      }
}



void MACDD_N_divergence()
{
   if (OrdersTotal() > 0)
   {
   for (int i = 0; i < OrdersTotal(); i++)
   {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() == 300)
         return;
    }
   }
   int      Price_deep2i = -1;
   double   MACDD_deep1v, MACDD_deep2v;
   double   MACDD[3];

   if (ArrayMinimum(Low,7, MathMax(MACDD_Shift - 3,1)) != MACDD_Shift) return;

   for (int i = MACDD_Shift + 4; i < 30; i++)
   {
      if (i == ArrayMinimum(Low, 7, i-3))
      {
         Price_deep2i = i;
         break;
      }
   }
   if (Price_deep2i == -1) return;

   MACDD_deep1v = MathMin(iMACD(NULL, 0, 12, 26, 9, PRICE_LOW, MODE_MAIN, MACDD_Shift - 1), MathMin(iMACD(NULL, 0, 12, 26, 9, PRICE_LOW, MODE_MAIN, MACDD_Shift),       iMACD(NULL, 0, 12, 26, 9, PRICE_LOW, MODE_MAIN, MACDD_Shift + 1)));
   MACDD_deep2v = MathMin(iMACD(NULL, 0, 12, 26, 9, PRICE_LOW, MODE_MAIN, Price_deep2i - 1),MathMin(iMACD(NULL, 0, 12, 26, 9, PRICE_LOW, MODE_MAIN, Price_deep2i),iMACD(NULL, 0, 12, 26, 9, PRICE_LOW, MODE_MAIN, Price_deep2i + 1)));


      if ((MACDD_WeakStrong != 2) &&
          Low[MACDD_Shift] <  Low[Price_deep2i] && MACDD_deep1v > MACDD_deep2v &&
         (Low[MACDD_Shift] <= Low[Price_deep2i] - iATR(NULL,0,10,0) * MACDD_MindPrice || MACDD_deep1v - MACDD_deep2v >= MindMACDD * iATR(NULL,0,10,0)) &&
         ((MACDD_deep2v < -MACDD_Lim * iATR(NULL,0,10,0)) || !CheckMACDDLevel))
      {
//         Print("Strong");
         ObjectCreate    (0, "MACDD_NSD" + (string)Time[0], OBJ_TREND, 0, Time[Price_deep2i], Low[Price_deep2i], Time[MACDD_Shift], Low[MACDD_Shift]);
         ObjectSetInteger(0, "MACDD_NSD" + (string)Time[0], OBJPROP_RAY_RIGHT, False);
         ObjectSetInteger(0, "MACDD_NSD" + (string)Time[0], OBJPROP_COLOR, clrBlue);

         double SL = MathMin(Low[ArrayMinimum(Low,6,0)] - Point * MACDD_StopLoss, Bid * (1 - MACDD_SLMax));
         int ticket = OrderSend(NULL, OP_BUY, LotSize, Ask, 3, SL, Bid + Point * MACDD_TakeProfit, "", 300);
      }

      if ((MACDD_WeakStrong != 1) &&
          Low[MACDD_Shift] >  Low[Price_deep2i] && MACDD_deep1v < MACDD_deep2v &&
         (Low[MACDD_Shift] >= Low[Price_deep2i] + iATR(NULL,0,10,0) * MACDD_MindPrice || MACDD_deep2v - MACDD_deep1v >= MindMACDD * iATR(NULL,0,10,0)) &&
         ((MACDD_deep2v < -MACDD_Lim * iATR(NULL,0,10,0)) || !CheckMACDDLevel))
      {
//         Print("Weak");
         ObjectCreate    (0, "MACDD_NWD" + (string)Time[0], OBJ_TREND, 0, Time[Price_deep2i], Low[Price_deep2i], Time[MACDD_Shift], Low[MACDD_Shift]);
         ObjectSetInteger(0, "MACDD_NWD" + (string)Time[0], OBJPROP_RAY_RIGHT, False);
         ObjectSetInteger(0, "MACDD_NWD" + (string)Time[0], OBJPROP_COLOR, clrYellow);

         double SL = MathMin(Low[ArrayMinimum(Low,6,0)] - Point * MACDD_StopLoss, Bid * (1 - MACDD_SLMax));
         int ticket = OrderSend(NULL, OP_BUY, LotSize, Ask, 3, SL, Bid + Point * MACDD_TakeProfit, "", 300);
      }
}



void FairValueGap()
  {
   if (OrdersTotal() > 0)
   {
   for (int i = 0; i < OrdersTotal(); i++)
   {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() == 400)
         return;
    }
   }
   double ATR = iATR  (NULL,0,14,1);
   double H1  = High [FVG_Shifts];
   double L1  = Low  [FVG_Shifts];

   double H2  = High [FVG_Shifts+1];   
   double L2  = Low  [FVG_Shifts+1];
   double C2  = Close[FVG_Shifts+1];
   double O2  = Open [FVG_Shifts+1];
   
   double H3  = High [FVG_Shifts+2];
   double L3  = Low  [FVG_Shifts+2];
   
   int outcome = 0, ticket;

   if(MathAbs(C2 - O2) < ATR * FVG_MinCdl || MathAbs(C2 - O2) > ATR * FVG_MaxCdl)
      return;
   //Print("*****************************************");


// Candle detection
   bool BullGap = (C2 > O2) && (L1 - H3) > FVG_MinGap * (C2 - O2) && (L1 - H3) < FVG_MaxGap * (C2 - O2);
        BullGap = BullGap && Ask > C2;
        BullGap = BullGap && FVG_LongShort == 0 || FVG_LongShort == 1;

   bool BearGap = (C2 < O2) && (L3 - H1) > FVG_MinGap * (O2 - C2) && (L3 - H1) < FVG_MaxGap * (O2 - C2);
        BearGap = BearGap && Bid < C2;
        BearGap = BearGap && FVG_LongShort == 0 || FVG_LongShort == 2;
        

// RSI
   if (FVG_RSICheck)
   {
      BullGap = BullGap && iRSI(NULL,0,14,PRICE_CLOSE, 0) < 40;
      BearGap = BearGap && iRSI(NULL,0,14,PRICE_CLOSE, 0) > 60;
   }


//Set trade details
   if(BullGap)
     {
      FVG_OpenPrice  = H3 + FVG_GapTarget * (L1 - H3);
      FVG_StopLoss   = MathMax(L2 - ATR * FVG_SLMargin, Bid * (1 - FVG_SLMax));
      FVG_TakeProfit = FVG_MinTrail ? H1 + FVG_TP * Point : MathMax(MathMax(H1,H2),H3) + ATR * FVG_SLMargin;
      FVG_OpenPrice  = NormalizeDouble(FVG_OpenPrice,  Digits());
      FVG_StopLoss   = NormalizeDouble(FVG_StopLoss,   Digits());
      FVG_TakeProfit = NormalizeDouble(FVG_TakeProfit, Digits());
      outcome = 1;
     }

   if(BearGap)
     {
      FVG_OpenPrice  = L3 - FVG_GapTarget * (L3 - H1);
      FVG_StopLoss   = MathMin(H2 + ATR * FVG_SLMargin, Bid * (1 + FVG_SLMax));
      FVG_TakeProfit = FVG_MinTrail ? L1 - FVG_TP * Point: MathMin(MathMin(L1,L2),L3) - ATR * FVG_SLMargin;
      FVG_OpenPrice  = NormalizeDouble(FVG_OpenPrice,  Digits());
      FVG_StopLoss   = NormalizeDouble(FVG_StopLoss,   Digits());
      FVG_TakeProfit = NormalizeDouble(FVG_TakeProfit, Digits());
      outcome = -1;
     }
     

   switch(outcome)
     {
      case 1:
         ticket = OrderSend(NULL, ORDER_TYPE_BUY_LIMIT, LotSize, FVG_OpenPrice, 5, FVG_StopLoss, FVG_TakeProfit, "", 400, TimeCurrent() + Period() * 60 * FVG_Expiry);
         if(ticket < 1) Print("    ----    BUY order error    ", FVG_OpenPrice, "  ", FVG_StopLoss, "  ", FVG_TakeProfit, "  ", LotSize);
         break;
      case -1:
         ticket = OrderSend(NULL, ORDER_TYPE_SELL_LIMIT, LotSize, FVG_OpenPrice, 5, FVG_StopLoss, FVG_TakeProfit, "", 400, TimeCurrent() + Period() * 60 * FVG_Expiry);
         if(ticket < 1) Print("    ----    SELL order error    ", FVG_OpenPrice, "  ", FVG_StopLoss, "  ", FVG_TakeProfit, "  ", LotSize);
     }
  return;
  }





void TrailOpenOrders()
  {
   int n;
   int MinProfit = 1;
   double ts;

   for(int i = OrdersTotal()-1; i >= 0; i--)
     {
      int ticket = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      double ATRn = iATR(NULL,0,10,0);
      if (OrderMagicNumber() == 100)
      {MinProfit = RSI_MinTrail;
      }
      else if (OrderMagicNumber() == 200)
      {MinProfit = MACD_MinTrail;
      }
      else if (OrderMagicNumber() == 300)
      {MinProfit = MACDD_MinTrail;
      }
      else if (OrderMagicNumber() == 400)
      {MinProfit = FVG_MinTrail;
      }
      

      if(OrderType() == OP_BUY)
        {
         n = floor((Bid - OrderOpenPrice())/ATRn);
         if (n < MinProfit || n < 1)
            continue;
         ts = NormalizeDouble(OrderOpenPrice() + (n-1) * ATRn, Digits());
         if(ts > OrderStopLoss())
           {
            ticket = OrderModify(OrderTicket(),OrderOpenPrice(),ts,OrderTakeProfit(),0,White);
            if (ticket<1) Print("----    ", OrderStopLoss(), "  ", ts);
            continue;
           }
        }
      if(OrderType() == OP_SELL)
        {
         n = floor((OrderOpenPrice() - Ask)/ATRn);
         if (n < MinProfit || n < 1)
            continue;
         ts = NormalizeDouble(OrderOpenPrice() - (n-1) * ATRn, Digits());
         if(ts < OrderStopLoss())
           {
            ticket = OrderModify(OrderTicket(),OrderOpenPrice(),ts,OrderTakeProfit(),0,White);
            if (ticket<1) Print("----    ", OrderStopLoss(), "  ", ts);
            continue;
           }
        }
     }
  }
