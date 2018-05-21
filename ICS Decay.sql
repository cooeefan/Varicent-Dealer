/*************************************************************
*                  Dealer Eligibility                        *
*       #DealerMonthlyEligibility has all eligible records   *
**************************************************************/
IF OBJECT_ID('tempdb..#DealerMonthlyEligibility') is not Null
drop table #DealerMonthlyEligibility

select * 
into #DealerMonthlyEligibility
from dbo.ufn_DealerMonthlyEligibility('2012-11-01', '2013-12-31')

create clustered index IX_DealerCode on #DealerMonthlyEligibility(SalesCode,MonthStartDate,MonthEndDate)

--select * from #DealerMonthlyEligibility where  CurrentMonth = '2013, Month 09' order by MonthStartDate


/***********************************************************
*                  Market Eligibility                      *
*      #MarketEligibility has all eligible records         *
************************************************************/

IF OBJECT_ID('tempdb..#MarketEligibility') is not Null
drop table #MarketEligibility

select * 
into #MarketEligibility
from dbo.ufn_MarketEligibility()

create clustered index IX_MarketCode on #MarketEligibility(ContractID,StartDate,EndDate)

--select * from #MarketEligibility where MarketCode = 'BIM'

/***************************************************
*             Product Eligibility                  *
*   #ProductEligibility has all eligible records   *
****************************************************/
IF OBJECT_ID('tempdb..#ProductEligibility') is not Null
drop table #ProductEligibility

select * 
into #ProductEligibility
from dbo.ufn_ProductEligibility('2012-11-01', '2013-12-31')

create clustered index IX_ProductCode on #ProductEligibility(ProductIDCode,BillingSubsystemID,StartDate,EndDate)

/*************************************************************
*                      Eligible TXNs                         *
*            #RawTxns has all eligible records               *
**************************************************************/

IF OBJECT_ID('tempdb..#RawTxns') is not Null
drop table #RawTxns

select cast((Convert(Varchar(7),cast(EffectiveCalcDate as datetime),121)+'-01') as date) as [Month],
	BillingSubsystemID,SubscriberActivityKey,cast(EffectiveCalcDate as date) as EffectiveCalcDate,ServiceUniversalID,EventType,ActDate,DeactDate,ReactDate,LastSuspendDate,ServiceNumber,CustomerBAN,CreditClass,PlanCode,
	PoolingMRC,RecAccess,MarketCode,NPANXX,SameMonth,IsAddALine,AddALineCode,T.SalesCode,TotalMRC,DiscountMRC,IsValid,CreditType,DealerName,ContractHolderID,ContractID,MasterDealerCode,ContractChannel,
	ContractHolderChannel,ChannelType,AgreementType
into #RawTxns
from tsdICSActivity T
	inner join #DealerMonthlyEligibility D on T.SalesCode = D.SalesCode 
		and cast(T.EffectiveCalcDate as date) between D.MonthStartDate and D.MonthEndDate
	inner join (
		select distinct ProductIDCode, StartDate, EndDate
		from cfgICSProductCategory
		where BillingSubsystemID = '1'
			and Level = 'POSTPAID CATEGORIES'	----- from cfgProductLevelGroup
		) P on T.PlanCode = P.ProductIDCode 
			and cast(T.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)

--select * from #RawTxns where EventType = 'ACT' and cast(EffectiveCalcDate as date) between '2012-12-01' and '2013-05-31' and ContractID = '1-18PB2Y'

create clustered index idx_RawTxn on #RawTxns (EffectiveCalcDate)
			
			
/*************************************************************
*                      Shifted TXNs                          *
*            #ShiftedTxns has all eligible records           *
**************************************************************/
IF OBJECT_ID('tempdb..#Month') is not Null
drop table #Month
IF OBJECT_ID('tempdb..#ShiftedTxns') is not Null
drop table #ShiftedTxns

select CurrentMonth,MIN(CAST(Date as date)) as StartDate, MAX(CAST(Date as date)) as EndDate
into #Month  
from cfgDateString
group by CurrentMonth


Declare @CurrentMonth varchar(20), @StartDate date, @EndDate date
--set @CurrentMonth = '2013-10-01'
--set @StartDate = '2013-10-01'
--set @EndDate = '2013-10-31'

--select DATEADD(mm,-2,@EndDate)

select cast('' as varchar(30)) as CalcMonth, cast('' as varchar(30)) as SubscriberContractID, cast('' as varchar(30)) as SubscriberMasterDealerCode,* 
into #ShiftedTxns
from #RawTxns
where 1=2

Declare Month CURSOR FOR
select CurrentMonth,StartDate,EndDate from #Month
where StartDate between '2012-01-01' and '2013-12-31'
order by StartDate

Open Month

FETCH NEXT FROM Month 
INTO @CurrentMonth, @StartDate, @EndDate 

WHILE @@FETCH_STATUS = 0
BEGIN
	
	--select @CurrentMonth, @StartDate, @EndDate 

	IF OBJECT_ID('tempdb..#RawTXNWT1') is not Null
	drop table #RawTXNWT1

	select @CurrentMonth as CalcMonth, ContractID as SubscriberContractID, MasterDealerCode as SubscriberMasterDealerCode
		,*
	into #RawTXNWT1			------ActTXNs
	from #RawTxns T
	where cast(T.EffectiveCalcDate as date) between DATEADD(mm,-7,@StartDate) and  DATEADD(mm,-2,@EndDate)
		and EventType = 'ACT'

	insert into #ShiftedTxns
	select * from #RawTXNWT1 where EventType = 'ACT'

	insert into #ShiftedTxns
	select @CurrentMonth as CalcMonth, Act.ContractID as SubscriberContractID, Act.MasterDealerCode as SubscriberMasterDealerCode 
		,T.*
	from #RawTxns T
		inner join #RawTXNWT1 Act on T.ServiceUniversalID = Act.ServiceUniversalID
	where cast(T.EffectiveCalcDate as date) between DATEADD(mm,-7,@StartDate) and  @EndDate
		and T.EventType in ('DEACT', 'REACT')
	
	FETCH NEXT FROM Month 
	INTO @CurrentMonth, @StartDate, @EndDate 
		
END
CLOSE Month;
DEALLOCATE Month;

--select * from #ShiftedTxns			
			
/*************************************************************
*                      Sum up TXNs                           *
*            #SumUpTXNs has all eligible records             *
**************************************************************/
IF OBJECT_ID('tempdb..#SumUpTXNs') is not Null
drop table #SumUpTXNs

select CalcMonth, SubscriberContractID as ContractID, SubscriberMasterDealerCode as MasterDealerCode, CreditType
	,SUM(case when EventType = 'ACT' then 1 else 0 end) as ACTAmt
	,SUM(case when EventType = 'DEACT' then 1 else 0 end) as DEACTAmt
	,SUM(case when EventType = 'REACT' then 1 else 0 end) as REACTAmt
	,SUM(case when EventType = 'DEACT' then 1 else 0 end) -  SUM(case when EventType = 'REACT' then 1 else 0 end) as DECAYAmt
	,Round((SUM(case when EventType = 'DEACT' then 1 else 0 end) -  SUM(case when EventType = 'REACT' then 1 else 0 end))/cast(SUM(case when EventType = 'ACT' then 1 else 0 end) as float)*100,2) as [DECAY%]
into #SumUpTXNs
from #ShiftedTxns
group by CalcMonth, SubscriberContractID, SubscriberMasterDealerCode, CreditType
order by CalcMonth,SubscriberMasterDealerCode, SubscriberContractID, CreditType

Insert into #SumUpTXNs
select CalcMonth, ContractID, MasterDealerCode,'ALL' as CreditType
	, SUM(ACTAmt),SUM(DEACTAmt),SUM(REACTAmt),SUM(DECAYAmt)
	,Round((SUM(cast(DECAYAmt as float))/SUM(ACTAmt))*100,2) as [DECAY%]
from #SumUpTXNs
group by CalcMonth, ContractID, MasterDealerCode


--select * from #SumUpTXNs order by CalcMonth,ContractID,MasterDealerCode,CreditType
			

/*************************************************************
            Check Tier calculated result from: 
       ICS Decay 1030 Deriver Tier fro each Contract
**************************************************************/





/*************************************************************
The logic that Varicent delivered maybe is wrong:
1. For example, Contract is eligible from 1/1/2013, 
 that means the started month that we can calculated decay is 3/1/2013, but Varicent calculated results started from 1/1/2013, that is because Varicent validate the date for salecodeEligible, not the effectCalcDate in TXNs 
2. SUM(IF(OR(ISEMPTY(ICS Decay 1020 Count of ReActivations Eligible for Decay calculation by Month.Value), ISEMPTY(ICS Decay 1015 Count of DeActivations Eligible for Decay calculation by Month.Value)), 0,
      (((ICS Decay 1015 Count of DeActivations Eligible for Decay calculation by Month.Value - ICS Decay 1020 Count of ReActivations Eligible for Decay calculation by Month.Value) / ICS Decay 1010 Count of Activations Eligible for Decay calculation by Month.Value)) * 100))
3. The way that Varicent used to calculate 'All' Decay logic maybe is wrong, A/B+C/D != (A+C)/(B+D)
**************************************************************/