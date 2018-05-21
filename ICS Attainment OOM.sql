/*************************************************************
*                  Out of Market TXNs                        *
*           #OOMTXNs has all eligible records                *
*      #OOMTXNCAP has CAPFlag to identity CAP condition      *
*         CAPFlag = 1 within CAP, = 0 exceeding CAP          *
**************************************************************/

IF OBJECT_ID('tempdb..#OOMTXNs') is not Null
drop table #OOMTXNs

select *
into #OOMTXNs
from (
	select C.BillingSubsystemID, C.ServiceUniversalID, C.FeatureSOC as PlanCode, C.EventType, C.DateString as EffectiveCalcDate
		,C.HighLevelChannel,C.AgreementType,C.MasterDealerCode,C.MarketCode,C.ContractID,C.SubDealerID, C.SalesCode, C.Event, T.SameMonth, C.Months,C.Value 
	from ICSFeaturePPDEligibility1310 C
		inner join tsdICSFeatureActivation T on C.ServiceUniversalID = T.ServiceUniversalID
			and C.BillingSubsystemID = T.BillingSubsystemID
			and C.FeatureSOC = T.FeatureSOC
			and C.EventType = T.EventType
			and cast(C.DateString as date) = cast(T.EffectiveCalcDate as date)
	--where C.ServiceUniversalID = '2307086133'
	Union All
	select C.BillingSubsystemID, C.ServiceUniversalID, C.FeatureSOC as PlanCode, C.EventType, C.DateString as EffectiveCalcDate
		,C.HighLevelChannel,C.AgreementType,C.MasterDealerCode,C.MarketCode,C.ContractID,C.SubDealerID, C.SalesCode, C.Event, T.SameMonth, C.Months,C.Value 
	from ICSFeatureEligibility1300 C
		inner join tsdICSFeatureActivation T on C.ServiceUniversalID = T.ServiceUniversalID
			and C.FeatureSOC = T.FeatureSOC
			and C.BillingSubsystemID = T.BillingSubsystemID
			and C.EventType = T.EventType
			and cast(C.DateString as date) = cast(T.EffectiveCalcDate as date)
	Union All		
	select U.BillingSubSystemID, U.OrderDetailID as ServiceUniversalID,U.PlanCode, U.EventType,U.DateString as EffectiveCalcDate
		,U.HighLevelChannel,  U.AgreementType,U.MasterDealerCode, U.MarketCode, U.ContractID, U.SubDealerID, U.SalesCode, U.Event, T.SameMonth, U.Months, U.Value
	from ICSUpgradesEligibilityUE2020 U
		inner join tsdICSUpgrades T on T.OrderDetailID = U.OrderDetailID
			and T.BillingSubSystemID = U.BillingSubSystemID
			and T.EventType = U.EventType
	Union All		
	select A.BillingSubsystemID, A.ServiceUniversalID, A.PlanCode, A.EventType, A.DateString as EffectiveCalcDate
		,A.HighLevelChannel, A.AgreementType,A.MasterDealerCode,  A.MarketCode, A.ContractID, A.SubDealerID, A.SalesCode, A.Event, T.SameMonth, A.Months, A.Value
	from ICSActivationAE2050 A
		inner join tsdICSActivity T on A.ServiceUniversalID = T.ServiceUniversalID
			and A.BillingSubsystemID = T.BillingSubsystemID
			and A.EventType = T.EventType
			and CAST(A.DateString as date) = CAST(T.EffectiveCalcDate as date)
	) X
where 1=1
	--and X.Value = '0.00'
	--and (X.SameMonth = 'Y' and X.EventType = 'REACT' or ISNull(X.SameMonth,'') <> 'Y' and X.EventType = 'ACT') 
--select * from #OOMTXNs

------ Apply OOM Cap Logic ------

IF OBJECT_ID('tempdb..#OOMTXNsWT1') is not Null
drop table #OOMTXNsWT1

select OM.*
	,P.HighLevelChannel as OMHighLevelChannel,P.AgreementType as OMAgreementType,P.MasterDealerCode as OMMasterDealerCode,P.ContractID as OMContractID,P.ValueNumeric as [CAP%]
into #OOMTXNsWT1
from #OOMTXNs OM
	left join cfgICSContractParams P on P.Name = 'OOMCAP'
		and P.HighLevelChannel = 'ALL' and P.AgreementType = 'ALL' and P.MasterDealerCode = 'ALL' and P.ContractID = 'ALL'
		and cast(OM.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
where OM.Value = '0.00'
	and (OM.SameMonth = 'Y' and OM.EventType = 'REACT' or ISNull(OM.SameMonth,'') <> 'Y' and OM.EventType = 'ACT') 
		
update OM 
set OM.[CAP%] = P.ValueNumeric, OM.OMHighLevelChannel = P.HighLevelChannel
from #OOMTXNsWT1 OM
	inner join cfgICSContractParams P on P.Name = 'OOMCAP'
		and OM.HighLevelChannel = P.HighLevelChannel
		and P.AgreementType = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
		and cast(OM.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)

update OM 
set OM.[CAP%] = P.ValueNumeric, OM.OMHighLevelChannel = P.HighLevelChannel,OM.OMAgreementType = P.AgreementType
from #OOMTXNsWT1 OM
	inner join cfgICSContractParams P on P.Name = 'OOMCAP'
		and OM.HighLevelChannel = P.HighLevelChannel
		and P.AgreementType = OM.AgreementType
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
		and cast(OM.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		
update OM 
set OM.[CAP%] = P.ValueNumeric, OM.OMHighLevelChannel = P.HighLevelChannel,OM.OMAgreementType = P.AgreementType, OM.OMMasterDealerCode = P.MasterDealerCode
from #OOMTXNsWT1 OM
	inner join cfgICSContractParams P on P.Name = 'OOMCAP'
		and OM.HighLevelChannel = P.HighLevelChannel
		and P.AgreementType = OM.AgreementType
		and P.MasterDealerCode = OM.MasterDealerCode
		and P.ContractID = 'ALL'
		and cast(OM.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		
update OM 
set OM.[CAP%] = P.ValueNumeric, OM.OMHighLevelChannel = P.HighLevelChannel,OM.OMAgreementType = P.AgreementType, OM.OMMasterDealerCode = P.MasterDealerCode, OM.OMContractID = P.ContractID
from #OOMTXNsWT1 OM
	inner join cfgICSContractParams P on P.Name = 'OOMCAP'
		and OM.HighLevelChannel = P.HighLevelChannel
		and P.AgreementType = OM.AgreementType
		and P.MasterDealerCode = OM.MasterDealerCode
		and P.ContractID = OM.ContractID 
		and cast(OM.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		
delete from #OOMTXNsWT1
where ISNULL(OMHighLevelChannel,'') = ''
	and ISNULL(OMAgreementType,'') = ''
	and ISNULL(OMMasterDealerCode,'') = ''
	and ISNULL(OMContractID,'') = ''

		
--select * from #OOMTXNsWT1 where OMContractID <> 'ALL'

------ Get total Amount per and CAP Amount, RANK the TXNs
IF OBJECT_ID('tempdb..#OOMTXNsWT2') is not Null
drop table #OOMTXNsWT2
IF OBJECT_ID('tempdb..#OOMTXNsWT3') is not Null
drop table #OOMTXNsWT3
IF OBJECT_ID('tempdb..#OOMTXNsWT4') is not Null
drop table #OOMTXNsWT4
IF OBJECT_ID('tempdb..#OOMTXNCAP') is not Null
drop table #OOMTXNCAP

select HighLevelChannel,AgreementType, MasterDealerCode, ContractID, Event, Months, COUNT(*) as TXNAmt
into #OOMTXNsWT2
from #OOMTXNs T
	inner join cfgICSProductCategory P on T.PlanCode = P.ProductIDCode
		and P.Level = 'POSTPAID CATEGORIES'			------ The condition here based on cfgICSOOMGroup and cfgICSProductLevelGroup tables
		and cast(T.EffectiveCalcDate as  date) between cast(P.StartDate as date) and cast(P.EndDate as date)
where EventType = 'ACT'
group by HighLevelChannel,AgreementType, MasterDealerCode, ContractID, Event, Months

select T.*, Amt.TXNAmt
	, ROW_NUMBER() Over(partition by T.HighLevelChannel,T.AgreementType, T.MasterDealerCode, T.ContractID, T.Event, T.Months order by cast(T.EffectiveCalcDate as date)) as RANK
	,round(Amt.TXNAmt*T.[CAP%]/100,0) as CAPAmt
into #OOMTXNsWT3
from #OOMTXNsWT1 T
	inner join #OOMTXNsWT2 Amt on Amt.HighLevelChannel = T.HighLevelChannel
		and Amt.AgreementType = T.AgreementType
		and Amt.MasterDealerCode = T.MasterDealerCode
		and Amt.ContractID = T.ContractID
		and Amt.Event = T.Event
		and Amt.Months = T.Months

select *
	,case when RANK <= CAPAmt then 1.00 else 0.00 end as CAPFlag
into #OOMTXNsWT4
from #OOMTXNsWT3

select * 
into #OOMTXNCAP
from (
	select BillingSubsystemID, ServiceUniversalID, PlanCode, EventType, Event, EffectiveCalcDate,HighLevelChannel,AgreementType, MasterDealerCode,
		MarketCode,ContractID,SubDealerID,SalesCode,SameMonth, Months, 'N/A' as OMHighLevelChannel, 'N/A' as OMAgreementType,
		'N/A' as OMMasterDealerCode,'N/A' as OMContractID, Value as InMarketFlag,1.00 as CAPFLag 
	from #OOMTXNs OM1
	where OM1.Value = '1.00'
		OR OM1.EventType = 'DEACT'
		OR (OM1.EventType = 'REACT' and ISNULL(SameMonth,'')<>'Y')
	UNION ALL	
	select BillingSubsystemID, ServiceUniversalID, PlanCode, EventType, Event, EffectiveCalcDate,HighLevelChannel,AgreementType, MasterDealerCode,
		MarketCode,ContractID,SubDealerID,SalesCode,SameMonth, Months, OMHighLevelChannel, OMAgreementType,
		OMMasterDealerCode,OMContractID, Value as InMarketFlag,CAPFLag  
	from #OOMTXNsWT4
	) X

--select * from #OOMTXNCAP where ServiceUniversalID in ('2305710252', '2306777034')


/******************************************************************************
*                                                                             *
*                  Positive Scenarios Test Result                             *
*                                                                             *
******************************************************************************/

--DAT0000	OutOfMarket Postpaid Activation - Global OOM Cap				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on “Global OOM cap” 		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List Out of Market PostPaid Activations, Deactivations and Reactivations		
--		Calc	'ICS OOM 1160'	

select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and OMHighLevelChannel = 'ALL'
	and OMAgreementType = 'ALL'
	and OMMasterDealerCode = 'ALL'
	and OMContractID = 'ALL'
	

--DAT0001	OutOfMarket Postpaid Activation - HighLevelChannel				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “HighLevelChannel setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List Out of Market PostPaid Activations, Deactivations and Reactivations		
--		Calc	'ICS OOM 1160'	

select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and EventType = 'ACT'
	and Event = 'ACTIVITY'
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType = 'ALL'
	and OMMasterDealerCode = 'ALL'
	and OMContractID = 'ALL'
	

--DAT0002	OutOfMarket Postpaid Activation - AgreementType				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on “AgreementType setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List Out of Market PostPaid Activations, Deactivations and Reactivations		
--		Calc	'ICS OOM 1160'	

select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and EventType = 'ACT'
	and Event = 'ACTIVITY'
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType <> 'ALL'
	and OMMasterDealerCode = 'ALL'
	and OMContractID = 'ALL'
	

--DAT0003	OutOfMarket Postpaid Activation - Masterdealercode				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Masterdealercode setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List Out of Market PostPaid Activations, Deactivations and Reactivations		
--		Calc	'ICS OOM 1160'	

select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and EventType = 'ACT'
	and Event = 'ACTIVITY'
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType <> 'ALL'
	and OMMasterDealerCode <> 'ALL'
	and OMContractID = 'ALL'
	
	
--DAT0004	OutOfMarket Postpaid Activation - Contract 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Contract Level setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List Out of Market PostPaid Activations, Deactivations and Reactivations		
--		Calc	'ICS OOM 1160'	
					
select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and EventType = 'ACT'
	and Event = 'ACTIVITY'
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType <> 'ALL'
	and OMMasterDealerCode <> 'ALL'
	and OMContractID <> 'ALL'
	
--DAT0005	OutOfMarket Postpaid Deactivation - Contract 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Contract Level setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List Out of Market PostPaid Activations, Deactivations and Reactivations		

/*--------For Deactivation, Varicent consider all of them as eligible ------*/



--DAT0006	OutOfMarket Postpaid Reactivation - Contract 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Contract Level setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List Out of Market PostPaid Activations, Deactivations and Reactivations		
--		Calc	'ICS OOM 1160'	

select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and EventType = 'REACT'
	and Event = 'ACTIVITY'
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType <> 'ALL'
	and OMMasterDealerCode <> 'ALL'
	and OMContractID <> 'ALL'
	
	
--DAT0007	OutOfMarket AddALine Activation - Contract 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Contract Level setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List of all AAL Out of Market transactions	
--		Calc	'ICS OOM 1160'		

select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and EventType = 'ACT'
	and Event = 'AAL'
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType <> 'ALL'
	and OMMasterDealerCode <> 'ALL'
	and OMContractID <> 'ALL'
	
	
--DAT0008	OutOfMarket AddALine Deactivation - Contract 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Contract Level setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List of all AAL Out of Market transactions		
--		Calc	'ICS OOM 1160'	

select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and EventType = 'DEACT'
	and Event = 'AAL'
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType <> 'ALL'
	and OMMasterDealerCode <> 'ALL'
	and OMContractID <> 'ALL'
	
--DAT0009	OutOfMarket AddALine Reactivation - Contract 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Contract Level setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List of all AAL Out of Market transactions	
--		Calc	'ICS OOM 1160'		

select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and EventType = 'REACT'
	and Event = 'AAL'
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType <> 'ALL'
	and OMMasterDealerCode <> 'ALL'
	and OMContractID <> 'ALL'
	
--DAT0010	OutOfMarket Prepaid Activation - Contract 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Contract Level setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List of PPD Out of Market transactions	
--		Calc	'ICS OOM 1160'		

select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and EventType = 'ACT'
	and Event in ('PREPAID')    -------Base on currently setup, we will filter out all prepaid OOM transactions, need to change code and config if we need to test this scenario
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType <> 'ALL'
	and OMMasterDealerCode <> 'ALL'
	and OMContractID <> 'ALL'


--DAT0011	OutOfMarket Prepaid Deactivation - Contract 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Contract Level setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List of PPD Out of Market transactions		
--		Calc	'ICS OOM 1160'	

select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and EventType = 'DEACT'
	and Event in ('PREPAID')    -------Base on currently setup, we will filter out all prepaid OOM transactions, need to change code and config if we need to test this scenario
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType <> 'ALL'
	and OMMasterDealerCode <> 'ALL'
	and OMContractID <> 'ALL'
	
	
--DAT0012	OutOfMarket Upgrade - Contract 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Contract Level setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List of all Out of Market Upgrade  transactions		
--		Calc	'ICS OOM 1160'	

select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and EventType = 'ACT'
	and Event = 'UPGRADE'
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType <> 'ALL'
	and OMMasterDealerCode <> 'ALL'
	and OMContractID <> 'ALL'


--DAT0013	OutOfMarket Upgrade Reset - Contract 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Contract Level setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List of all Out of Market Upgrade  transactions		
--		Calc	'ICS OOM 1160'

select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and EventType = 'REACT'
	and Event = 'UPGRADE'
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType <> 'ALL'
	and OMMasterDealerCode <> 'ALL'
	and OMContractID <> 'ALL'
	
--DAT0014	OutOfMarket PostPaid Feature Activation - Contract 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Contract Level setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List of Out of Market feature activation transactions
--		Calc	'ICS OOM 1160'	


select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and EventType = 'ACT'
	and Event = 'FEATURE'
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType <> 'ALL'
	and OMMasterDealerCode <> 'ALL'
	and OMContractID <> 'ALL'
	
--DAT0015	OutOfMarket PostPaid Feature Deactivation - Contract 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Contract Level setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List of Out of Market feature activation transactions		
--		Calc	'ICS OOM 1160'	

/*--------For Deactivation, Varicent consider all of them as eligible ------*/


--DAT0016	OutOfMarket PostPaid Feature Reactivation - Contract 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Contract Level setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List of Out of Market feature activation transactions		
--		Calc	'ICS OOM 1160'	

select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and EventType = 'REACT'
	and Event = 'FEATURE'
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType <> 'ALL'
	and OMMasterDealerCode <> 'ALL'
	and OMContractID <> 'ALL'
	
--DAT0017	OutOfMarket Prepaid Feature Activation - Contract 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Contract Level setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List of Out of Out of Market PPD feature activation transactions		
--		Calc	'ICS OOM 1160'	

select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and EventType = 'ACT'
	and Event in ('PREPAID FEATURE')    -------Base on currently setup, we will filter out all prepaid OOM transactions, need to change code and config if we need to test this scenario
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType <> 'ALL'
	and OMMasterDealerCode <> 'ALL'
	and OMContractID <> 'ALL'
	

--DAT0018	OutOfMarket Prepaid Feature Deactivation - Contract 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Contract Level setup” from the “cfgICSContractParms” table.		
--			Transaction not exeeding the Cap		
					
--		Expected	Transaction present in List of Out of Out of Market PPD feature activation transactions		
--		Calc	'ICS OOM 1160'	

select * 
from #OOMTXNCAP
where InMarketFlag = '0.00'
	and CAPFLag = '1.00'
	and EventType = 'DEACT'
	and Event in ('PREPAID FEATURE')    -------Base on currently setup, we will filter out all prepaid OOM transactions, need to change code and config if we need to test this scenario
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType <> 'ALL'
	and OMMasterDealerCode <> 'ALL'
	and OMContractID <> 'ALL'
	
	
/******************************************************************************
*                                                                             *
*                  Negative Scenarios Test Result                             *
*                                                                             *
******************************************************************************/

--DAT0051N	OutOfMarket PostPaid Activation - InMarket 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			In Market activations for dealers		
					
--		Expected	Transaction NOT present in List Out of Market PostPaid Activations, Deactivations and Reactivations		
--		Calc	'ICS OOM 1160'	

select * 
from #OOMTXNCAP
where InMarketFlag = '1.00'


--DAT0052N	OutOfMarket Postpaid Activation - Exeeding the Cap 				
--		Preconditions			
--			Transaction is eligible		
--				Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business	
--				AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business	
--				Dealer codes eligible for activation transactions based on sales code hierarchy	
--				Eligible commissionable products for all activation transactions	
--			Out of Market activations for dealers		
--			Compensation levelGroup based on  “Contract Level setup” from the “cfgICSContractParms” table.		
--			Transaction exeeding the Cap		
					
--		Expected	Transaction NOT present in List Out of Market Activations and Reactivations		
--		Calc	'ICS OOM 1160'

select *
from #OOMTXNCAP
where CAPFLag = '0.00'
	and OMHighLevelChannel <> 'ALL'
	and OMAgreementType <> 'ALL'
	and OMMasterDealerCode <> 'ALL'
	and OMContractID <> 'ALL' 