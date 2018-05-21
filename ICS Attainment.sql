IF OBJECT_ID('tempdb..#AttmTXNs') is not Null
drop table #AttmTXNs

select HighLevelChannel,AgreementType,MasterDealerCode, ContractID, SubDealerID, SalesCode, PlanCode, Event,EventType, Months, COUNT(*) as Value
into #AttmTXNs
from(
	------ Activation ACT/DEACT/REACT (Include AAL) ------
	select A.BillingSubsystemID, A.ServiceUniversalID, A.PlanCode
		,case when A.EventType = 'REACT' then 'ACT' else A.EventType end as EventType
		,A.DateString as EffectiveCalcDate,A.HighLevelChannel, A.AgreementType,A.MasterDealerCode,  A.MarketCode, A.ContractID, A.SubDealerID, A.SalesCode
		,case when IsAddALine = 'Y' then 'AAL' else 'ACTIVITY' end as Event, T.SameMonth, A.Months,A.Value
	from ICSActivationAE2050 A
		inner join tsdICSActivity T on A.ServiceUniversalID = T.ServiceUniversalID
			and A.BillingSubsystemID = T.BillingSubsystemID
			and A.EventType = T.EventType
			and CAST(A.DateString as date) = CAST(T.EffectiveCalcDate as date)
	where A.EventType in ('ACT', 'DEACT', 'REACT')
		and T.SameMonth = case when A.EventType = 'REACT' then 'Y' else 'N' end 
		and A.BillingSubsystemID = '1'
		and A.Value = '1.00'		----- In Market Only
		--and T.IsAddALine = 'Y'     ----- Need to remove later
	Union ALL
	
	------ Upgrade ACT/DEACT ------
	select U.BillingSubSystemID, U.OrderDetailID as ServiceUniversalID,U.PlanCode, U.EventType,U.DateString as EffectiveCalcDate
		,U.HighLevelChannel,  U.AgreementType,U.MasterDealerCode, U.MarketCode, U.ContractID, U.SubDealerID, U.SalesCode, U.Event, T.SameMonth, U.Months, U.Value
	from ICSUpgradesEligibilityUE2020 U
		inner join tsdICSUpgrades T on T.OrderDetailID = U.OrderDetailID
			and T.BillingSubSystemID = U.BillingSubSystemID
			and T.EventType = U.EventType
	where U.EventType in ('DEACT', 'ACT')
		and T.SameMonth = 'N'
		and U.Value = '1.00'		----- In Market Only
	Union ALL
	
	------ PPD Feature ------
	select C.BillingSubsystemID, C.ServiceUniversalID, C.FeatureSOC as PlanCode, C.EventType, C.DateString as EffectiveCalcDate
		,C.HighLevelChannel,C.AgreementType,C.MasterDealerCode,C.MarketCode,C.ContractID,C.SubDealerID, C.SalesCode, C.Event, T.SameMonth, C.Months,C.Value 
	from ICSFeaturePPDEligibility1310 C
		inner join tsdICSFeatureActivation T on C.ServiceUniversalID = T.ServiceUniversalID
			and C.BillingSubsystemID = T.BillingSubsystemID
			and C.FeatureSOC = T.FeatureSOC
			and C.EventType = T.EventType
			and cast(C.DateString as date) = cast(T.EffectiveCalcDate as date)
	where C.EventType in ('DEACT', 'ACT')
		and T.SameMonth = 'N'
		and C.Value = '1.00'		----- In Market Only
	Union ALL
	
	------ Feature ACT/DEACT ------
	select C.BillingSubsystemID, C.ServiceUniversalID, C.FeatureSOC as PlanCode, C.EventType, C.DateString as EffectiveCalcDate
		,C.HighLevelChannel,C.AgreementType,C.MasterDealerCode,C.MarketCode,C.ContractID,C.SubDealerID, C.SalesCode, C.Event, T.SameMonth, C.Months,C.Value 
	from ICSFeatureEligibility1300 C
		inner join tsdICSFeatureActivation T on C.ServiceUniversalID = T.ServiceUniversalID
			and C.FeatureSOC = T.FeatureSOC
			and C.BillingSubsystemID = T.BillingSubsystemID
			and C.EventType = T.EventType
			and cast(C.DateString as date) = cast(T.EffectiveCalcDate as date)
	where C.EventType in ('ACT','DEACT')
		and T.SameMonth = 'N'
		and C.Value = '1.00'		----- In Market Only
	Union ALL
	
	------ PPD Activity ------
	select A.BillingSubsystemID, A.ServiceUniversalID, A.PlanCode
		,case when A.EventType = 'REACT' then 'ACT' else A.EventType end as EventType		----- Here we didn't flip SameMonth React to Act, why?
		,A.DateString as EffectiveCalcDate,A.HighLevelChannel, A.AgreementType,A.MasterDealerCode,  A.MarketCode, A.ContractID, A.SubDealerID, A.SalesCode
		,A.Event, T.SameMonth, A.Months,A.Value
	from ICSActivationAE2050 A
		inner join tsdICSActivity T on A.ServiceUniversalID = T.ServiceUniversalID
			and A.BillingSubsystemID = T.BillingSubsystemID
			and A.EventType = T.EventType
			and CAST(A.DateString as date) = CAST(T.EffectiveCalcDate as date)
	where A.EventType in ('ACT', 'DEACT', 'REACT')
		and A.BillingSubsystemID in ('2','5')
		and T.SameMonth = case when A.EventType = 'REACT' then 'Y' else 'N' end 
		and A.Value = '1.00'		----- In Market Only
		and T.IsAddALine = 'N'     
	
	) X
group by HighLevelChannel,AgreementType,MasterDealerCode, ContractID, SubDealerID, SalesCode, PlanCode, Event,EventType, Months


--select * from #AttmTXNs

----------------Below shows how to get Attainment Tier---------------------------------

IF OBJECT_ID('tempdb..#Month') is not Null
drop table #Month
IF OBJECT_ID('tempdb..#AttainSetup') is not Null
drop table #AttainSetup

select CurrentMonth,MIN(CAST(Date as date)) as StartDate, MAX(CAST(Date as date)) as EndDate
into #Month  
from cfgDateString
group by CurrentMonth

select distinct C.MasterDealerCode,C.ContractID, C.AttainmentGroup, C.LevelGroup, M.CurrentMonth, M.StartDate as MonthStartDate, M.EndDate as MonthEndDate 
into #AttainSetup
from cfgICSAttainContract C
	inner join #Month M on CAST(C.StartDate as date) <= CAST(M.EndDate as date)
		and CAST(C.EndDate as date) >= CAST(M.EndDate as date) 
		
------------- Join with TXNs to get AttainSetup ---------------

IF OBJECT_ID('tempdb..#AttmTXNSetup') is not Null
drop table #AttmTXNSetup

select T.*, S.MonthStartDate, S.MonthEndDate, S.MasterDealerCode as CSMasterDealerCode, S.ContractID as CSContractID, S.AttainmentGroup, S.LevelGroup 
into #AttmTXNSetup
from #AttmTXNs T 
	left join #AttainSetup S on S.MasterDealerCode = 'ALL'
		and S.ContractID = 'ALL'
		and Substring(T.Months,1,7) = SUBSTRING(CurrentMonth,1,4)+SUBSTRING(CurrentMonth,12,3)
		
update A
set A.CSMasterDealerCode = S.MasterDealerCode
	, A.MonthStartDate = S.MonthStartDate
	, A.MonthEndDate = S.MonthEndDate
	, A.CSContractID = 'ALL'
	, A.AttainmentGroup = S.AttainmentGroup
	, A.LevelGroup = S.LevelGroup
from #AttmTXNSetup A
	inner join #AttainSetup S on A.MasterDealerCode = S.MasterDealerCode
		and S.ContractID = 'ALL'
		and Substring(A.Months,1,7) = SUBSTRING(CurrentMonth,1,4)+SUBSTRING(CurrentMonth,12,3)

update A
set A.CSMasterDealerCode = S.MasterDealerCode
	, A.MonthStartDate = S.MonthStartDate
	, A.MonthEndDate = S.MonthEndDate
	, A.CSContractID = S.ContractID
	, A.AttainmentGroup = S.AttainmentGroup
	, A.LevelGroup = S.LevelGroup
from #AttmTXNSetup A
	inner join #AttainSetup S on A.MasterDealerCode = S.MasterDealerCode
		and S.ContractID = A.ContractID
		and Substring(A.Months,1,7) = SUBSTRING(CurrentMonth,1,4)+SUBSTRING(CurrentMonth,12,3)

delete 
from #AttmTXNSetup
where ISNULL(CSMasterDealerCode,'')='' 
	and ISNULL(CSContractID,'')='' 
	

IF OBJECT_ID('tempdb..#AttmAmount') is not Null
drop table #AttmAmount

select X.*
into #AttmAmount
from 
   (select Distinct T.*    ------ Check whether Product should be include 
	from #AttmTXNSetup T
		inner join cfgICSProductCategory P on T.PlanCode = P.ProductIDCode
			and CAST(T.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		inner join cfgICSProductLevelGroup L on L.LevelGroup = T.LevelGroup
			and L.Level = P.Level
			and CAST(T.MonthEndDate as date) between cast(L.StartDate as date) and cast(L.EndDate as date)
	) X
	inner join cfgICSAttainEventGroups G on X.AttainmentGroup = G.AttainmentGroup   ------ Check whether Event and EventType should be include
		and X.Event = G.Event
		and X.EventType = G.EventType
		and CAST(X.MonthEndDate as date) between cast(G.StartDate as date) and cast(G.EndDate as date)
		
--select * from #AttmAmount		


----------------Get final result ------------------------ 
select *
from (
	select HighLevelChannel,AgreementType,MasterDealerCode,ContractID,LevelGroup,AttainmentGroup,Months,MonthStartDate,MonthEndDate
		,CSMasterDealerCode,CSContractID, SUM(Value) as Amt 
	from #AttmAmount
	group by HighLevelChannel,AgreementType,MasterDealerCode,ContractID,LevelGroup,AttainmentGroup,Months,MonthStartDate,MonthEndDate,CSMasterDealerCode,CSContractID
	) X 
	inner join cfgICSAttainContract C on X.CSMasterDealerCode = C.MasterDealerCode
		and X.CSContractID = C.ContractID
		and cast(X.Amt as float) between cast(C.Min as float) and cast(C.Max as float) 
		and CAST(X.MonthEndDate as date) between cast(C.StartDate as date) and cast(C.EndDate as date)