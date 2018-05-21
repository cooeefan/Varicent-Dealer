
------------ Activations -------------------

select T.*, S.AssignmentID, S.ID as cfgICSSpiffPayeeGroupID,S.ID2 as cfgICSSpiffID
from dbo.ICSOOM1170Union T
	inner join ICSSPH1100EligibleSalesCodes S on T.SalesCode = S.SalesCode
		and T.Months = S.Months
	inner join (
		select Distinct BillingSubsystemID, ProductIDCode, EventType, AssignmentID, ID, Months
		from ICSSPH2100EligibleProductCodes
		) X on T.PlanCode = X.ProductIDCode
		and T.BillingSubsystemID = X.BillingSubsystemID
		and T.Event = X.EventType
		and S.AssignmentID = X.AssignmentID
		and S.ID2 = X.ID
		and T.Months = X.Months
	--inner join cfgICSSpiff SP on S.ID2 = SP.ID
	--	and CAST(T.EffectiveCalcDate as date) between cast(SP.StartDate as date) and cast(SP.EndDate as date)
	--inner join cfgICSSpiffCAPSPIFFS SPCS on SP.SpiffID = SPCS.SpiffID
	--	and CAST(T.EffectiveCalcDate as date) between cast(SPCS.StartDate as date) and cast(SPCS.EndDate as date)
	--inner join cfgICSSpiffCAPs SPC on SPCS.CAPID = SPC.CAPID
	--	and CAST(T.EffectiveCalcDate as date) between cast(SPC.StartDate as date) and cast(SPC.EndDate as date)
	
where EVENT in ('ACTIVITY','AAL','PREPAID') 
	--and ServiceUniversalID = '100635921' and EffectiveCalcDate = '2013-06-18' and PlanCode = 'PCADD500' and ID2 = '3.49730367606929E+16'
	and exists (
		select * 
		from cfgICSSpiff SP 
			inner join cfgICSSpiffCAPSPIFFS SPCS on SP.SpiffID = SPCS.SpiffID
			inner join cfgICSSpiffCAPs SPC on SPCS.CAPID = SPC.CAPID
		where SP.ID = S.ID2
			and CAST(T.EffectiveCalcDate as date) between cast(SP.StartDate as date) and cast(SP.EndDate as date)
			and CAST(T.EffectiveCalcDate as date) between cast(SPCS.StartDate as date) and cast(SPCS.EndDate as date)
			and CAST(T.EffectiveCalcDate as date) between cast(SPC.StartDate as date) and cast(SPC.EndDate as date)
		)


------------ Features -------------------

select T.*, S.AssignmentID, S.ID as cfgICSSpiffPayeeGroupID,S.ID2 as cfgICSSpiffID
from dbo.ICSOOM1170Union T
	inner join ICSSPH1100EligibleSalesCodes S on T.SalesCode = S.SalesCode
		and T.Months = S.Months
	inner join (
		select Distinct BillingSubsystemID, ProductIDCode, EventType, AssignmentID, ID, Months
		from ICSSPH2100EligibleProductCodes
		) X on T.PlanCode = X.ProductIDCode
		and T.BillingSubsystemID = X.BillingSubsystemID
		and T.Event = X.EventType
		and S.AssignmentID = X.AssignmentID
		and S.ID2 = X.ID
		and T.Months = X.Months
where EVENT in ('PREPAID FEATURE','FEATURE') 
	--and ServiceUniversalID = '100635921' and EffectiveCalcDate = '2013-06-18' and PlanCode = 'PCADD500' and ID2 = '3.49730367606929E+16'
	and exists (
		select * 
		from cfgICSSpiff SP 
			inner join cfgICSSpiffCAPSPIFFS SPCS on SP.SpiffID = SPCS.SpiffID
			inner join cfgICSSpiffCAPs SPC on SPCS.CAPID = SPC.CAPID
		where SP.ID = S.ID2
			and CAST(T.EffectiveCalcDate as date) between cast(SP.StartDate as date) and cast(SP.EndDate as date)
			and CAST(T.EffectiveCalcDate as date) between cast(SPCS.StartDate as date) and cast(SPCS.EndDate as date)
			and CAST(T.EffectiveCalcDate as date) between cast(SPC.StartDate as date) and cast(SPC.EndDate as date)
			)
			
			
------------ Upgrade -------------------

select T.*, S.AssignmentID, S.ID as cfgICSSpiffPayeeGroupID,S.ID2 as cfgICSSpiffID
from dbo.ICSOOM1170Union T
	inner join ICSSPH1100EligibleSalesCodes S on T.SalesCode = S.SalesCode
		and T.Months = S.Months
	inner join (
		select Distinct BillingSubsystemID, ProductIDCode, EventType, AssignmentID, ID, Months
		from ICSSPH2100EligibleProductCodes
		) X on T.PlanCode = X.ProductIDCode
		and T.BillingSubsystemID = X.BillingSubsystemID
		and T.Event = X.EventType
		and S.AssignmentID = X.AssignmentID
		and S.ID2 = X.ID
		and T.Months = X.Months
where EVENT in ('UPGRADE') 
	--and ServiceUniversalID = '100635921' and EffectiveCalcDate = '2013-06-18' and PlanCode = 'PCADD500' and ID2 = '3.49730367606929E+16'
	and exists (
		select * 
		from cfgICSSpiff SP 
			inner join cfgICSSpiffCAPSPIFFS SPCS on SP.SpiffID = SPCS.SpiffID
			inner join cfgICSSpiffCAPs SPC on SPCS.CAPID = SPC.CAPID
		where SP.ID = S.ID2
			and CAST(T.EffectiveCalcDate as date) between cast(SP.StartDate as date) and cast(SP.EndDate as date)
			and CAST(T.EffectiveCalcDate as date) between cast(SPCS.StartDate as date) and cast(SPCS.EndDate as date)
			and CAST(T.EffectiveCalcDate as date) between cast(SPC.StartDate as date) and cast(SPC.EndDate as date)
			)