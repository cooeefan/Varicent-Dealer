IF OBJECT_ID('tempdb..#SpiffAttmTXNs') is not Null
drop table #SpiffAttmTXNs

select HighLevelChannel,AgreementType,MasterDealerCode, ContractID, SubDealerID, SalesCode, PlanCode, Event,EventType, Months, COUNT(*) as Value
into #SpiffAttmTXNs
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

/* Only Upgrade use In Market transactions only */
--select * from #SpiffAttmTXNs where Event = 'UPGRADE' --and EventType = 'ACT'

IF OBJECT_ID('tempdb..#Month') is not Null
drop table #Month

select CurrentMonth,MIN(CAST(Date as date)) as StartDate, MAX(CAST(Date as date)) as EndDate
into #Month  
from cfgDateString
group by CurrentMonth

IF OBJECT_ID('tempdb..#SpiffAttmWT1') is not Null
drop table #SpiffAttmWT1


------ Here we need add Months into Partition by cause, Varicent missed that-----
select T.*, M.CurrentMonth, M.StartDate, M.EndDate, G.ID, G.Level,G.LevelGroup
	, ROW_NUMBER() Over(Partition by T.HighLevelChannel, T.AgreementType, T.MasterDealerCode, T.ContractID, T.SubdealerID, T.SalesCode, T.PlanCode
		, T.Event, T.EventType,G.LevelGroup,Months order by cast(P.LevelNumber as float) desc) as SOCLevel
into #SpiffAttmWT1
from #SpiffAttmTXNs T
	inner join #Month M on Substring(T.Months,1,7) = SUBSTRING(CurrentMonth,1,4)+SUBSTRING(CurrentMonth,12,3)
	inner join cfgICSProductCategory P on T.PlanCode = P.ProductIDCode
		and M.EndDate between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsCommissionable = 'YES'
	inner join cfgICSProductLevelGroup G on P.Level = G.Level
		and M.EndDate between cast(G.StartDate as date) and cast(G.EndDate as date)
		
--select * from #SpiffAttmWT1 
--where SOCLevel =1 and SalesCode = '4548529' and Months = '2013 06 (JUN)' and LevelGroup ='DECAY1' and Event = 'ACTIVITY'

IF OBJECT_ID('tempdb..#SpiffAttmWT2') is not Null
drop table #SpiffAttmWT2

select HighLevelChannel, AgreementType, MasterDealerCode, ContractID, SubdealerID, SalesCode
		, Event, EventType,LevelGroup,Months,StartDate, EndDate, SUM(Value) as Value
into #SpiffAttmWT2
from #SpiffAttmWT1 
where SOCLevel =1 
group by HighLevelChannel, AgreementType, MasterDealerCode, ContractID, SubdealerID, SalesCode
		, Event, EventType,LevelGroup,Months, StartDate, EndDate
--order by Months,HighLevelChannel, AgreementType,ContractID,MasterDealerCode,SubDealerID,SalesCode,Event,EventType, LevelGroup


IF OBJECT_ID('tempdb..#SpiffAttmWT3') is not Null
drop table #SpiffAttmWT3

select A.HighLevelChannel, A.AgreementType, A.MasterDealerCode, A.ContractID, A.SubDealerID, A.SalesCode, G.AttainmentGroup
	, A.LevelGroup, A.Months, A.StartDate, A.EndDate, SUM(cast(A.Value as float)* cast(G.Value as float)) as Value
into #SpiffAttmWT3
from #SpiffAttmWT2 A
	inner join cfgICSAttainEventGroups G on A.Event = G.Event
		and A.EventType = G.EventType
		and A.EndDate between cast(G.StartDate as date) and cast(G.EndDate as date)
group by A.HighLevelChannel, A.AgreementType, A.MasterDealerCode, A.ContractID, A.SubDealerID, A.SalesCode, G.AttainmentGroup
	, A.LevelGroup, A.Months, A.StartDate, A.EndDate


--select HighLevelChannel, AgreementType, MasterDealerCode, AttainmentGroup, LevelGroup,Months,StartDate, EndDate, sum(value) 
--from #SpiffAttmWT3
--group by HighLevelChannel, AgreementType, MasterDealerCode, AttainmentGroup, LevelGroup,Months,StartDate, EndDate
--Order by Months, MasterDealerCode

select  MasterDealerCode, AttainmentGroup, LevelGroup,Months,StartDate, EndDate, sum(value) as Value
from #SpiffAttmWT3
group by MasterDealerCode, AttainmentGroup, LevelGroup,Months,StartDate, EndDate		----- refICSSpiffRollUpLevels, Roll up to master dealer
Order by Months, MasterDealerCode