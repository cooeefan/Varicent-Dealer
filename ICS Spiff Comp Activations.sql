/*************************************************************
*               Spiff Comp for Activations                   *
*          #SpiffCompActivations contains results            *
**************************************************************/


IF OBJECT_ID('tempdb..#SpiffCompActivationsWT1') is not Null
drop table #SpiffCompActivationsWT1

/***********Act and REACT***************/

------- Apply 'All' TAC Group first -------
select T.*, OT.TAC, OT.RecAccess, OT.PlanCode,OT.AddALineCode, OT.PoolingMRC, OT.DiscountMRC, OT.TotalMRC, S.SpiffDescription,S.AssignmentID
	,S.ProductEventGroupID, S.MRCType,D.ID as SpiffDefinitionID
	, case when S.MRCType = 'LINEMRC' then OT.RecAccess
		when S.MRCType = 'PLANMRC' then OT.PoolingMRC
		when S.MRCType = 'REDUCEDMRC' then OT.DiscountMRC
		when S.MRCType = 'TOTALMRC' then OT.TotalMRC
	  else '0' end as CountMRC 
into #SpiffCompActivationsWT1
from ICSAGSpiff1090Activation T
	left join tsdICSActivity OT on T.ServiceUniversalID = OT.ServiceUniversalID
		and T.EventType = OT.EventType
		and T.BillingSubsystemID = OT.BillingSubsystemID
		and cast(T.EffectiveCalcDate as date) = cast(OT.EffectiveCalcDate as date)
	left join cfgICSSpiff S on T.cfgICSSpiffID = S.ID
		and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
		and S.IsActive = 'Y'
	left join cfgICSSpiffDefinition D on S.SpiffID = D.SpiffID
		and cast(T.EffectiveCalcDate as date) between cast(D.StartDate as date) and cast(D.EndDate as date)
		and D.IsActive = 'Y'
		and D.TacGroup = 'ALL'
--order by T.ServiceUniversalID

------- Apply 'Specific' TAC Group  -------
update T
set T.SpiffDefinitionID = D.ID
--select *
from #SpiffCompActivationsWT1 T
	inner join cfgICSSpiff S on T.cfgICSSpiffID = S.ID
		and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
		and S.IsActive = 'Y'
	inner join cfgICSSpiffDefinition D on S.SpiffID = D.SpiffID
		and cast(T.EffectiveCalcDate as date) between cast(D.StartDate as date) and cast(D.EndDate as date)
		and D.IsActive = 'Y'
	inner join cfgICSSpiffTACGroups G on D.TacGroup = G.TACGroupID
		and cast(T.EffectiveCalcDate as date) between cast(G.StartDate as date) and cast(G.EndDate as date)
		and G.IsActive = 'Y'
		and G.TAC = T.TAC
		
------- MRC Logic -------

IF OBJECT_ID('tempdb..#SpiffCompActivationsWT2') is not Null
drop table #SpiffCompActivationsWT2

select T.*, D.MinValue, D.MaxValue
into #SpiffCompActivationsWT2
from #SpiffCompActivationsWT1 T
	inner join cfgICSSpiffDefinition D on T.SpiffDefinitionID = D.ID
where cast(T.CountMRC as float) between cast(D.MinValue as float) and cast(D.MaxValue as float)
	--and EventType = 'ACT'
	--and EffectiveCalcDate = '2013-06-02'
	--and Months = '2013 06 (JUN)'


/************DEACT***************/
IF OBJECT_ID('tempdb..#RawTXNs') is not Null
drop table #RawTXNs

select   T.*
--select SubscriberActivityKey, COUNT(*)
into #RawTXNs
from dbo.tsdICSActivity T
	left join tsdICSManualExclude E on T.ServiceUniversalID = E.ServiceUniversalID
		and T.BillingSubsystemID = E.BillingSubsystemID
		and T.EventType = E.EventType
		and T.EffectiveCalcDate = E.EffectiveCalcDate
	left join dbo.cfgICSAccountTypeExclude A on A.AccountSubType = T.AccountSubTypeID
		and A.AccountType = T.AccountTypeID
		and CAST(T.EffectiveCalcDate as date) between cast(A.StartDate as date) and cast(A.EndDate as date)
where E.ServiceUniversalID is null
	and A.StartDate is null
	and (T.EventType in ('ACT', 'DEACT') and isnull(T.SameMonth,'Y') <> 'Y'
		or T.EventType = 'REACT')
	and T.IsValid = '1.00'

------- Map to original Act -------
IF OBJECT_ID('tempdb..#SpiffCompActivationsWT3') is not Null
drop table #SpiffCompActivationsWT3

select *
into #SpiffCompActivationsWT3 
from 
(	
------ Map to archICSPaidActivationSpiff-----
select T.*, A.SpiffID, A.SpiffDefinitionID, A.EffectiveCalcDate as ActCalcdate
	,A.AccumulatedPaidAmount, A.LastCalculatedCommission, A.AccumulatedCompAmount, 1 as P 
from #RawTXNs T
	inner join archICSPaidActivationSpiff A on A.BillingSubsystemID = T.BillingSubsystemID
		and A.ServiceUniversalID = T.ServiceUniversalID
where A.EventType = 'ACT' and T.EventType = 'DEACT'
	and cast(T.EffectiveCalcDate as date) >= cast(A.EffectiveCalcDate as Date)
Union 
------ Map to ArchICSActivationSpiffDelta-----
select T.*, A.SpiffID, A.SpiffDefinitionID, A.EffectiveCalcDate as ActCalcdate
	,A.AccumulatedPaidAmount, A.LastCalculatedCommission, A.AccumulatedCompAmount, 0 as P 
from #RawTXNs T
	inner join (
		select * from (
			select *, 
				ROW_NUMBER() Over(Partition by BillingSubSystemID, ServiceUniversalID, EffectiveCalcDate, EventType, SpiffID order by cast(DeltaBatchID as Float) desc) as Seq
			from ArchICSActivationSpiffDelta) X
		where X.Seq = 1) A on A.BillingSubsystemID = T.BillingSubsystemID
		and A.ServiceUniversalID = T.ServiceUniversalID
where A.EventType = 'ACT' and T.EventType = 'DEACT'
	and cast(T.EffectiveCalcDate as date) >= cast(A.EffectiveCalcDate as Date)
) Y


IF OBJECT_ID('tempdb..#SpiffCompActivationsWT4') is not Null
drop table #SpiffCompActivationsWT4

select *
into #SpiffCompActivationsWT4
from (
	select T.*,
		ROW_NUMBER() Over (Partition by BillingSubSystemID, ServiceUniversalID, EffectiveCalcDate, EventType, SpiffID, SalesCode order by P) as Seq
	from #SpiffCompActivationsWT3 T 
) X
where X.Seq = 1