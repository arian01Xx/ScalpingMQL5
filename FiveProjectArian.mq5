#property link      "CEO Neo-Bite wave"
#property version   "Nova Noir Bank"

#include <Trade/Trade.mqh>

CTrade trade;

double AccountRisk=0.01;// 1% of account balance
double Lots=0.1;
int takeProfits=100;
int stopLoss=100;
int magic=11;
int handle;
int handleTrendMaFast;
int handleTrendMaSlow;
int maxOrders=3;
int ordersOpened=0; //variable to count the number of opened orders
int totalPositions=PositionsTotal();
int openPositions=0;

double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);

int OnInit(){
  
  //Moving Average code
  handleTrendMaFast=iMA(_Symbol, PERIOD_H1,8,0,MODE_EMA,PRICE_CLOSE);
  handleTrendMaSlow=iMA(_Symbol,PERIOD_H1,21,0,MODE_EMA,PRICE_CLOSE);
  
  //Registrar operaciones en un excel codigo=
  handle=FileOpen("trade_log.csv",FILE_WRITE|FILE_CSV|FILE_COMMON);
  if(handle<0){
    Print("Failed to open file");
    return INIT_FAILED;
  }
  FileWrite(handle,"Type","Symbol","Volume","Price","Time");
  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
  if(handle>=0){
    FileClose(handle);
  }
}

void OnTick(){
   
   //Moving Average code=
   double maTrendFast[], maTrendSlow[];
   
   ArraySetAsSeries(maTrendFast,true);
   ArraySetAsSeries(maTrendSlow,true);
   
   CopyBuffer(handleTrendMaFast,0,0,3,maTrendFast);
   CopyBuffer(handleTrendMaSlow,1,0,3,maTrendSlow);
   
   double maFast=maTrendFast[0];
   double maSlow=maTrendSlow[0];
   
   //trade code
   ask=NormalizeDouble(ask,_Digits);
   bid=NormalizeDouble(bid,_Digits);
   double sl=ask-50*_Point; 
   double tp=bid+50*_Point;
   
   //buying
   double tpB=ask+takeProfits*_Point;
   double slB=ask-stopLoss*_Point;
   
   tpB=NormalizeDouble(tpB,_Digits);
   slB=NormalizeDouble(slB,_Digits);
   
   //selling
   double tpS=bid-takeProfits*_Point;
   double slS=bid+takeProfits*_Point;
   
   tpS=NormalizeDouble(tpS,_Digits);
   slS=NormalizeDouble(slS,_Digits);
   
   //Gestion de riesgo
   double accountBalance=AccountInfoDouble(ACCOUNT_BALANCE);
   double maxRisk=accountBalance*AccountRisk;
   double slNew=100*_Point;
   double lotSize=maxRisk/slNew;
   
   //using like this: trade.Buy(NormalizeDouble(lotSize,2),_Symbol,ask,ask-sl,ask+2*sl);
   
   //Gestion dinamica de StopLoss y TakeProfit
   for(int i=PositionsTotal()-1; i>=0; i--){
     if(PositionGetSymbol(i)==_Symbol && PositionGetInteger(POSITION_MAGIC)==magic){
       ulong ticket=PositionGetTicket(i);
       if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
         trade.PositionModify(ticket,sl,tp);
       }else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
         trade.PositionModify(ticket,bid+50*_Point,bid-100*_Point);
       }
     }
   }
   
   //just three orders no more
   //if there are less than maxOrders open positions, open new orders
   for(int i=totalPositions-1; i>=0; i--){
     if(PositionSelect(i)){
       if(PositionGetString(POSITION_SYMBOL)==_Symbol){
         openPositions++;
       }
     }
   }
   
   if(openPositions<maxOrders){
     if(trade.Buy(Lots,_Symbol,ask,slB,tpB)|| trade.Sell(Lots,_Symbol,bid,slS,tpS)){
       ordersOpened++;
     }
   }
   
   if(openPositions>=maxOrders){
     ordersOpened=0;
   }
   
   //Strategy Scalping
   if(maFast>maSlow){
     //buying
     trade.Buy(Lots,_Symbol,ask,slB,tpB);
   }
   if(maFast<maSlow){
     //selling
     trade.Sell(Lots,_Symbol,bid,slS,tpS);
   }
}

void OnTradeTransaction(const MqlTradeTransaction& trans, 
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result){
  if(trans.type==TRADE_TRANSACTION_ORDER_ADD || trans.type==TRADE_TRANSACTION_ORDER_ADD){
    FileWrite(handle,trans.type,trans.symbol,trans.volume,trans.price,TimeToString(trans.time_type,TIME_DATE|TIME_MINUTES));
  }
}