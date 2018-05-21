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

--select * from #ProductEligibility where ProductIDCode = '1000A12M'
--select * from cfgICSProductCategory where ProductIDCode = '166'



/*************************************************************
*              Activity PostPaid Activation                  *
*   #ActivityActivation has all eligible Act&SameMon React   *
**************************************************************/
IF OBJECT_ID('tempdb..#ActivityActivation') is not Null
drop table #ActivityActivation

select   T.*, D.DealerName,D.MasterDealerCode,D.CurrentMonth,D.ContractHolderID,D.ContractID,D.ContractHolderChannel,D.ContractChannel,D.ChannelType,D.AgreementType
	, M.MarketCode as UDFMarketCode,M.SamsonMktName
	,case when M.ContractID is not null then 1 else 0 end as InMarketFlag
into #ActivityActivation
--select SubscriberActivityKey, COUNT(*)
from dbo.tsdICSActivity T
	left join tsdICSManualExclude E on T.ServiceUniversalID = E.ServiceUniversalID
		and T.BillingSubsystemID = E.BillingSubsystemID
		and T.EventType = E.EventType
		and T.EffectiveCalcDate = E.EffectiveCalcDate
	left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubTypeID and A.AccountType = T.AccountTypeID)
	inner join #DealerMonthlyEligibility D on D.SalesCode = T.SalesCode
		and CAST(T.EffectiveCalcDate as date) between D.MonthStartDate and D.MonthEndDate 
	inner join #ProductEligibility P on T.PlanCode = P.ProductIDCode
		and T.BillingSubsystemID = P.BillingSubsystemID
		and CAST(T.EffectiveCalcDate as date) between P.StartDate and P.EndDate
	left join #MarketEligibility M on D.ContractID = M.ContractID
		and (ISNULL(M.NPANXX,'')='' and T.MarketCode = M.SamsonMktName)
		and CAST(T.EffectiveCalcDate as date) between M.StartDate and M.EndDate
where E.ServiceUniversalID is null
	and ((T.EventType = 'ACT' and isnull(T.SameMonth,'N/A') <> 'Y') or (T.EventType = 'REACT' and T.SameMonth = 'Y'))         -----Same Month logic for Act maybe not in the Varicent yet
	and A.StartDate is null
	and T.IsValid = '1.00'
	
update A
set A.UDFMarketCode = M.MarketCode
from #ActivityActivation A
	inner join #MarketEligibility M on A.ContractID = M.ContractID
		and (ISNULL(M.NPANXX,'')<>'' and A.NPANXX = M.NPANXX)
		and CAST(A.EffectiveCalcDate as date) between M.StartDate and M.EndDate



--select A.ServiceUniversalID, A.EventType, A.EffectiveCalcDate,  COUNT(*)
--from #ActivityActivation A
--group by A.ServiceUniversalID, A.EventType, A.EffectiveCalcDate
--having  COUNT(*) > 1

--select count(*) from #ActivityActivation 



/******************************************************************************
*         Activity PostPaid Deactivation&Non-Same month Reactivation          *
*        #ActivityDeactReact has all eligible Act&Non-SameMonth React         *
******************************************************************************/
IF OBJECT_ID('tempdb..#EligibleTxnForReactDeact') is not Null
drop table #EligibleTxnForReactDeact

select * 
into #EligibleTxnForReactDeact
from (
	--select distinct A.ServiceUniversalID,A.EventType,A.SalesCode,A.EffectiveCalcDate
	--from #ActivityPostPaidActivation A
	--union 
	select distinct B.BillingSubSystemID,B.ServiceUniversalID,B.EventType,B.SalesCode,B.EffectiveCalcDate
	from archICSPaidActivations B
	) X

--select * from #EligibleTxnForReactDeact where ServiceUniversalID = '1849802344'

IF OBJECT_ID('tempdb..#EligibleReactDeactWT1') is not Null
drop table #EligibleReactDeactWT1

select X.*, D.DealerName,D.MasterDealerCode,D.CurrentMonth,D.ContractHolderID,D.ContractID,D.ContractHolderChannel,D.ContractChannel,D.ChannelType,D.AgreementType
	,M.MarketCode as UDFMarketCode,M.SamsonMktName
	,case when M.ContractID is not null then 1 else 0 end as InMarketFlag
	,ROW_NUMBER() over ( partition by X.ServiceUniversalID, X.EventType, X.EffectiveCalcDate order by case when M.MarketCode like '%[0-9]' then 1 else 2 end ) as MKTOrder 
into #EligibleReactDeactWT1
from (
	-----Non Same Month Reactivation-----
	select T.*, Act.SalesCode as SubscriberSalesCode,Act.EffectiveCalcDate as SubscriberActDate,Deact.EffectiveCalcDate as  SubscriberDeactDate
	from tsdICSActivity T
		left join tsdICSManualExclude E on T.ServiceUniversalID = E.ServiceUniversalID
			and T.EventType = E.EventType
			and T.EffectiveCalcDate = E.EffectiveCalcDate
		left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubTypeID and A.AccountType = T.AccountTypeID)
		--Change the logic based on Paul's comment
		inner join #EligibleTxnForReactDeact Act on T.ServiceUniversalID = Act.ServiceUniversalID 
			and Act.BillingSubSystemID = T.BillingSubsystemID
			and Act.EventType in  ('ACT','REACT') 
		inner join #EligibleTxnForReactDeact Deact on T.ServiceUniversalID = Deact.ServiceUniversalID 
			and Deact.BillingSubSystemID = T.BillingSubsystemID
			and Deact.EventType = 'DEACT' 
	where E.ServiceUniversalID is null
		and T.EventType = 'REACT' and isnull(SameMonth,'N/A') <> 'Y'
		and A.StartDate is null
	-----Deactivation-----
	union
	select T.*, Act.SalesCode as SubscriberSalesCode, Act.EffectiveCalcDate as SubscriberActDate,'' as SubscriberDeactDate
	from tsdICSActivity T
		left join tsdICSManualExclude E on T.ServiceUniversalID = E.ServiceUniversalID
			and T.EventType = E.EventType
			and T.EffectiveCalcDate = E.EffectiveCalcDate
		left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubTypeID and A.AccountType = T.AccountTypeID)
		--Change the logic based on Paul's comment
		inner join #EligibleTxnForReactDeact Act on T.ServiceUniversalID = Act.ServiceUniversalID 
			and Act.BillingSubSystemID = T.BillingSubsystemID
			and Act.EventType in ('ACT','REACT') and cast(T.EffectiveCalcDate as date)>= cast(Act.EffectiveCalcDate as date)
	where E.ServiceUniversalID is null
		and T.EventType = 'DEACT' and isnull(SameMonth,'N/A') <> 'Y'
		and A.StartDate is null
		--and T.ServiceUniversalID = '2305497747'
		) X
	inner join #DealerMonthlyEligibility D on D.SalesCode = X.SubscriberSalesCode
		and CAST(X.SubscriberActDate as date) between D.MonthStartDate and D.MonthEndDate 
	inner join #ProductEligibility P on X.PlanCode = P.ProductIDCode
		and X.BillingSubsystemID = P.BillingSubsystemID
		and CAST(X.SubscriberActDate as date) between P.StartDate and P.EndDate
	left join #MarketEligibility M on D.ContractID = M.ContractID
		and ((ISNULL(M.NPANXX,'')<>'' and X.NPANXX = M.NPANXX) or (ISNULL(M.NPANXX,'')='' and X.MarketCode = M.SamsonMktName))
		and CAST(X.SubscriberActDate as date) between M.StartDate and M.EndDate
where X.IsValid = '1.00'
--select * from #EligibleReactDeactWT1 where ServiceUniversalID = '2305306952'

--select ServiceUniversalID,EventType from #EligibleReactDeactWT1
--where MKTOrder = 1
--group by ServiceUniversalID,EventType
--having count(*) > 1

IF OBJECT_ID('tempdb..#EligibleReactDeactWT2') is not Null
drop table #EligibleReactDeactWT2


select DR.*
	,P.HighLevelChannel as CRHighLevelChannel,P.AgreementType as CRAgreementType,P.MasterDealerCode as CRMasterDealerCode,P.ContractID as CRContractID,P.ValueText as CRLevel
into #EligibleReactDeactWT2
from #EligibleReactDeactWT1 DR
	left join cfgICSContractParams P on P.Name = 'CHARGEBACKLEVEL'
		and P.HighLevelChannel = 'ALL' and P.AgreementType = 'ALL' and P.MasterDealerCode = 'ALL' and P.ContractID = 'ALL'
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
where DR.MKTOrder = 1
	--and ServiceUniversalID = '2306048568'
--order by ServiceUniversalID


-----Begin to apply the level by sequence, Contract > MasterDealer > AgreementType > HighLevelChannel

update DR 
set DR.CRLevel = P.ValueText, DR.CRHighLevelChannel = P.HighLevelChannel
from #EligibleReactDeactWT2 DR
	inner join cfgICSContractParams P on P.Name = 'CHARGEBACKLEVEL'
		and DR.ContractHolderChannel = P.HighLevelChannel
		and P.AgreementType = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)

update DR 
set DR.CRLevel = P.ValueText, DR.CRHighLevelChannel = P.HighLevelChannel,DR.CRAgreementType = P.AgreementType
from #EligibleReactDeactWT2 DR
	inner join cfgICSContractParams P on P.Name = 'CHARGEBACKLEVEL'
		and DR.ContractHolderChannel = P.HighLevelChannel
		and P.AgreementType = DR.AgreementType
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		
update DR 
set DR.CRLevel = P.ValueText, DR.CRHighLevelChannel = P.HighLevelChannel,DR.CRAgreementType = P.AgreementType,DR.CRMasterDealerCode = P.MasterDealerCode
from #EligibleReactDeactWT2 DR
	inner join cfgICSContractParams P on P.Name = 'CHARGEBACKLEVEL'
		and DR.ContractHolderChannel = P.HighLevelChannel
		and P.AgreementType = DR.AgreementType
		and P.MasterDealerCode = DR.MasterDealerCode
		and P.ContractID = 'ALL'
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		
update DR 
set DR.CRLevel = P.ValueText, DR.CRHighLevelChannel = P.HighLevelChannel,DR.CRAgreementType = P.AgreementType,DR.CRMasterDealerCode = P.MasterDealerCode,DR.CRContractID = P.ContractID
from #EligibleReactDeactWT2 DR
	inner join cfgICSContractParams P on P.Name = 'CHARGEBACKLEVEL'
		and DR.ContractHolderChannel = P.HighLevelChannel
		and P.AgreementType = DR.AgreementType
		and P.MasterDealerCode = DR.MasterDealerCode
		and P.ContractID = DR.ContractID
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		
Delete From
#EligibleReactDeactWT2 
where ISNULL(CRHighLevelChannel,'') = ''
	and ISNULL(CRAgreementType,'') = ''
	and ISNULL(CRMasterDealerCode,'') = ''
	and ISNULL(CRContractID,'') = ''


--select * from #EligibleReactDeactWT2 where ServiceUniversalID = '2306048568'

IF OBJECT_ID('tempdb..#ActivityDeactReact') is not Null
drop table #ActivityDeactReact

select * 
into #ActivityDeactReact
from (
	select T.*,P.Level,P.LevelNumber,P.LongName,C.Event,C.LevelGroup,C.ChargeBackDays,C.ReactDays
		,ROW_NUMBER() Over(Partition by SubscriberActivityKey,EventType order by P.LevelNumber desc) as SocLevel 

	from #EligibleReactDeactWT2 T
		inner join cfgICSProductCategory P on T.PlanCode = P.ProductIDCode
		inner join cfgICSContractProductLevels C on P.Level = C.Level
			and T.CRLevel = C.LevelGroup
	where P.Level in (
		'POSTPAID FEATURE',	
		'PREPAID CATEGORIES',	
		'PREPAID FEATURE',	
		'POSTPAID CATEGORIES',
		'POSTPAID CATEGORIES',
		'POSTPAID CATEGORIES'
		)
		and ((P.Level = 'PREPAID CATEGORIES' and C.Event = 'FEATURE')
			or (P.Level = 'POSTPAID CATEGORIES' and T.IsAddALine = 'N' and C.Event = 'ACTIVITY')
			or (P.Level = 'POSTPAID CATEGORIES' and T.IsAddALine = 'Y' and C.Event = 'AAL')) 
		-----ChargeBack&React Window check-----
		and ((EventType = 'DEACT' and (datediff(dd, T.ActDate, T.EffectiveCalcDate)<= ChargeBackDays
			or datediff(dd, T.ActDate, T.LastSuspendDate)<= ChargeBackDays))
		OR (EventType = 'REACT' and datediff(dd, T.DeactDate, T.ReactDate)<= ReactDays))
	) X
where X.SocLevel = 1

--select * from #ActivityDeactReact



/******************************************************************************
*                                                                             *
*                  Positive Scenarios Test Result                             *
*                                                                             *
******************************************************************************/

-- DEL0000	Activity PostPaid Activation					
--	Preconditions				
--		Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business			
--		AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business			
--		Dealer codes eligible for activation transactions based on sales code hierarchy			
--		Eligible commissionable products for all activation transactions			
--		In market activations for dealers			
						
--	Expected	Transaction is Eligible	(Calc: ICS Activation 1075)		
--		Transaction available in the list of eligible postpaid activation and reactivation transactions			

select T1.BillingSubsystemID, T1.ServiceUniversalID, T1.EventType, T1.EffectiveCalcDate, T1.SubscriberActivityKey, T1.ProfileID
  , T1.ActDate, T1.DeactDate, T1.ReactDate, T1.CustomerBAN, T1.SubscriberName, T1.CreditClass, T1.PlanCode, T1.PoolingMRC, T1.RecAccess
  , T1.MarketCode, T1.NPANXX, T1.ServiceNumber, T1.SameMonth, T1.SIM, T1.IMEI, T1.DepositAmount, T1.IsAddALine, T1.AddALineCode, T1.LastSuspendDate
  , T1.PortType, T1.ContractTerm, T1.AccountTypeID, T1.AccountSubTypeID, T1.EBTVIndicator, T1.HOTI, T1.OtherNetSP, T1.CorpNodeNumber, T1.SalesCode
  , T1.TotalMRC, T1.DiscountMRC, T1.IsValid, T1.CreditType, T1.FullyLoaded, T1.TAC, T1.ShipToMaster, T1.FirstUseDate, T1.COBIndicator, T1.ShippedDate
  , T1.SrlznBAN, T1.SrlznMSISDN, T1.SourceHOTI, T1.DealerName, T1.MasterDealerCode, T1.CurrentMonth, T1.ContractHolderID, T1.ContractID, T1.ContractHolderChannel
  , T1.ContractChannel, T1.ChannelType, T1.AgreementType, T1.UDFMarketCode, T1.SamsonMktName, T1.InMarketFlag
from #ActivityActivation T1
where BillingSubsystemID = '1'
  and IsAddALine = 'N'
  and T1.CurrentMonth = '2013, Month 06'
union 
select T2.BillingSubsystemID, T2.ServiceUniversalID, T2.EventType, T2.EffectiveCalcDate, T2.SubscriberActivityKey, T2.ProfileID
  , T2.ActDate, T2.DeactDate, T2.ReactDate, T2.CustomerBAN, T2.SubscriberName, T2.CreditClass, T2.PlanCode, T2.PoolingMRC, T2.RecAccess
  , T2.MarketCode, T2.NPANXX, T2.ServiceNumber, T2.SameMonth, T2.SIM, T2.IMEI, T2.DepositAmount, T2.IsAddALine, T2.AddALineCode, T2.LastSuspendDate
  , T2.PortType, T2.ContractTerm, T2.AccountTypeID, T2.AccountSubTypeID, T2.EBTVIndicator, T2.HOTI, T2.OtherNetSP, T2.CorpNodeNumber, T2.SalesCode
  , T2.TotalMRC, T2.DiscountMRC, T2.IsValid, T2.CreditType, T2.FullyLoaded, T2.TAC, T2.ShipToMaster, T2.FirstUseDate, T2.COBIndicator, T2.ShippedDate
  , T2.SrlznBAN, T2.SrlznMSISDN, T2.SourceHOTI, T2.DealerName, T2.MasterDealerCode, T2.CurrentMonth, T2.ContractHolderID, T2.ContractID, T2.ContractHolderChannel
  , T2.ContractChannel, T2.ChannelType, T2.AgreementType, T2.UDFMarketCode, T2.SamsonMktName, T2.InMarketFlag
from #ActivityDeactReact T2
where BillingSubsystemID = '1'
  and IsAddALine = 'N'
  and EventType = 'REACT'
  and T2.CurrentMonth = '2013, Month 06'


/*********************************************************************************************************************************************************************/
--DEL0001	Activity AddALine Activation					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business			
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business			
--			Dealer codes eligible for activation transactions based on sales code hierarchy			
--			Eligible commissionable products for all activation transactions			
--			In market activations for dealers			
--						
--		Expected	Transaction is Eligible	(Calc: ICS Activation 1080 )		
--			Transaction available in the list of eligible AAL transactions			

select T1.BillingSubsystemID, T1.ServiceUniversalID, T1.EventType, T1.EffectiveCalcDate, T1.SubscriberActivityKey, T1.ProfileID
  , T1.ActDate, T1.DeactDate, T1.ReactDate, T1.CustomerBAN, T1.SubscriberName, T1.CreditClass, T1.PlanCode, T1.PoolingMRC, T1.RecAccess
  , T1.MarketCode, T1.NPANXX, T1.ServiceNumber, T1.SameMonth, T1.SIM, T1.IMEI, T1.DepositAmount, T1.IsAddALine, T1.AddALineCode, T1.LastSuspendDate
  , T1.PortType, T1.ContractTerm, T1.AccountTypeID, T1.AccountSubTypeID, T1.EBTVIndicator, T1.HOTI, T1.OtherNetSP, T1.CorpNodeNumber, T1.SalesCode
  , T1.TotalMRC, T1.DiscountMRC, T1.IsValid, T1.CreditType, T1.FullyLoaded, T1.TAC, T1.ShipToMaster, T1.FirstUseDate, T1.COBIndicator, T1.ShippedDate
  , T1.SrlznBAN, T1.SrlznMSISDN, T1.SourceHOTI, T1.DealerName, T1.MasterDealerCode, T1.CurrentMonth, T1.ContractHolderID, T1.ContractID, T1.ContractHolderChannel
  , T1.ContractChannel, T1.ChannelType, T1.AgreementType, T1.UDFMarketCode, T1.SamsonMktName,T1.InMarketFlag
from #ActivityActivation T1
where BillingSubsystemID = '1'  
  and IsAddALine = 'Y'
  and T1.CurrentMonth = '2013, Month 06'
union 
select T2.BillingSubsystemID, T2.ServiceUniversalID, T2.EventType, T2.EffectiveCalcDate, T2.SubscriberActivityKey, T2.ProfileID
  , T2.ActDate, T2.DeactDate, T2.ReactDate, T2.CustomerBAN, T2.SubscriberName, T2.CreditClass, T2.PlanCode, T2.PoolingMRC, T2.RecAccess
  , T2.MarketCode, T2.NPANXX, T2.ServiceNumber, T2.SameMonth, T2.SIM, T2.IMEI, T2.DepositAmount, T2.IsAddALine, T2.AddALineCode, T2.LastSuspendDate
  , T2.PortType, T2.ContractTerm, T2.AccountTypeID, T2.AccountSubTypeID, T2.EBTVIndicator, T2.HOTI, T2.OtherNetSP, T2.CorpNodeNumber, T2.SalesCode
  , T2.TotalMRC, T2.DiscountMRC, T2.IsValid, T2.CreditType, T2.FullyLoaded, T2.TAC, T2.ShipToMaster, T2.FirstUseDate, T2.COBIndicator, T2.ShippedDate
  , T2.SrlznBAN, T2.SrlznMSISDN, T2.SourceHOTI, T2.DealerName, T2.MasterDealerCode, T2.CurrentMonth, T2.ContractHolderID, T2.ContractID, T2.ContractHolderChannel
  , T2.ContractChannel, T2.ChannelType, T2.AgreementType, T2.UDFMarketCode, T2.SamsonMktName, T2.InMarketFlag
from #ActivityDeactReact T2
where BillingSubsystemID = '1'
  and IsAddALine = 'Y'
  and EventType = 'REACT'
  and T2.CurrentMonth = '2013, Month 06'

/*********************************************************************************************************************************************************************/
--DEL0002	Activity Prepaid Activation					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business			
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business			
--			Dealer codes eligible for activation transactions based on sales code hierarchy			
--			Eligible commissionable products for all activation transactions			
--			In market activations for dealers			
--						
--		Expected	Transaction is Eligible	 (Calc: ICS Activation 1085)		
--			Transaction available in the list of eligible Prepaid transactions			
  
select T1.BillingSubsystemID, T1.ServiceUniversalID, T1.EventType, T1.EffectiveCalcDate, T1.SubscriberActivityKey, T1.ProfileID
  , T1.ActDate, T1.DeactDate, T1.ReactDate, T1.CustomerBAN, T1.SubscriberName, T1.CreditClass, T1.PlanCode, T1.PoolingMRC, T1.RecAccess
  , T1.MarketCode, T1.NPANXX, T1.ServiceNumber, T1.SameMonth, T1.SIM, T1.IMEI, T1.DepositAmount, T1.IsAddALine, T1.AddALineCode, T1.LastSuspendDate
  , T1.PortType, T1.ContractTerm, T1.AccountTypeID, T1.AccountSubTypeID, T1.EBTVIndicator, T1.HOTI, T1.OtherNetSP, T1.CorpNodeNumber, T1.SalesCode
  , T1.TotalMRC, T1.DiscountMRC, T1.IsValid, T1.CreditType, T1.FullyLoaded, T1.TAC, T1.ShipToMaster, T1.FirstUseDate, T1.COBIndicator, T1.ShippedDate
  , T1.SrlznBAN, T1.SrlznMSISDN, T1.SourceHOTI, T1.DealerName, T1.MasterDealerCode, T1.CurrentMonth, T1.ContractHolderID, T1.ContractID, T1.ContractHolderChannel
  , T1.ContractChannel, T1.ChannelType, T1.AgreementType, T1.UDFMarketCode, T1.SamsonMktName, T1.InMarketFlag
from #ActivityActivation T1
where BillingSubsystemID  in ('2','5')
  and IsAddALine = 'N'
  and T1.CurrentMonth = '2013, Month 06'
union 
select T2.BillingSubsystemID, T2.ServiceUniversalID, T2.EventType, T2.EffectiveCalcDate, T2.SubscriberActivityKey, T2.ProfileID
  , T2.ActDate, T2.DeactDate, T2.ReactDate, T2.CustomerBAN, T2.SubscriberName, T2.CreditClass, T2.PlanCode, T2.PoolingMRC, T2.RecAccess
  , T2.MarketCode, T2.NPANXX, T2.ServiceNumber, T2.SameMonth, T2.SIM, T2.IMEI, T2.DepositAmount, T2.IsAddALine, T2.AddALineCode, T2.LastSuspendDate
  , T2.PortType, T2.ContractTerm, T2.AccountTypeID, T2.AccountSubTypeID, T2.EBTVIndicator, T2.HOTI, T2.OtherNetSP, T2.CorpNodeNumber, T2.SalesCode
  , T2.TotalMRC, T2.DiscountMRC, T2.IsValid, T2.CreditType, T2.FullyLoaded, T2.TAC, T2.ShipToMaster, T2.FirstUseDate, T2.COBIndicator, T2.ShippedDate
  , T2.SrlznBAN, T2.SrlznMSISDN, T2.SourceHOTI, T2.DealerName, T2.MasterDealerCode, T2.CurrentMonth, T2.ContractHolderID, T2.ContractID, T2.ContractHolderChannel
  , T2.ContractChannel, T2.ChannelType, T2.AgreementType, T2.UDFMarketCode, T2.SamsonMktName, T2.InMarketFlag
from #ActivityDeactReact T2
where BillingSubsystemID in ('2','5')
  and IsAddALine = 'N'
  and EventType = 'REACT'
  and T2.CurrentMonth = '2013, Month 06'
  
  
/*********************************************************************************************************************************************************************/
--DEL0003	Activity PostPaid Deactivation - Comp Contract Setup					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business			
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business			
--			Deactivations match with paid historical activations based on archICSPaidActivations table			
--			Eligible dealer codes for deact transactions based on sales code hierarchy			
--			Eligible commissionable products for all deactivation transactions			
--			The date difference between the LastSuspenddate and the act date of the transaction is within the specified timeframe of the ChargeBackdays parameter in  “cfgICSContractProductLeve			
--			The date difference between the deact date and act date is within the timeframe defined in the “ChargeBackDays” parameter in the “cfgICSContractProductLevel” table for the deact transactions			
--			Tag out of market\in market deactivations for dealers and filter out of market deacts			
--			Compensation levelGroup based on  Contracts setup for chargebacks from the “cfgICSContractParms” table.			
						
--		Expected	Transaction is Eligible	 (Calc: ICS Activation 1090)		
--			Transaction available in thelist of eligible postpaid deactivation transactions			

select * 
from #ActivityDeactReact T2
where 1=1
	and BillingSubsystemID = '1'
    and EventType = 'DEACT'
    and IsAddALine = 'N'
    and CRHighLevelChannel <> 'ALL'
    and CRAgreementType <> 'ALL'
    and CRMasterDealerCode <> 'ALL'
    and CRContractID <> 'ALL'


/*********************************************************************************************************************************************************************/	
--DEL0004	Activity PostPaid Deactivation - Comp Masterdealer Setup					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business			
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business			
--			Deactivations match with paid historical activations based on archICSPaidActivations table			
--			Eligible dealer codes for deact transactions based on sales code hierarchy			
--			Eligible commissionable products for all deactivation transactions			
--			The date difference between the LastSuspenddate and the act date of the transaction is within the specified timeframe of the ChargeBackdays parameter in  “cfgICSContractProductLeve			
--			The date difference between the deact date and act date is within the timeframe defined in the “ChargeBackDays” parameter in the “cfgICSContractProductLevel” table for the deact transactions			
--			Tag out of market\in market deactivations for dealers and filter out of market deacts			
--			Compensation levelGroup based on Masterdealer setup for chargebacks from the “cfgICSContractParms” table.			
						
--		Expected	Transaction is Eligible			
--			Transaction available in thelist of eligible postpaid deactivation transactions			

select * 
from #ActivityDeactReact T2
where 1=1
	--and BillingSubsystemID = '1'
    and EventType = 'DEACT'
    and IsAddALine = 'N'
    and CRHighLevelChannel <> 'ALL'
    and CRAgreementType <> 'ALL'
    and CRMasterDealerCode <> 'ALL'
    and CRContractID = 'ALL'
   
/*********************************************************************************************************************************************************************/ 
--DEL0005	Activity PostPaid Deactivation - Comp AgreementType Setup					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business			
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business			
--			Deactivations match with paid historical activations based on archICSPaidActivations table			
--			Eligible dealer codes for deact transactions based on sales code hierarchy			
--			Eligible commissionable products for all deactivation transactions			
--			The date difference between the LastSuspenddate and the act date of the transaction is within the specified timeframe of the ChargeBackdays parameter in  “cfgICSContractProductLeve			
--			The date difference between the deact date and act date is within the timeframe defined in the “ChargeBackDays” parameter in the “cfgICSContractProductLevel” table for the deact transactions			
--			Tag out of market\in market deactivations for dealers and filter out of market deacts			
--			Compensation levelGroup based on AgreementType setup for chargebacks from the “cfgICSContractParms” table.			
						
--		Expected	Transaction is Eligible			
--			Transaction available in thelist of eligible postpaid deactivation transactions			

select * 
from #ActivityDeactReact T2
where 1=1
	--and BillingSubsystemID = '1'
    and EventType = 'DEACT'
    and IsAddALine = 'N'
    and CRHighLevelChannel <> 'ALL'
    and CRAgreementType <> 'ALL'
    and CRMasterDealerCode = 'ALL'
    and CRContractID = 'ALL'
 
 
/*********************************************************************************************************************************************************************/   
--DEL0006	Activity PostPaid Deactivation - Comp HighLevelChannel Setup					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business			
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business			
--			Deactivations match with paid historical activations based on archICSPaidActivations table			
--			Eligible dealer codes for deact transactions based on sales code hierarchy			
--			Eligible commissionable products for all deactivation transactions			
--			The date difference between the LastSuspenddate and the act date of the transaction is within the specified timeframe of the ChargeBackdays parameter in  “cfgICSContractProductLeve			
--			The date difference between the deact date and act date is within the timeframe defined in the “ChargeBackDays” parameter in the “cfgICSContractProductLevel” table for the deact transactions			
--			Tag out of market\in market deactivations for dealers and filter out of market deacts			
--			Compensation levelGroup based on HighLevelChannel  setup for chargebacks from the “cfgICSContractParms” table.			
						
--		Expected	Transaction is Eligible			
--			Transaction available in thelist of eligible postpaid deactivation transactions			

select * 
from #ActivityDeactReact T2
where 1=1
	--and BillingSubsystemID = '1'
    and EventType = 'DEACT'
    and IsAddALine = 'N'
    and CRHighLevelChannel <> 'ALL'
    and CRAgreementType = 'ALL'
    and CRMasterDealerCode = 'ALL'
    and CRContractID = 'ALL'
   
   
/*********************************************************************************************************************************************************************/ 
--DEL0007	Activity AddALine Deactivation - Comp Contract Setup					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business			
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business			
--			Deactivations match with paid historical activations based on archICSPaidActivations table			
--			Eligible dealer codes for deact transactions based on sales code hierarchy			
--			Eligible commissionable products for all deactivation transactions			
--			The date difference between the LastSuspenddate and the act date of the transaction is within the specified timeframe of the ChargeBackdays parameter in  “cfgICSContractProductLeve			
--			The date difference between the deact date and act date is within the timeframe defined in the “ChargeBackDays” parameter in the “cfgICSContractProductLevel” table for the deact transactions			
--			Tag out of market\in market deactivations for dealers and filter out of market deacts			
--			Compensation levelGroup based on  Contracts setup for chargebacks from the “cfgICSContractParms” table.			
						
--		Expected	Transaction is Eligible			
--			Transaction available in thelist of eligible postpaid deactivation transactions			

select * 
from #ActivityDeactReact T2
where 1=1
	--and BillingSubsystemID = '1'
    and EventType = 'DEACT'
    and IsAddALine = 'Y'
    --and CRHighLevelChannel <> 'ALL'
    --and CRAgreementType <> 'ALL'
    --and CRMasterDealerCode <> 'ALL'
    --and CRContractID <> 'ALL'
    
/*********************************************************************************************************************************************************************/
--DEL0008	Activity Prepaid Deactivation - Comp Contract Setup					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business			
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business			
--			Deactivations match with paid historical activations based on archICSPaidActivations table			
--			Eligible dealer codes for deact transactions based on sales code hierarchy			
--			Eligible commissionable products for all deactivation transactions			
--			The date difference between the LastSuspenddate and the act date of the transaction is within the specified timeframe of the ChargeBackdays parameter in  “cfgICSContractProductLeve			
--			The date difference between the deact date and act date is within the timeframe defined in the “ChargeBackDays” parameter in the “cfgICSContractProductLevel” table for the deact transactions			
--			Tag out of market\in market deactivations for dealers and filter out of market deacts			
--			Compensation levelGroup based on  Contracts setup for chargebacks from the “cfgICSContractParms” table.			
						
--		Expected	Transaction is Eligible			
--			Transaction available in thelist of eligible postpaid deactivation transactions			

select *
from #ActivityDeactReact T2
where BillingSubsystemID in ('2','5')  
  and IsAddALine = 'N'
  and EventType = 'DEACT'
/*********************************************************************************************************************************************************************/  
  
--DEL0009	Activity PostPaid Reactivation					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business			
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business			
--			Reactivations match with paid historical deactivations based on archICSPaidActivations table			
--			Eligible dealer codes for react transactions based on sales code hierarchy			
--			Check if the date difference between the react date and the deact date of the transaction is within the specified timeframe of the reactdays parameter in  “cfgICSContractProductLeve			
						
--		Expected	Transaction is Eligible			
--			Transaction available in the list of eligible postpaid activation and reactivation transactions			

select T1.BillingSubsystemID, T1.ServiceUniversalID, T1.EventType, T1.EffectiveCalcDate, T1.SubscriberActivityKey, T1.ProfileID
  , T1.ActDate, T1.DeactDate, T1.ReactDate, T1.CustomerBAN, T1.SubscriberName, T1.CreditClass, T1.PlanCode, T1.PoolingMRC, T1.RecAccess
  , T1.MarketCode, T1.NPANXX, T1.ServiceNumber, T1.SameMonth, T1.SIM, T1.IMEI, T1.DepositAmount, T1.IsAddALine, T1.AddALineCode, T1.LastSuspendDate
  , T1.PortType, T1.ContractTerm, T1.AccountTypeID, T1.AccountSubTypeID, T1.EBTVIndicator, T1.HOTI, T1.OtherNetSP, T1.CorpNodeNumber, T1.SalesCode
  , T1.TotalMRC, T1.DiscountMRC, T1.IsValid, T1.CreditType, T1.FullyLoaded, T1.TAC, T1.ShipToMaster, T1.FirstUseDate, T1.COBIndicator, T1.ShippedDate
  , T1.SrlznBAN, T1.SrlznMSISDN, T1.SourceHOTI, T1.DealerName, T1.MasterDealerCode, T1.CurrentMonth, T1.ContractHolderID, T1.ContractID, T1.ContractHolderChannel
  , T1.ContractChannel, T1.ChannelType, T1.AgreementType, T1.UDFMarketCode, T1.SamsonMktName
from #ActivityActivation T1
where BillingSubsystemID = '1'
  and IsAddALine = 'N'
  and EventType = 'REACT'
union 
select T2.BillingSubsystemID, T2.ServiceUniversalID, T2.EventType, T2.EffectiveCalcDate, T2.SubscriberActivityKey, T2.ProfileID
  , T2.ActDate, T2.DeactDate, T2.ReactDate, T2.CustomerBAN, T2.SubscriberName, T2.CreditClass, T2.PlanCode, T2.PoolingMRC, T2.RecAccess
  , T2.MarketCode, T2.NPANXX, T2.ServiceNumber, T2.SameMonth, T2.SIM, T2.IMEI, T2.DepositAmount, T2.IsAddALine, T2.AddALineCode, T2.LastSuspendDate
  , T2.PortType, T2.ContractTerm, T2.AccountTypeID, T2.AccountSubTypeID, T2.EBTVIndicator, T2.HOTI, T2.OtherNetSP, T2.CorpNodeNumber, T2.SalesCode
  , T2.TotalMRC, T2.DiscountMRC, T2.IsValid, T2.CreditType, T2.FullyLoaded, T2.TAC, T2.ShipToMaster, T2.FirstUseDate, T2.COBIndicator, T2.ShippedDate
  , T2.SrlznBAN, T2.SrlznMSISDN, T2.SourceHOTI, T2.DealerName, T2.MasterDealerCode, T2.CurrentMonth, T2.ContractHolderID, T2.ContractID, T2.ContractHolderChannel
  , T2.ContractChannel, T2.ChannelType, T2.AgreementType, T2.UDFMarketCode, T2.SamsonMktName
from #ActivityDeactReact T2
where BillingSubsystemID = '1'
  and IsAddALine = 'N'
  and EventType = 'REACT'
  
/*********************************************************************************************************************************************************************/  
--DEL0010	Activity AddALine Reactivation					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business			
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business			
--			Reactivations match with paid historical deactivations based on archICSPaidActivations table			
--			Eligible dealer codes for react transactions based on sales code hierarchy			
--			Check if the date difference between the react date and the deact date of the transaction is within the specified timeframe of the reactdays parameter in  “cfgICSContractProductLeve			
						
--		Expected	Transaction is Eligible			
--			Transaction available in the list of eligible AAL transactions			

select T1.BillingSubsystemID, T1.ServiceUniversalID, T1.EventType, T1.EffectiveCalcDate, T1.SubscriberActivityKey, T1.ProfileID
  , T1.ActDate, T1.DeactDate, T1.ReactDate, T1.CustomerBAN, T1.SubscriberName, T1.CreditClass, T1.PlanCode, T1.PoolingMRC, T1.RecAccess
  , T1.MarketCode, T1.NPANXX, T1.ServiceNumber, T1.SameMonth, T1.SIM, T1.IMEI, T1.DepositAmount, T1.IsAddALine, T1.AddALineCode, T1.LastSuspendDate
  , T1.PortType, T1.ContractTerm, T1.AccountTypeID, T1.AccountSubTypeID, T1.EBTVIndicator, T1.HOTI, T1.OtherNetSP, T1.CorpNodeNumber, T1.SalesCode
  , T1.TotalMRC, T1.DiscountMRC, T1.IsValid, T1.CreditType, T1.FullyLoaded, T1.TAC, T1.ShipToMaster, T1.FirstUseDate, T1.COBIndicator, T1.ShippedDate
  , T1.SrlznBAN, T1.SrlznMSISDN, T1.SourceHOTI, T1.DealerName, T1.MasterDealerCode, T1.CurrentMonth, T1.ContractHolderID, T1.ContractID, T1.ContractHolderChannel
  , T1.ContractChannel, T1.ChannelType, T1.AgreementType, T1.UDFMarketCode, T1.SamsonMktName
from #ActivityActivation T1
where 1=1
  --and BillingSubsystemID = '1'
  and IsAddALine = 'Y'
  and EventType = 'REACT'
union 
select T2.BillingSubsystemID, T2.ServiceUniversalID, T2.EventType, T2.EffectiveCalcDate, T2.SubscriberActivityKey, T2.ProfileID
  , T2.ActDate, T2.DeactDate, T2.ReactDate, T2.CustomerBAN, T2.SubscriberName, T2.CreditClass, T2.PlanCode, T2.PoolingMRC, T2.RecAccess
  , T2.MarketCode, T2.NPANXX, T2.ServiceNumber, T2.SameMonth, T2.SIM, T2.IMEI, T2.DepositAmount, T2.IsAddALine, T2.AddALineCode, T2.LastSuspendDate
  , T2.PortType, T2.ContractTerm, T2.AccountTypeID, T2.AccountSubTypeID, T2.EBTVIndicator, T2.HOTI, T2.OtherNetSP, T2.CorpNodeNumber, T2.SalesCode
  , T2.TotalMRC, T2.DiscountMRC, T2.IsValid, T2.CreditType, T2.FullyLoaded, T2.TAC, T2.ShipToMaster, T2.FirstUseDate, T2.COBIndicator, T2.ShippedDate
  , T2.SrlznBAN, T2.SrlznMSISDN, T2.SourceHOTI, T2.DealerName, T2.MasterDealerCode, T2.CurrentMonth, T2.ContractHolderID, T2.ContractID, T2.ContractHolderChannel
  , T2.ContractChannel, T2.ChannelType, T2.AgreementType, T2.UDFMarketCode, T2.SamsonMktName
from #ActivityDeactReact T2
where 1=1
  --and BillingSubsystemID = '1'
  and IsAddALine = 'Y'
  and EventType = 'REACT'


/*********************************************************************************************************************************************************************/    
--DEL0011	Activity PostPaid Activation - Out-of-Market					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business			
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business			
--			Dealer codes eligible for activation transactions based on sales code hierarchy			
--			Eligible commissionable products for all activation transactions			
--			In market activations for dealers			
						
--		Expected	Transaction is Eligible			
--			Transaction available in the list of eligible postpaid activation and reactivation transactions			
--			Transaction flagget as out-of-market	
		
select T1.BillingSubsystemID, T1.ServiceUniversalID, T1.EventType, T1.EffectiveCalcDate, T1.SubscriberActivityKey, T1.ProfileID
  , T1.ActDate, T1.DeactDate, T1.ReactDate, T1.CustomerBAN, T1.SubscriberName, T1.CreditClass, T1.PlanCode, T1.PoolingMRC, T1.RecAccess
  , T1.MarketCode, T1.NPANXX, T1.ServiceNumber, T1.SameMonth, T1.SIM, T1.IMEI, T1.DepositAmount, T1.IsAddALine, T1.AddALineCode, T1.LastSuspendDate
  , T1.PortType, T1.ContractTerm, T1.AccountTypeID, T1.AccountSubTypeID, T1.EBTVIndicator, T1.HOTI, T1.OtherNetSP, T1.CorpNodeNumber, T1.SalesCode
  , T1.TotalMRC, T1.DiscountMRC, T1.IsValid, T1.CreditType, T1.FullyLoaded, T1.TAC, T1.ShipToMaster, T1.FirstUseDate, T1.COBIndicator, T1.ShippedDate
  , T1.SrlznBAN, T1.SrlznMSISDN, T1.SourceHOTI, T1.DealerName, T1.MasterDealerCode, T1.CurrentMonth, T1.ContractHolderID, T1.ContractID, T1.ContractHolderChannel
  , T1.ContractChannel, T1.ChannelType, T1.AgreementType, T1.UDFMarketCode, T1.SamsonMktName, T1.InMarketFlag
from #ActivityActivation T1
where BillingSubsystemID = '1'
  and IsAddALine = 'N'
  and T1.CurrentMonth = '2013, Month 06'
  and InMarketFlag = '0'
union 
select T2.BillingSubsystemID, T2.ServiceUniversalID, T2.EventType, T2.EffectiveCalcDate, T2.SubscriberActivityKey, T2.ProfileID
  , T2.ActDate, T2.DeactDate, T2.ReactDate, T2.CustomerBAN, T2.SubscriberName, T2.CreditClass, T2.PlanCode, T2.PoolingMRC, T2.RecAccess
  , T2.MarketCode, T2.NPANXX, T2.ServiceNumber, T2.SameMonth, T2.SIM, T2.IMEI, T2.DepositAmount, T2.IsAddALine, T2.AddALineCode, T2.LastSuspendDate
  , T2.PortType, T2.ContractTerm, T2.AccountTypeID, T2.AccountSubTypeID, T2.EBTVIndicator, T2.HOTI, T2.OtherNetSP, T2.CorpNodeNumber, T2.SalesCode
  , T2.TotalMRC, T2.DiscountMRC, T2.IsValid, T2.CreditType, T2.FullyLoaded, T2.TAC, T2.ShipToMaster, T2.FirstUseDate, T2.COBIndicator, T2.ShippedDate
  , T2.SrlznBAN, T2.SrlznMSISDN, T2.SourceHOTI, T2.DealerName, T2.MasterDealerCode, T2.CurrentMonth, T2.ContractHolderID, T2.ContractID, T2.ContractHolderChannel
  , T2.ContractChannel, T2.ChannelType, T2.AgreementType, T2.UDFMarketCode, T2.SamsonMktName, T2.InMarketFlag
from #ActivityDeactReact T2
where BillingSubsystemID = '1'
  and IsAddALine = 'N'
  and EventType = 'REACT'
  and T2.CurrentMonth = '2013, Month 06'
  and InMarketFlag = '0'
  
/*********************************************************************************************************************************************************************/    
--DEL0012	Activity AddALine Activation  - Out-of-Market					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business			
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business			
--			Dealer codes eligible for activation transactions based on sales code hierarchy			
--			Eligible commissionable products for all activation transactions			
--			In market activations for dealers			
						
--		Expected	Transaction is Eligible			
--			Transaction available in the list of eligible AAL transactions			
--			Transaction flagget as out-of-market		

select T1.BillingSubsystemID, T1.ServiceUniversalID, T1.EventType, T1.EffectiveCalcDate, T1.SubscriberActivityKey, T1.ProfileID
  , T1.ActDate, T1.DeactDate, T1.ReactDate, T1.CustomerBAN, T1.SubscriberName, T1.CreditClass, T1.PlanCode, T1.PoolingMRC, T1.RecAccess
  , T1.MarketCode, T1.NPANXX, T1.ServiceNumber, T1.SameMonth, T1.SIM, T1.IMEI, T1.DepositAmount, T1.IsAddALine, T1.AddALineCode, T1.LastSuspendDate
  , T1.PortType, T1.ContractTerm, T1.AccountTypeID, T1.AccountSubTypeID, T1.EBTVIndicator, T1.HOTI, T1.OtherNetSP, T1.CorpNodeNumber, T1.SalesCode
  , T1.TotalMRC, T1.DiscountMRC, T1.IsValid, T1.CreditType, T1.FullyLoaded, T1.TAC, T1.ShipToMaster, T1.FirstUseDate, T1.COBIndicator, T1.ShippedDate
  , T1.SrlznBAN, T1.SrlznMSISDN, T1.SourceHOTI, T1.DealerName, T1.MasterDealerCode, T1.CurrentMonth, T1.ContractHolderID, T1.ContractID, T1.ContractHolderChannel
  , T1.ContractChannel, T1.ChannelType, T1.AgreementType, T1.UDFMarketCode, T1.SamsonMktName,T1.InMarketFlag
from #ActivityActivation T1
where BillingSubsystemID = '1'  
  and IsAddALine = 'Y'
  and T1.CurrentMonth = '2013, Month 06'
  and InMarketFlag = '0'
union 
select T2.BillingSubsystemID, T2.ServiceUniversalID, T2.EventType, T2.EffectiveCalcDate, T2.SubscriberActivityKey, T2.ProfileID
  , T2.ActDate, T2.DeactDate, T2.ReactDate, T2.CustomerBAN, T2.SubscriberName, T2.CreditClass, T2.PlanCode, T2.PoolingMRC, T2.RecAccess
  , T2.MarketCode, T2.NPANXX, T2.ServiceNumber, T2.SameMonth, T2.SIM, T2.IMEI, T2.DepositAmount, T2.IsAddALine, T2.AddALineCode, T2.LastSuspendDate
  , T2.PortType, T2.ContractTerm, T2.AccountTypeID, T2.AccountSubTypeID, T2.EBTVIndicator, T2.HOTI, T2.OtherNetSP, T2.CorpNodeNumber, T2.SalesCode
  , T2.TotalMRC, T2.DiscountMRC, T2.IsValid, T2.CreditType, T2.FullyLoaded, T2.TAC, T2.ShipToMaster, T2.FirstUseDate, T2.COBIndicator, T2.ShippedDate
  , T2.SrlznBAN, T2.SrlznMSISDN, T2.SourceHOTI, T2.DealerName, T2.MasterDealerCode, T2.CurrentMonth, T2.ContractHolderID, T2.ContractID, T2.ContractHolderChannel
  , T2.ContractChannel, T2.ChannelType, T2.AgreementType, T2.UDFMarketCode, T2.SamsonMktName, T2.InMarketFlag
from #ActivityDeactReact T2
where BillingSubsystemID = '1'
  and IsAddALine = 'Y'
  and EventType = 'REACT'
  and T2.CurrentMonth = '2013, Month 06'	
  and InMarketFlag = '0'


/*********************************************************************************************************************************************************************/   
--DEL0013	Activity Prepaid Activation - Out-of-Market					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business			
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business			
--			Dealer codes eligible for activation transactions based on sales code hierarchy			
--			Eligible commissionable products for all activation transactions			
--			In market activations for dealers			
						
--		Expected	Transaction is Eligible			
--			Transaction available in the list of eligible Prepaid transactions			
--			Transaction flagget as out-of-market			

select T1.BillingSubsystemID, T1.ServiceUniversalID, T1.EventType, T1.EffectiveCalcDate, T1.SubscriberActivityKey, T1.ProfileID
  , T1.ActDate, T1.DeactDate, T1.ReactDate, T1.CustomerBAN, T1.SubscriberName, T1.CreditClass, T1.PlanCode, T1.PoolingMRC, T1.RecAccess
  , T1.MarketCode, T1.NPANXX, T1.ServiceNumber, T1.SameMonth, T1.SIM, T1.IMEI, T1.DepositAmount, T1.IsAddALine, T1.AddALineCode, T1.LastSuspendDate
  , T1.PortType, T1.ContractTerm, T1.AccountTypeID, T1.AccountSubTypeID, T1.EBTVIndicator, T1.HOTI, T1.OtherNetSP, T1.CorpNodeNumber, T1.SalesCode
  , T1.TotalMRC, T1.DiscountMRC, T1.IsValid, T1.CreditType, T1.FullyLoaded, T1.TAC, T1.ShipToMaster, T1.FirstUseDate, T1.COBIndicator, T1.ShippedDate
  , T1.SrlznBAN, T1.SrlznMSISDN, T1.SourceHOTI, T1.DealerName, T1.MasterDealerCode, T1.CurrentMonth, T1.ContractHolderID, T1.ContractID, T1.ContractHolderChannel
  , T1.ContractChannel, T1.ChannelType, T1.AgreementType, T1.UDFMarketCode, T1.SamsonMktName, T1.InMarketFlag
from #ActivityActivation T1
where BillingSubsystemID  in ('2','5')
  and IsAddALine = 'N'
  and T1.CurrentMonth = '2013, Month 06'
  and InMarketFlag = '0'
union 
select T2.BillingSubsystemID, T2.ServiceUniversalID, T2.EventType, T2.EffectiveCalcDate, T2.SubscriberActivityKey, T2.ProfileID
  , T2.ActDate, T2.DeactDate, T2.ReactDate, T2.CustomerBAN, T2.SubscriberName, T2.CreditClass, T2.PlanCode, T2.PoolingMRC, T2.RecAccess
  , T2.MarketCode, T2.NPANXX, T2.ServiceNumber, T2.SameMonth, T2.SIM, T2.IMEI, T2.DepositAmount, T2.IsAddALine, T2.AddALineCode, T2.LastSuspendDate
  , T2.PortType, T2.ContractTerm, T2.AccountTypeID, T2.AccountSubTypeID, T2.EBTVIndicator, T2.HOTI, T2.OtherNetSP, T2.CorpNodeNumber, T2.SalesCode
  , T2.TotalMRC, T2.DiscountMRC, T2.IsValid, T2.CreditType, T2.FullyLoaded, T2.TAC, T2.ShipToMaster, T2.FirstUseDate, T2.COBIndicator, T2.ShippedDate
  , T2.SrlznBAN, T2.SrlznMSISDN, T2.SourceHOTI, T2.DealerName, T2.MasterDealerCode, T2.CurrentMonth, T2.ContractHolderID, T2.ContractID, T2.ContractHolderChannel
  , T2.ContractChannel, T2.ChannelType, T2.AgreementType, T2.UDFMarketCode, T2.SamsonMktName, T2.InMarketFlag
from #ActivityDeactReact T2
where BillingSubsystemID in ('2','5')
  and IsAddALine = 'N'
  and EventType = 'REACT'
  and T2.CurrentMonth = '2013, Month 06'
  and InMarketFlag = '0'
  
  
/*********************************************************************************************************************************************************************/   
--DEL0014	Activity PostPaid Deactivation - Global Setup					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business			
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business			
--			Deactivations match with paid historical activations based on archICSPaidActivations table			
--			Eligible dealer codes for deact transactions based on sales code hierarchy			
--			Eligible commissionable products for all deactivation transactions			
--			The date difference between the LastSuspenddate and the act date of the transaction is within the specified timeframe of the ChargeBackdays parameter in  “cfgICSContractProductLeve			
--			The date difference between the deact date and act date is within the timeframe defined in the “ChargeBackDays” parameter in the “cfgICSContractProductLevel” table for the deact transactions			
--			Tag out of market\in market deactivations for dealers and filter out of market deacts			
--			Compensation levelGroup based on Global setup for chargebacks from the “cfgICSContractParms” table.			
						
--		Expected	Transaction is Eligible			
--			Transaction available in thelist of eligible postpaid deactivation transactions			

select * 
from #ActivityDeactReact T2
where 1=1
	--and BillingSubsystemID = '1'
    and EventType = 'DEACT'
    and IsAddALine = 'N'
    and CRHighLevelChannel = 'ALL'
    and CRAgreementType = 'ALL'
    and CRMasterDealerCode = 'ALL'
    and CRContractID = 'ALL'



/******************************************************************************
*                                                                             *
*                  Negative Scenarios Test Result                             *
*                                                                             *
******************************************************************************/

--DEL0050N	Activity Transactions  have been manually excluded by the business in the table “tsdICSManualExclude”
--ICS Activation Eligibility TRAP UNION: RuleName = 'Manual Exclusion'

select distinct T.* 
from dbo.tsdICSActivity T
		inner join tsdICSManualExclude E on T.ServiceUniversalID = E.ServiceUniversalID
			and T.EventType = E.EventType
			and T.EffectiveCalcDate = E.EffectiveCalcDate	
where T.IsValid = '1.00'	
			


--DEL0051N	Activity Transactions correspond to an excluded AccountTypes based on data in the table “cfgICSAccountTypeExclude”					
--ICS Activation Eligibility TRAP UNION: RuleName = 'Account Type Exclusion'

select distinct T.*
from dbo.tsdICSActivity T
	inner join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubTypeID and A.AccountType = T.AccountTypeID)
where not( EventType in ('ACT','DEACT') and SameMonth = 'Y')
	and T.IsValid = '1.00'


--DEL0052N	Activity Activations - Non-eligible dealer codes for activation transactions based on sales code hierarchy	
--ICS Activation Eligibility TRAP UNION: RuleName = 'Valid Sales Code'				

select distinct T.BillingSubsystemID,T.ServiceUniversalID,T.EventType,T.EffectiveCalcDate,T.SubscriberActivityKey 
from dbo.tsdICSActivity T
	left join tsdICSManualExclude E on T.ServiceUniversalID = E.ServiceUniversalID
		and T.EventType = E.EventType
		and T.EffectiveCalcDate = E.EffectiveCalcDate
	left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubTypeID and A.AccountType = T.AccountTypeID)
	left join #DealerMonthlyEligibility D on D.SalesCode = T.SalesCode
		and CAST(T.EffectiveCalcDate as date) between D.MonthStartDate and D.MonthEndDate 
where E.ServiceUniversalID is null
	and ((T.EventType = 'ACT' and isnull(T.SameMonth,'N/A') <> 'Y') or (T.EventType = 'REACT' and T.SameMonth = 'Y'))         -----Same Month logic for Act maybe not in the Varicent yet
	and A.StartDate is null
	and D.SalesCode is null
	and T.IsValid = '1.00'
union
select distinct X.BillingSubsystemID,X.ServiceUniversalID,X.EventType,X.EffectiveCalcDate,X.SubscriberActivityKey
from (
	-----Non Same Month Reactivation-----
	select T.*, Act.SalesCode as SubscriberSalesCode,Act.EffectiveCalcDate as SubscriberActDate,Deact.EffectiveCalcDate as  SubscriberDeactDate
	from tsdICSActivity T
		left join tsdICSManualExclude E on T.ServiceUniversalID = E.ServiceUniversalID
			and T.EventType = E.EventType
			and T.EffectiveCalcDate = E.EffectiveCalcDate
		left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubTypeID and A.AccountType = T.AccountTypeID)
		inner join #EligibleTxnForReactDeact Act on T.ServiceUniversalID = Act.ServiceUniversalID 
			and Act.BillingSubSystemID = T.BillingSubsystemID
			and Act.EventType = 'ACT' 
		inner join #EligibleTxnForReactDeact Deact on T.ServiceUniversalID = Deact.ServiceUniversalID 
			and Deact.BillingSubSystemID = T.BillingSubsystemID
			and Deact.EventType = 'DEACT' 
	where E.ServiceUniversalID is null
		and T.EventType = 'REACT' and isnull(SameMonth,'N/A') <> 'Y'
		and A.StartDate is null
	-----Deactivation-----
	union
	select T.*, Act.SalesCode as SubscriberSalesCode, Act.EffectiveCalcDate as SubscriberActDate,'' as SubscriberDeactDate
	from tsdICSActivity T
		left join tsdICSManualExclude E on T.ServiceUniversalID = E.ServiceUniversalID
			and T.EventType = E.EventType
			and T.EffectiveCalcDate = E.EffectiveCalcDate
		left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubTypeID and A.AccountType = T.AccountTypeID)
		inner join #EligibleTxnForReactDeact Act on T.ServiceUniversalID = Act.ServiceUniversalID 
			and Act.BillingSubSystemID = T.BillingSubsystemID
			and Act.EventType = 'ACT' and cast(T.EffectiveCalcDate as date)>= cast(Act.EffectiveCalcDate as date)
	where E.ServiceUniversalID is null
		and T.EventType = 'DEACT' and isnull(SameMonth,'N/A') <> 'Y'
		and A.StartDate is null
		--and T.ServiceUniversalID = '2305497747'
		) X
	left join #DealerMonthlyEligibility D on D.SalesCode = X.SubscriberSalesCode
		and CAST(X.SubscriberActDate as date) between D.MonthStartDate and D.MonthEndDate 
where X.IsValid = '1.00'
	and D.SalesCode is null
	

--DEL0053N	Activity Activations - Non-eligible commissionable products for all activation transactions					
--ICS Activation Eligibility TRAP UNION: RuleName = 'Commissionable Product'	

select distinct  T.*
--select SubscriberActivityKey, COUNT(*)
from dbo.tsdICSActivity T
	left join tsdICSManualExclude E on T.ServiceUniversalID = E.ServiceUniversalID
		and T.EventType = E.EventType
		and T.EffectiveCalcDate = E.EffectiveCalcDate
	left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubTypeID and A.AccountType = T.AccountTypeID)
	inner join #DealerMonthlyEligibility D on D.SalesCode = T.SalesCode
		and CAST(T.EffectiveCalcDate as date) between D.MonthStartDate and D.MonthEndDate 
	left join #ProductEligibility P on T.PlanCode = P.ProductIDCode
		and T.BillingSubsystemID = P.BillingSubsystemID
		and CAST(T.EffectiveCalcDate as date) between P.StartDate and P.EndDate
where E.ServiceUniversalID is null
	and ((T.EventType = 'ACT' and isnull(T.SameMonth,'N/A') <> 'Y') or (T.EventType = 'REACT' and T.SameMonth = 'Y'))         -----Same Month logic for Act maybe not in the Varicent yet
	and A.StartDate is null
	and T.IsValid = '1.00'
	and P.ProductIDCode is null
	
--DEL0054N	Activity Deactivations does not match with paid historical activations based on archICSPaidActivations table					
--ICS Activation Eligibility TRAP UNION: RuleName = 'Matching DEACT REACT'	

select distinct T.*
from tsdICSActivity T
	left join tsdICSManualExclude E on T.ServiceUniversalID = E.ServiceUniversalID
		and T.EventType = E.EventType
		and T.EffectiveCalcDate = E.EffectiveCalcDate
	left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubTypeID and A.AccountType = T.AccountTypeID)
	left join #EligibleTxnForReactDeact Act on T.ServiceUniversalID = Act.ServiceUniversalID 
		and Act.BillingSubSystemID = T.BillingSubsystemID
		and Act.EventType = 'ACT' and cast(T.EffectiveCalcDate as date)>= cast(Act.EffectiveCalcDate as date)
where E.ServiceUniversalID is null
	and T.EventType = 'DEACT' and isnull(SameMonth,'N/A') <> 'Y'
	and A.StartDate is null
	and ACt.ServiceUniversalID is null
	and T.IsValid = '1.00'
	--and cast(T.EffectiveCalcDate as date) = '2013-01-12'
	

--DEL0055N	Activity Deactivations - Non-eligible dealer codes for deact transactions based on sales code hierarchy					
--Same as DEL0052N, EventType = 'DEACT'


--DEL0056N	Activity Deactivations - Non-eligible commissionable products for all deactivation transactions	
--This Logic is not in Varicent				

select X.* 
from (
	select T.*, Act.SalesCode as SubscriberSalesCode, Act.EffectiveCalcDate as SubscriberActDate,'' as SubscriberDeactDate
	from tsdICSActivity T
		left join tsdICSManualExclude E on T.ServiceUniversalID = E.ServiceUniversalID
			and T.EventType = E.EventType
			and T.EffectiveCalcDate = E.EffectiveCalcDate
		left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubTypeID and A.AccountType = T.AccountTypeID)
		inner join #EligibleTxnForReactDeact Act on T.ServiceUniversalID = Act.ServiceUniversalID 
			and Act.BillingSubSystemID = T.BillingSubsystemID
			and Act.EventType = 'ACT' and cast(T.EffectiveCalcDate as date)>= cast(Act.EffectiveCalcDate as date)
	where E.ServiceUniversalID is null
		and T.EventType = 'DEACT' and isnull(SameMonth,'N/A') <> 'Y'
		and A.StartDate is null
		--and T.ServiceUniversalID = '2305497747'
		) X
	inner join #DealerMonthlyEligibility D on D.SalesCode = X.SubscriberSalesCode
		and CAST(X.SubscriberActDate as date) between D.MonthStartDate and D.MonthEndDate 
	left join #ProductEligibility P on X.PlanCode = P.ProductIDCode
		and X.BillingSubsystemID = P.BillingSubsystemID
		and CAST(X.SubscriberActDate as date) between P.StartDate and P.EndDate
where P.ProductIDCode is null

--DEL0057N	Activity Deactivations - The date difference between the LastSuspenddate and the act date of the transaction is outside the specified timeframe of the ChargeBackdays parameter in  “cfgICSContractProductLeve					

select * 
from (
	select T.*,P.Level,P.LevelNumber,P.LongName,C.Event,C.LevelGroup,C.ChargeBackDays,C.ReactDays
		,ROW_NUMBER() Over(Partition by T.ServiceUniversalID, T.EventType, T.EffectiveCalcDate order by P.LevelNumber desc) as SocLevel 
	from #EligibleReactDeactWT2 T
		inner join cfgICSProductCategory P on T.PlanCode = P.ProductIDCode
		inner join cfgICSContractProductLevels C on P.Level = C.Level
			and T.CRLevel = C.LevelGroup
	where P.Level in (
		'POSTPAID FEATURE',	
		'PREPAID CATEGORIES',	
		'PREPAID FEATURE',	
		'POSTPAID CATEGORIES',
		'POSTPAID CATEGORIES',
		'POSTPAID CATEGORIES'
		)
		and ((P.Level = 'PREPAID CATEGORIES' and C.Event = 'FEATURE')
			or (P.Level = 'POSTPAID CATEGORIES' and T.IsAddALine = 'N' and C.Event = 'ACTIVITY')
			or (P.Level = 'POSTPAID CATEGORIES' and T.IsAddALine = 'Y' and C.Event = 'AAL')) 
		-----ChargeBack&React Window check-----
		and (EventType = 'DEACT' and datediff(dd, T.ActDate, T.LastSuspendDate) > ChargeBackDays)
		) X
where X.SocLevel = 1

--DEL0058N	Activity Deactivations - The date difference between the deact date and act date is outside the timeframe defined in the “ChargeBackDays” parameter in the “cfgICSContractProductLevel” table for the deact transactions					

select * 
from (
	select T.*,P.Level,P.LevelNumber,P.LongName,C.Event,C.LevelGroup,C.ChargeBackDays,C.ReactDays
		,ROW_NUMBER() Over(Partition by T.ServiceUniversalID, T.EventType, T.EffectiveCalcDate order by P.LevelNumber desc) as SocLevel 
	from #EligibleReactDeactWT2 T
		inner join cfgICSProductCategory P on T.PlanCode = P.ProductIDCode
		inner join cfgICSContractProductLevels C on P.Level = C.Level
			and T.CRLevel = C.LevelGroup
	where P.Level in (
		'POSTPAID FEATURE',	
		'PREPAID CATEGORIES',	
		'PREPAID FEATURE',	
		'POSTPAID CATEGORIES',
		'POSTPAID CATEGORIES',
		'POSTPAID CATEGORIES'
		)
		and ((P.Level = 'PREPAID CATEGORIES' and C.Event = 'FEATURE')
			or (P.Level = 'POSTPAID CATEGORIES' and T.IsAddALine = 'N' and C.Event = 'ACTIVITY')
			or (P.Level = 'POSTPAID CATEGORIES' and T.IsAddALine = 'Y' and C.Event = 'AAL')) 
		-----ChargeBack&React Window check-----
		and (EventType = 'DEACT' and datediff(dd, T.ActDate, T.EffectiveCalcDate) > ChargeBackDays)
		) X
where X.SocLevel = 1


--DEL0059N	Activity Deactivations - Out of market deactivations for dealers

select * 
from #ActivityDeactReact		
where EventType = 'DEACT'
	and InMarketFlag = '0'			


--DEL0060N	Activity Reactivations does not match with paid historical deactivations based on archICSPaidActivations table					

select T.*, Act.SalesCode as SubscriberSalesCode,Act.EffectiveCalcDate as SubscriberActDate,Deact.EffectiveCalcDate as  SubscriberDeactDate
from tsdICSActivity T
	left join tsdICSManualExclude E on T.ServiceUniversalID = E.ServiceUniversalID
		and T.EventType = E.EventType
		and T.EffectiveCalcDate = E.EffectiveCalcDate
	left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubTypeID and A.AccountType = T.AccountTypeID)
	left join #EligibleTxnForReactDeact Act on T.ServiceUniversalID = Act.ServiceUniversalID 
		and Act.BillingSubSystemID = T.BillingSubsystemID
		and Act.EventType = 'ACT' 
	left join #EligibleTxnForReactDeact Deact on T.ServiceUniversalID = Deact.ServiceUniversalID 
		and Deact.BillingSubSystemID = T.BillingSubsystemID
		and Deact.EventType = 'DEACT' 
where T.IsValid = '1.00'
	and E.ServiceUniversalID is null
	and T.EventType = 'REACT' and isnull(SameMonth,'N/A') <> 'Y'
	and A.StartDate is null
	and (Act.ServiceUniversalID is null or Deact.ServiceUniversalID is null)
	--and Deact.ServiceUniversalID is null
	and cast(T.EffectiveCalcDate as date) between '2013-06-01' and '2013-07-31'
	
	
--DEL0061N	Activity Reactivations - Non-eligible dealer codes for react transactions based on sales code hierarchy					
----Same as DEL0052N, EventType = 'REACT'


--DEL0062N	Activity Reactivations - The date difference between the react date and the deact date of the transaction is outside the specified timeframe of the reactdays parameter in  “cfgICSContractProductLeve					

select * 
from (
	select T.*,P.Level,P.LevelNumber,P.LongName,C.Event,C.LevelGroup,C.ChargeBackDays,C.ReactDays
		,ROW_NUMBER() Over(Partition by T.ServiceUniversalID, T.EventType, T.EffectiveCalcDate order by P.LevelNumber desc) as SocLevel 
	from #EligibleReactDeactWT2 T
		inner join cfgICSProductCategory P on T.PlanCode = P.ProductIDCode
		inner join cfgICSContractProductLevels C on P.Level = C.Level
			and T.CRLevel = C.LevelGroup
	where P.Level in (
		'POSTPAID FEATURE',	
		'PREPAID CATEGORIES',	
		'PREPAID FEATURE',	
		'POSTPAID CATEGORIES',
		'POSTPAID CATEGORIES',
		'POSTPAID CATEGORIES'
		)
		and ((P.Level = 'PREPAID CATEGORIES' and C.Event = 'FEATURE')
			or (P.Level = 'POSTPAID CATEGORIES' and T.IsAddALine = 'N' and C.Event = 'ACTIVITY')
			or (P.Level = 'POSTPAID CATEGORIES' and T.IsAddALine = 'Y' and C.Event = 'AAL')) 
		-----ChargeBack&React Window check-----
		and (EventType = 'REACT' and datediff(dd, T.DeactDate, T.EffectiveCalcDate) > ReactDays)
		) X
where X.SocLevel = 1