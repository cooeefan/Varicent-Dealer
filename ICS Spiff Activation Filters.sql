/******************************
		Raw Transactions
*******************************/

IF OBJECT_ID('tempdb..#SPIFFTXNs') is not Null
drop table #SPIFFTXNs

select T.*, S.AssignmentID, S.ID as cfgICSSpiffPayeeGroupID,S.ID2 as cfgICSSpiffID
	,CAST('' as varchar(500)) as RuleFiltered
into #SPIFFTXNs
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
		
--select * from #SPIFFTXNs


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


/******************************************
		Agreement Type Name Filter
*******************************************/

--select * 
update T
set T.RuleFiltered = T.RuleFiltered+'AgreementType,'
from #SPIFFTXNs T
	inner join #DealerMonthlyEligibility D on T.SalesCode = D.SalesCode
		and Substring(T.Months,1,7) = SUBSTRING(CurrentMonth,1,4)+SUBSTRING(CurrentMonth,12,3)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'AGREEMENTTYPENAME'
			and FI.Action = '!='
		)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'AGREEMENTTYPENAME'
			and FI.Action = '!='
			and FI.FilterValueText = D.AgreementType
		)
	
update T
set T.RuleFiltered = T.RuleFiltered+'AgreementType,'
from #SPIFFTXNs T
	inner join #DealerMonthlyEligibility D on T.SalesCode = D.SalesCode
		and Substring(T.Months,1,7) = SUBSTRING(CurrentMonth,1,4)+SUBSTRING(CurrentMonth,12,3)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'AGREEMENTTYPENAME'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'AGREEMENTTYPENAME'
			and FI.Action = '='
			and FI.FilterValueText = D.AgreementType
			)


/******************************************
		MasterDealer Code Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'MasterDealer Code,'
from #SPIFFTXNs T
	inner join #DealerMonthlyEligibility D on T.SalesCode = D.SalesCode
		and Substring(T.Months,1,7) = SUBSTRING(CurrentMonth,1,4)+SUBSTRING(CurrentMonth,12,3)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'MASTERDEALERCODE'
			and FI.Action = '!='
		)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'MASTERDEALERCODE'
			and FI.Action = '!='
			and FI.FilterValueText = D.MasterDealerCode
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'MasterDealer Code,'
from #SPIFFTXNs T
	inner join #DealerMonthlyEligibility D on T.SalesCode = D.SalesCode
		and Substring(T.Months,1,7) = SUBSTRING(CurrentMonth,1,4)+SUBSTRING(CurrentMonth,12,3)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'MASTERDEALERCODE'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'MASTERDEALERCODE'
			and FI.Action = '='
			and FI.FilterValueText = D.MasterDealerCode
			)


/******************************************
	     	Contract Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'Contract,'
from #SPIFFTXNs T
	inner join #DealerMonthlyEligibility D on T.SalesCode = D.SalesCode
		and Substring(T.Months,1,7) = SUBSTRING(CurrentMonth,1,4)+SUBSTRING(CurrentMonth,12,3)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CONTRACT'
			and FI.Action = '!='
		)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CONTRACT'
			and FI.Action = '!='
			and FI.FilterValueText = D.ContractID
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'Contract,'
from #SPIFFTXNs T
	inner join #DealerMonthlyEligibility D on T.SalesCode = D.SalesCode
		and Substring(T.Months,1,7) = SUBSTRING(CurrentMonth,1,4)+SUBSTRING(CurrentMonth,12,3)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CONTRACT'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CONTRACT'
			and FI.Action = '='
			and FI.FilterValueText = D.ContractID
			)


/******************************************
	     	SubdealerEntity Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'SubDealerEntity,'
from #SPIFFTXNs T
	inner join #DealerMonthlyEligibility D on T.SalesCode = D.SalesCode
		and Substring(T.Months,1,7) = SUBSTRING(CurrentMonth,1,4)+SUBSTRING(CurrentMonth,12,3)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'SUBDEALERENTITY'
			and FI.Action = '!='
		)
	and  exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'SUBDEALERENTITY'
			and FI.Action = '!='
			and FI.FilterValueText = ISNull(D.SubDealerID,'')
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'SubDealerEntity,'
from #SPIFFTXNs T
	inner join #DealerMonthlyEligibility D on T.SalesCode = D.SalesCode
		and Substring(T.Months,1,7) = SUBSTRING(CurrentMonth,1,4)+SUBSTRING(CurrentMonth,12,3)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'SUBDEALERENTITY'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'SUBDEALERENTITY'
			and FI.Action = '='
			and FI.FilterValueText = ISNull(D.SubDealerID,'')
			)


/******************************************
	     	SalesCode Filter
*******************************************/
update T
set T.RuleFiltered = T.RuleFiltered+'SalesCode,'
from #SPIFFTXNs T
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'SALESCODE'
			and FI.Action = '!='
		)
	and  exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'SALESCODE'
			and FI.Action = '!='
			and FI.FilterValueText = T.SalesCode
		)
	
update T
set T.RuleFiltered = T.RuleFiltered+'SalesCode,'
from #SPIFFTXNs T
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'SALESCODE'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'SALESCODE'
			and FI.Action = '='
			and FI.FilterValueText = T.SalesCode
		)


/******************************************
	     	MarketCode Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'MarketCode,'
from #SPIFFTXNs T
	inner join tsdICSActivity RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.EventType = T.EventType
		and cast(RT.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'MARKETCODE'
			and FI.Action = '!='
			)
	and  exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'MARKETCODE'
			and FI.Action = '!='
			and FI.FilterValueText = RT.MarketCode
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'MarketCode,'
from #SPIFFTXNs T
	inner join tsdICSActivity RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.EventType = T.EventType
		and cast(RT.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'MARKETCODE'
			and FI.Action = '='
			)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'MARKETCODE'
			and FI.Action = '='
			and FI.FilterValueText = RT.MarketCode
			)


/******************************************
	     	Contract Term Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'ContractTerm,'
from #SPIFFTXNs T
	inner join tsdICSActivity RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.EventType = T.EventType
		and cast(RT.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CONTRACTTERM'
			and FI.Action = '!='
			)
	and  exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CONTRACTTERM'
			and FI.Action = '!='
			and FI.FilterValueText = RT.ContractTerm
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'ContractTerm,'
from #SPIFFTXNs T
	inner join tsdICSActivity RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.EventType = T.EventType
		and cast(RT.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CONTRACTTERM'
			and FI.Action = '='
			)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CONTRACTTERM'
			and FI.Action = '='
			and FI.FilterValueText = RT.ContractTerm
			)
			
/******************************************
	     	FullyLoaded Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'FullyLoaded,'
from #SPIFFTXNs T
	inner join tsdICSActivity RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.EventType = T.EventType
		and cast(RT.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'FULLYLOADEDFLAG'
			and FI.Action = '!='
			)
	and  exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'FULLYLOADEDFLAG'
			and FI.Action = '!='
			and FI.FilterValueText = RT.FullyLoaded
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'FullyLoaded,'
from #SPIFFTXNs T
	inner join tsdICSActivity RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.EventType = T.EventType
		and cast(RT.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'FULLYLOADEDFLAG'
			and FI.Action = '='
			)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'FULLYLOADEDFLAG'
			and FI.Action = '='
			and FI.FilterValueText = RT.FullyLoaded
			)


/******************************************
	      PlanFeatureLevel Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'PlanFeatureLevel,'
from #SPIFFTXNs T
	inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
		and T.ServiceUniversalID = FA.ServiceUniversalID
		and FA.EventType = 'ACT'
		and Month(FA.EffectiveCalcDate) = Month(T.EffectiveCalcDate)
		and Year(FA.EffectiveCalcDate) = Year(T.EffectiveCalcDate)
	inner join cfgICSProductCategory PC on PC.BillingSubsystemID = FA.BillingSubsystemID
		and PC.ProductIDCode = FA.FeatureSOC
		and cast(T.EffectiveCalcDate as DATE) between cast(PC.StartDate as date) and cast(PC.EndDate as date)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'PLANFEATURELEVEL'
			and FI.Action = '!='
			)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'PLANFEATURELEVEL'
			and FI.Action = '!='
			and FI.FilterValueText = PC.Level			----- Should Not include UNKNOWN
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'PlanFeatureLevel,'
--select * 
from #SPIFFTXNs T
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'PLANFEATURELEVEL'
			and FI.Action = '='
			)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
			inner join cfgICSProductCategory PC on FI.FilterValueText = PC.Level
			inner join tsdICSFeatureActivation FA on FA.FeatureSOC = PC.ProductIDCode
		where S.ID = T.cfgICSSpiffID
			and PC.BillingSubsystemID = FA.BillingSubsystemID
			and T.ServiceUniversalID = FA.ServiceUniversalID
			and FA.EventType = 'ACT'
			and Month(FA.EffectiveCalcDate) = Month(T.EffectiveCalcDate)
			and Year(FA.EffectiveCalcDate) = Year(T.EffectiveCalcDate)
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(PC.StartDate as date) and cast(PC.EndDate as date)
			and S.IsActive = 'Y' and F.IsActive = 'Y' and FI.IsActive = 'Y' and PC.IsCommissionable = 'YES'
			and FI.FilterValueDesc = 'PLANFEATURELEVEL'
			and FI.Action = '='
			)
		--and T.ServiceUniversalID = '100834351'
			
update T
set T.RuleFiltered = T.RuleFiltered+'PlanFeatureLevel,'
from #SPIFFTXNs T
	left join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
		and T.ServiceUniversalID = FA.ServiceUniversalID
		and FA.EventType = 'ACT'
		and Month(FA.EffectiveCalcDate) = Month(T.EffectiveCalcDate)
		and Year(FA.EffectiveCalcDate) = Year(T.EffectiveCalcDate)
	left join cfgICSProductCategory PC on PC.BillingSubsystemID = FA.BillingSubsystemID
		and PC.ProductIDCode = FA.FeatureSOC
		and cast(T.EffectiveCalcDate as DATE) between cast(PC.StartDate as date) and cast(PC.EndDate as date)	
where PC.ProductIDCode is null		----- No mapping Feature or Product transactions
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'PLANFEATURELEVEL'
			and FI.Action ='='
			)


--select * from #SPIFFTXNs where RuleFiltered like  'PlanFeatureLevel%' order by serviceUniversalID

--select COUNT(*) from #SPIFFTXNs


--update #SPIFFTXNs set RuleFiltered = ''

--select BillingSubsystemID, ServiceUniversalID, EffectiveCalcDate, EventType, SalesCode, Event, cfgICSSpiffID, Months 
--from #SPIFFTXNs where RuleFiltered like  'PlanFeatureLevel%'
--except
--select BillingSubsystemID, ServiceUniversalID, EffectiveCalcDate, EventType, SalesCode, Event, cfgICSSpiffID, Months  
--from dbo.UnionOfTrapActivations where RuleDescription = 'TRAP Transaction of PLANFEATURELEVEL Activations'
--except
--select BillingSubsystemID, ServiceUniversalID, EffectiveCalcDate, EventType, SalesCode, Event, cfgICSSpiffID, Months 
--from #SPIFFTXNs where RuleFiltered like  'PlanFeatureLevel%'

--select * from #SPIFFTXNs where ServiceUniversalID = '2292000318' 
--select * from tsdICSFeatureActivation where ServiceUniversalID = '2292000318' 
--select * from UnionOfTrapActivations where ServiceUniversalID = '2292000318' 

--select *
--from #SPIFFTXNs T
	--inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
	--	and T.ServiceUniversalID = FA.ServiceUniversalID
		--and FA.EventType = 'ACT'
		--and Month(FA.EffectiveCalcDate) = Month(T.EffectiveCalcDate)
		--and Year(FA.EffectiveCalcDate) = Year(T.EffectiveCalcDate)
	--inner join cfgICSProductCategory PC on PC.BillingSubsystemID = FA.BillingSubsystemID
	--	and PC.ProductIDCode = FA.FeatureSOC
	--	and cast(T.EffectiveCalcDate as DATE) between cast(PC.StartDate as date) and cast(PC.EndDate as date)
--where T.ServiceUniversalID = '2292000318'


/******************************************
		PlanFeature Activation Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'PlanFeature Activation,'
from #SPIFFTXNs T
	inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
		and T.ServiceUniversalID = FA.ServiceUniversalID
		and FA.EventType = 'ACT'
		and Month(FA.EffectiveCalcDate) = Month(T.EffectiveCalcDate)
		and Year(FA.EffectiveCalcDate) = Year(T.EffectiveCalcDate)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'PLANFEATURE'
			and FI.Action = '!='
			)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'PLANFEATURE'
			and FI.Action = '!='
			and FI.FilterValueText = FA.FeatureSOC			----- Should Not include UNKNOWN
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'PlanFeature Activation,'
--select * 
from #SPIFFTXNs T
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'PLANFEATURE'
			and FI.Action = '='
			)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
			inner join tsdICSFeatureActivation FA on FA.FeatureSOC = FI.FilterValueText
		where S.ID = T.cfgICSSpiffID
			and T.ServiceUniversalID = FA.ServiceUniversalID
			and FA.EventType = 'ACT'
			and Month(FA.EffectiveCalcDate) = Month(T.EffectiveCalcDate)
			and Year(FA.EffectiveCalcDate) = Year(T.EffectiveCalcDate)
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y' and F.IsActive = 'Y' and FI.IsActive = 'Y' 
			and FI.FilterValueDesc = 'PLANFEATURE'
			and FI.Action = '='
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'PlanFeature Activation,'
from #SPIFFTXNs T
	left join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
		and T.ServiceUniversalID = FA.ServiceUniversalID
		and FA.EventType = 'ACT'
		and Month(FA.EffectiveCalcDate) = Month(T.EffectiveCalcDate)
		and Year(FA.EffectiveCalcDate) = Year(T.EffectiveCalcDate)
where FA.FeatureActivityKey is null		----- No mapping Feature 
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'PLANFEATURE'
			and FI.Action ='='
			)		

			

/******************************************
		HOTI Activation Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'HOTI Activation,'
from #SPIFFTXNs T
	inner join dbo.tsdICSActivity IA on T.BillingSubsystemID = IA.BillingSubsystemID
		and T.ServiceUniversalID = IA.ServiceUniversalID
		and T.EventType = IA.EventType
		and T.EffectiveCalcDate = IA.EffectiveCalcDate
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'HOTI'
			and FI.Action = '!='
		)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'HOTI'
			and FI.Action = '!='
			and FI.FilterValueText = IA.HOTI
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'HOTI Activation,'
from #SPIFFTXNs T
	inner join dbo.tsdICSActivity IA on T.BillingSubsystemID = IA.BillingSubsystemID
		and T.ServiceUniversalID = IA.ServiceUniversalID
		and T.EventType = IA.EventType
		and T.EffectiveCalcDate = IA.EffectiveCalcDate
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'HOTI'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'HOTI'
			and FI.Action = '='
			and FI.FilterValueText = IA.HOTI
			)

/******************************************
		Credit Class Activation Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'CreditClass Activation,'
from #SPIFFTXNs T
	inner join dbo.tsdICSActivity IA on T.BillingSubsystemID = IA.BillingSubsystemID
		and T.ServiceUniversalID = IA.ServiceUniversalID
		and T.EventType = IA.EventType
		and T.EffectiveCalcDate = IA.EffectiveCalcDate
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CREDITCLASS'
			and FI.Action = '!='
		)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CREDITCLASS'
			and FI.Action = '!='
			and FI.FilterValueText = IA.CreditClass
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'CreditClass Activation,'
from #SPIFFTXNs T
	inner join dbo.tsdICSActivity IA on T.BillingSubsystemID = IA.BillingSubsystemID
		and T.ServiceUniversalID = IA.ServiceUniversalID
		and T.EventType = IA.EventType
		and T.EffectiveCalcDate = IA.EffectiveCalcDate
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CREDITCLASS'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CREDITCLASS'
			and FI.Action = '='
			and FI.FilterValueText = IA.CreditClass
			)

/******************************************
		Port Type Activation Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'PortType Activation,'
from #SPIFFTXNs T
	inner join dbo.tsdICSActivity IA on T.BillingSubsystemID = IA.BillingSubsystemID
		and T.ServiceUniversalID = IA.ServiceUniversalID
		and T.EventType = IA.EventType
		and T.EffectiveCalcDate = IA.EffectiveCalcDate
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'PORTTYPE'
			and FI.Action = '!='
		)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'PORTTYPE'
			and FI.Action = '!='
			and FI.FilterValueText = IA.PortType
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'PortType Activation,'
from #SPIFFTXNs T
	inner join dbo.tsdICSActivity IA on T.BillingSubsystemID = IA.BillingSubsystemID
		and T.ServiceUniversalID = IA.ServiceUniversalID
		and T.EventType = IA.EventType
		and T.EffectiveCalcDate = IA.EffectiveCalcDate
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'PORTTYPE'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'PORTTYPE'
			and FI.Action = '='
			and FI.FilterValueText = IA.PortType
			)


/******************************************
		Corp Node Activation Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'CorpNode Activation,'
from #SPIFFTXNs T
	inner join dbo.tsdICSActivity IA on T.BillingSubsystemID = IA.BillingSubsystemID
		and T.ServiceUniversalID = IA.ServiceUniversalID
		and T.EventType = IA.EventType
		and T.EffectiveCalcDate = IA.EffectiveCalcDate
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CORPNODE'
			and FI.Action = '!='
		)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CORPNODE'
			and FI.Action = '!='
			and FI.FilterValueText = IA.CorpNodeNumber
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'CorpNode Activation,'
from #SPIFFTXNs T
	inner join dbo.tsdICSActivity IA on T.BillingSubsystemID = IA.BillingSubsystemID
		and T.ServiceUniversalID = IA.ServiceUniversalID
		and T.EventType = IA.EventType
		and T.EffectiveCalcDate = IA.EffectiveCalcDate
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CORPNODE'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CORPNODE'
			and FI.Action = '='
			and FI.FilterValueText = IA.CorpNodeNumber
			)
			

/******************************************
		Shipped To Master Activation Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'ShippedToMaster,'
from #SPIFFTXNs T
	inner join dbo.tsdICSActivity IA on T.BillingSubsystemID = IA.BillingSubsystemID
		and T.ServiceUniversalID = IA.ServiceUniversalID
		and T.EventType = IA.EventType
		and T.EffectiveCalcDate = IA.EffectiveCalcDate
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'SHIPPEDTOMASTER'
			and FI.Action = '!='
		)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'SHIPPEDTOMASTER'
			and FI.Action = '!='
			and FI.FilterValueText = IA.ShipToMaster
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'ShippedToMaster,'
from #SPIFFTXNs T
	inner join dbo.tsdICSActivity IA on T.BillingSubsystemID = IA.BillingSubsystemID
		and T.ServiceUniversalID = IA.ServiceUniversalID
		and T.EventType = IA.EventType
		and T.EffectiveCalcDate = IA.EffectiveCalcDate
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'SHIPPEDTOMASTER'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'SHIPPEDTOMASTER'
			and FI.Action = '='
			and FI.FilterValueText = IA.ShipToMaster
			)
			



/****************************************************
		FullLoaded Percentage Filter
*****************************************************/

IF OBJECT_ID('tempdb..#Numerator') IS NOT NULL
DROP TABLE #Numerator

SELECT OOM.* INTO #Numerator
FROM dbo.ICSOOM1230PPDActivityWithOOMCap OOM	INNER JOIN dbo.cfgICSProductCategory PC
ON OOM.BillingSubSystemID = PC.BillingSubsystemID
AND OOM.PlanCode = PC.ProductIDCode
AND CAST(OOM.EffectiveCalcDate AS DATE) BETWEEN CAST(PC.StartDate AS DATE) AND CAST(PC.EndDate AS DATE)

INNER JOIN dbo.refICSBANLevelFeatures BL ON BL.Level = PC.Level
AND CAST(OOM.EffectiveCalcDate AS DATE) BETWEEN CAST(BL.StartDate AS DATE) AND CAST(BL.EndDate AS DATE)

INNER JOIN dbo.tsdICSActivity IA ON IA.BillingSubsystemID = OOM.BillingSubsystemID
AND IA.ServiceUniversalID = OOM.ServiceUniversalID
AND IA.EventType = OOM.EventType
AND CAST(IA.EffectiveCalcDate AS DATE) = CAST(OOM.EffectiveCalcDate AS DATE)

WHERE BL.MonthlyPlanLevelFlag = 'Y'
AND OOM.EventType = 'ACT'
AND IA.FullyLoaded = 'Y'



IF OBJECT_ID('tempdb..#Denominator') IS NOT NULL
DROP TABLE #Denominator

SELECT OOM.* INTO #Denominator
FROM dbo.ICSOOM1230PPDActivityWithOOMCap OOM	INNER JOIN dbo.cfgICSProductCategory PC
ON OOM.BillingSubSystemID = PC.BillingSubsystemID
AND OOM.PlanCode = PC.ProductIDCode
AND CAST(OOM.EffectiveCalcDate AS DATE) BETWEEN CAST(PC.StartDate AS DATE) AND CAST(PC.EndDate AS DATE)

INNER JOIN dbo.refICSBANLevelFeatures BL ON BL.Level = PC.Level
AND CAST(OOM.EffectiveCalcDate AS DATE) BETWEEN CAST(BL.StartDate AS DATE) AND CAST(BL.EndDate AS DATE)

WHERE BL.MonthlyPlanLevelFlag = 'Y'
AND OOM.EventType = 'ACT'

--*********** Count of Numerators and unioning them **********
IF OBJECT_ID('tempdb..#UnionNumerators') IS NOT NULL
DROP TABLE #UnionNumerators

SELECT SubDealerID AS LevelType, 'SDE' AS Rollup, Months, COUNT(SubDealerID) AS Value
INTO #UnionNumerators
FROM #Numerator 
GROUP BY SubDealerID, Months
UNION ALL
SELECT MasterDealerCode, 'MasterDealer', Months, COUNT(MasterDealerCode)
FROM #Numerator 
GROUP BY MasterDealerCode, Months
UNION ALL
SELECT AgreementType, 'AGREEMENTTYPE', Months, COUNT(AgreementType)
FROM #Numerator 
GROUP BY AgreementType, Months
UNION ALL
SELECT SalesCode, 'SALESCODE', Months, COUNT(SalesCode)
FROM #Numerator 
GROUP BY SalesCode, Months
UNION ALL
SELECT ContractID, 'CONTRACT', Months, COUNT(ContractID)
FROM #Numerator 
GROUP BY ContractID, Months

--*********** Count of Denominators and unioning them **********
IF OBJECT_ID('tempdb..#UnionDenominator') IS NOT NULL
DROP TABLE #UnionDenominator

SELECT SubDealerID AS LevelType, 'SDE' AS Rollup, Months, COUNT(SubDealerID) AS Value
INTO #UnionDenominator
FROM #Denominator 
GROUP BY SubDealerID, Months
UNION ALL
SELECT MasterDealerCode, 'MasterDealer', Months, COUNT(MasterDealerCode)
FROM #Denominator 
GROUP BY MasterDealerCode, Months
UNION ALL
SELECT AgreementType, 'AGREEMENTTYPE', Months, COUNT(AgreementType)
FROM #Denominator 
GROUP BY AgreementType, Months
UNION ALL
SELECT SalesCode, 'SALESCODE', Months, COUNT(SalesCode)
FROM #Denominator
GROUP BY SalesCode, Months
UNION ALL
SELECT ContractID, 'CONTRACT', Months, COUNT(ContractID)
FROM #Denominator 
GROUP BY ContractID, Months


--******** Calculating the Percentage *******
IF OBJECT_ID('tempdb..#FULLYLOADEDPERCENTBYROLLUPLEVEL') IS NOT NULL
DROP TABLE #FULLYLOADEDPERCENTBYROLLUPLEVEL

SELECT DISTINCT N.LevelType AS RollupValue, N.Rollup AS RollupType, N.Months, CAST(N.Value AS FLOAT)/CAST(D.Value AS FLOAT) AS PercentValues 
INTO #FULLYLOADEDPERCENTBYROLLUPLEVEL
FROM #UnionNumerators N INNER JOIN #UnionDenominator D ON N.LevelType = D.LevelType
AND N.Rollup = N.Rollup
AND N.Months = D.Months

--SELECT * FROM #FULLYLOADEDPERCENTBYROLLUPLEVEL


--******** Calculating All FullyLoaded *******
IF OBJECT_ID('tempdb..#AllFullyLoaded') IS NOT NULL
DROP TABLE #AllFullyLoaded

SELECT Distinct T.BillingSubSystemID, T.ServiceUniversalID, T.EffectiveCalcDate, T.EventType, T.SalesCode
,T.Event, T.cfgICSSpiffID, T.Months, FI.Action, FI.FilterValueDesc
INTO #AllFullyLoaded
FROM dbo.ICSSpiffFilterActivationPassThrough T INNER JOIN dbo.cfgICSSpiff CIS ON CIS.ID = T.cfgICSSpiffID

INNER JOIN dbo.cfgICSSpiffFilter SF ON SF.SpiffID = CIS.SpiffID
AND SF.IsActive = 'Y'
AND CAST(T.EffectiveCalcDate AS DATE) BETWEEN CAST(SF.StartDate AS DATE) AND CAST(SF.EndDate AS DATE) 

INNER JOIN dbo.cfgICSSpiffFilterItems FI ON FI.FilterTableItemID = SF.FilterTableItemID
AND CAST(T.EffectiveCalcDate AS DATE) BETWEEN CAST(FI.StartDate AS DATE) AND CAST(FI.EndDate AS DATE) 
AND FI.FilterValueDesc = 'FULLYLOADEDPERCENT'



--******** Calculating Eligible FullyLoaded *******
IF OBJECT_ID('tempdb..#EligibleFullyLoaded') IS NOT NULL
DROP TABLE #EligibleFullyLoaded

SELECT Distinct T.BillingSubSystemID, T.ServiceUniversalID, T.EffectiveCalcDate, T.EventType, T.SalesCode
,T.Event, T.cfgICSSpiffID, T.Months, FI.Action, FI.FilterValueDesc
INTO #EligibleFullyLoaded
FROM dbo.ICSSpiffFilterActivationPassThrough T INNER JOIN dbo.cfgICSSpiff CIS ON CIS.ID = T.cfgICSSpiffID

INNER JOIN dbo.cfgICSSpiffFilter SF ON SF.SpiffID = CIS.SpiffID
AND SF.IsActive = 'Y'
AND CAST(T.EffectiveCalcDate AS DATE) BETWEEN CAST(SF.StartDate AS DATE) AND CAST(SF.EndDate AS DATE) 

INNER JOIN dbo.cfgICSSpiffFilterItems FI ON FI.FilterTableItemID = SF.FilterTableItemID
AND CAST(T.EffectiveCalcDate AS DATE) BETWEEN CAST(FI.StartDate AS DATE) AND CAST(FI.EndDate AS DATE) 
AND FI.FilterValueDesc = 'FULLYLOADEDPERCENT'

INNER JOIN dbo.ICSHierarchySCH1200EligibleSalesCodesAttribute ESC ON T.SalesCode = ESC.SalesCode
AND T.Months = ESC.Months

INNER JOIN #FULLYLOADEDPERCENTBYROLLUPLEVEL FLR ON FI.RollupType = FLR.RollupType
AND T.Months = FLR.Months

WHERE 
(
   CASE WHEN FI.Action = '=' THEN FLR.PercentValues END = FI.FilterValueNum
OR CASE WHEN FI.Action = '<=' THEN FLR.PercentValues END <= FI.FilterValueNum
OR CASE WHEN FI.Action = '>=' THEN FLR.PercentValues END >= FI.FilterValueNum
OR CASE WHEN FI.Action = '<' THEN FLR.PercentValues END < FI.FilterValueNum
OR CASE WHEN FI.Action = '>' THEN FLR.PercentValues END > FI.FilterValueNum
)
AND
(
   (FI.RollupType = 'SALESCODE' AND FLR.RollupValue = T.SalesCode)
OR (FI.RollupType = 'SDE' AND FLR.RollupValue = ESC.SubDealerID)
OR (FI.RollupType = 'CONTRACT' AND FLR.RollupValue = ESC.ContractID)
OR (FI.RollupType = 'MASTERDEALER' AND FLR.RollupValue = ESC.MasterDealerCode)
OR (FI.RollupType = 'AGREEMENTTYPE' AND FLR.RollupValue = ESC.AgreementType)
)


--******** Separating out TRAP transactions *******
IF OBJECT_ID('tempdb..#FullyLoadedTRAP') IS NOT NULL
DROP TABLE #FullyLoadedTRAP

SELECT * INTO #FullyLoadedTRAP FROM #AllFullyLoaded
EXCEPT
SELECT * FROM #EligibleFullyLoaded


--********** Updating the TRAP table **************
UPDATE T
SET T.RuleFiltered = T.RuleFiltered+'FullyLoadedPercent,'
FROM #SPIFFTXNs T INNER JOIN #FullyLoadedTRAP FLT
ON T.BillingSubSystemID = FLT.BillingSubSystemID
AND T.ServiceUniversalID = FLT.ServiceUniversalID
AND T.EffectiveCalcDate = FLT.EffectiveCalcDate
AND T.EventType = FLT.EventType
AND T.SalesCode = FLT.SalesCode
AND T.Event = FLT.Event
AND T.cfgICSSpiffID = FLT.cfgICSSpiffID
AND T.Months = FLT.Months


/****************************************************
		     DaysToUsage Filter
*****************************************************/

IF OBJECT_ID('tempdb..#DaysToUsageTable') is not Null
drop table #DaysToUsageTable

select T.*, RT.FirstUseDate
	,case when (RT.FirstUseDate is null OR RT.FirstUseDate = '') then 0
	 else DATEDIFF(dd,RT.EffectiveCalcDate,RT.FirstUseDate ) end as DaysToUsage
into #DaysToUsageTable
from #SPIFFTXNs T
	left join tsdICSActivity RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.EventType = T.EventType
		and cast(RT.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
--where T.ServiceUniversalID = '2307987404'

update T1
set T1.RuleFiltered = T1.RuleFiltered+'DaysToUsage,'
from #SPIFFTXNs T1
left join (
	----- Pass Through TXNs------
	select T.*
	from #SPIFFTXNs T
		inner join #DaysToUsageTable DTU on T.ServiceUniversalID = DTU.ServiceUniversalID
			and T.EventType = DTU.EventType
			and T.BillingSubsystemID = DTU.BillingSubsystemID
			and cast(DTU.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
		inner join cfgICSSpiff S on T.cfgICSSpiffID = S.ID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and  S.IsActive = 'Y'
		inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and F.IsActive = 'Y'
		inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and FI.IsActive = 'Y'
	where FI.FilterValueDesc = 'DAYSTOUSAGE'
		and ( FI.Action = '<' and cast(DTU.DaysToUsage as float) < cast(FI.FilterValueNum as float)
			or FI.Action = '<=' and cast(DTU.DaysToUsage as float) <= cast(FI.FilterValueNum as float)
			or FI.Action = '=' and cast(DTU.DaysToUsage as float) = cast(FI.FilterValueNum as float)
			or FI.Action = '>=' and cast(DTU.DaysToUsage as float) >= cast(FI.FilterValueNum as float)
			or FI.Action = '>' and cast(DTU.DaysToUsage as float) > cast(FI.FilterValueNum as float)
			)
	union 
	select T.*
	from #SPIFFTXNs T
	where not exists(
			select * 
			from cfgICSSpiff S
				inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
				inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
			where S.ID = T.cfgICSSpiffID
				and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
				and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
				and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
				and S.IsActive = 'Y'
				and F.IsActive = 'Y'
				and FI.IsActive = 'Y'
				and FI.FilterValueDesc = 'DAYSTOUSAGE'
				)
	) X on T1.BillingSubsystemID = X.BillingSubsystemID
		and T1.ServiceUniversalID = X.ServiceUniversalID
		and T1.EventType = X.EventType
		and cast(T1.EffectiveCalcDate as date) = cast(X.EffectiveCalcDate as date)
where X.ServiceUniversalID is null


/****************************************************
		            TAC Filter
*****************************************************/

--select * 
update T
set T.RuleFiltered = T.RuleFiltered+'TAC,'
from #SPIFFTXNs T
	inner join dbo.tsdICSActivity IA on T.BillingSubsystemID = IA.BillingSubsystemID
		and T.ServiceUniversalID = IA.ServiceUniversalID
		and T.EventType = IA.EventType
		and cast(T.EffectiveCalcDate as date) = cast(IA.EffectiveCalcDate as date)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'TAC'
			and FI.Action = '!='
		)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'TAC'
			and FI.Action = '!='
			and FI.FilterValueText = IA.TAC
			)

--select *	
update T
set T.RuleFiltered = T.RuleFiltered+'TAC,'
from #SPIFFTXNs T
	inner join dbo.tsdICSActivity IA on T.BillingSubsystemID = IA.BillingSubsystemID
		and T.ServiceUniversalID = IA.ServiceUniversalID
		and T.EventType = IA.EventType
		and cast(T.EffectiveCalcDate as date) = cast(IA.EffectiveCalcDate as date)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'TAC'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'TAC'
			and FI.Action = '='
			and FI.FilterValueText = IA.TAC
			)
			
			
/****************************************************
		           DupIMEI Filter
*****************************************************/

--select *
update T
set T.RuleFiltered = T.RuleFiltered+'DupIMEI,'
from #SPIFFTXNs T
	inner join dbo.tsdICSActivity IA on T.BillingSubsystemID = IA.BillingSubsystemID
		and T.ServiceUniversalID = IA.ServiceUniversalID
		and T.EventType = IA.EventType
		and cast(T.EffectiveCalcDate as date) = cast(IA.EffectiveCalcDate as date)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'ALLOWDUPLICATEIMEI'
			and FI.FilterValueText = 'N'
			and FI.Action = '='
		)
		and Exists(
		 select * from tsdICSIMEIUsage I
		 where I.IMEI = IA.IMEI and I.EventType = IA.EventType
			and I.EffectiveCalcDate <> T.EffectiveCalcDate
			and DATEDIFF(dd, I.EffectiveCalcDate, T.EffectiveCalcDate) <= 180
			)
			

/******************************************
		Location Market Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'LocationMarket,'
from #SPIFFTXNs T

where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'LOCATIONMARKETCODE'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
			inner join dbo.cfgICSSalesCode ISC ON T.SalesCode = ISC.SalesCode
	
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and CAST(T.EffectiveCalcDate AS DATE) BETWEEN CAST(ISC.StartDate AS DATE) AND CAST(ISC.EndDate AS DATE) 
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'LOCATIONMARKETCODE'
			and FI.Action = '='
			and FI.FilterValueText = ISC.LocationMarketCode
			)

update T
set T.RuleFiltered = T.RuleFiltered+'LocationMarket,'
from #SPIFFTXNs T

where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'LOCATIONMARKETCODE'
			and FI.Action = '!='
		)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
			inner join dbo.cfgICSSalesCode ISC ON T.SalesCode = ISC.SalesCode
	
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and CAST(T.EffectiveCalcDate AS DATE) BETWEEN CAST(ISC.StartDate AS DATE) AND CAST(ISC.EndDate AS DATE) 
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'LOCATIONMARKETCODE'
			and FI.Action = '!='
			and FI.FilterValueText = ISC.LocationMarketCode
			)
			

/******************************************
		COB Indicator Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'COBIndicator,'
from #SPIFFTXNs T

where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'COBINDICATOR'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
			inner join dbo.tsdICSActivity IA on T.BillingSubSystemID = IA.BillingSubsystemID	
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and T.ServiceUniversalID = IA.ServiceUniversalID
			and T.EventType = IA.EventType
			and T.EffectiveCalcDate = IA.EffectiveCalcDate
			and FI.FilterValueDesc = 'COBINDICATOR'
			and FI.Action = '='
			and FI.FilterValueText = IA.COBIndicator
			)

update T
set T.RuleFiltered = T.RuleFiltered+'COBIndicator,'
from #SPIFFTXNs T

where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'COBINDICATOR'
			and FI.Action = '!='
		)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
			inner join dbo.tsdICSActivity IA on T.BillingSubSystemID = IA.BillingSubsystemID	
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and T.ServiceUniversalID = IA.ServiceUniversalID
			and T.EventType = IA.EventType
			and T.EffectiveCalcDate = IA.EffectiveCalcDate
			and FI.FilterValueDesc = 'COBINDICATOR'
			and FI.Action = '!='
			and FI.FilterValueText = IA.COBIndicator
			)
			

/******************************************
		TAC Group Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'TACGroup,'
from #SPIFFTXNs T
	inner join tsdICSActivity RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.EventType = T.EventType
		and cast(RT.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'TACGROUP'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
			inner join dbo.cfgICSSpiffTACGroups TG on FI.FilterValueText = TG.TACGroupID
		where S.ID = T.cfgICSSpiffID
			and RT.TAC = TG.TAC
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(TG.StartDate as date) and cast(TG.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and TG.IsActive = 'Y'
			and FI.FilterValueDesc = 'TACGROUP'
			and FI.Action = '='
			)

update T
set T.RuleFiltered = T.RuleFiltered+'TACGroup,'
from #SPIFFTXNs T
	inner join tsdICSActivity RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.EventType = T.EventType
		and cast(RT.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'TACGROUP'
			and FI.Action = '!='
		)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
			inner join dbo.cfgICSSpiffTACGroups TG on FI.FilterValueText = TG.TACGroupID
		where S.ID = T.cfgICSSpiffID
			and RT.TAC = TG.TAC
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(TG.StartDate as date) and cast(TG.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and TG.IsActive = 'Y'
			and FI.FilterValueDesc = 'TACGROUP'
			and FI.Action = '!='
			)
			
/******************************************
		Market Group Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'MarketGroup,'
from #SPIFFTXNs T
	inner join tsdICSActivity RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.EventType = T.EventType
		and cast(RT.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'MARKETGROUP'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
			inner join dbo.cfgICSSpiffMarketGroups TG on FI.FilterValueText = TG.MarketGroupID
		where S.ID = T.cfgICSSpiffID
			and RT.MarketCode = TG.marketCode
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(TG.StartDate as date) and cast(TG.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and TG.IsActive = 'Y'
			and FI.FilterValueDesc = 'MARKETGROUP'
			and FI.Action = '='
			)

update T
set T.RuleFiltered = T.RuleFiltered+'MarketGroup,'
from #SPIFFTXNs T
	inner join tsdICSActivity RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.EventType = T.EventType
		and cast(RT.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'MARKETGROUP'
			and FI.Action = '!='
		)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
			inner join dbo.cfgICSSpiffMarketGroups TG on FI.FilterValueText = TG.MarketGroupID
		where S.ID = T.cfgICSSpiffID
			and RT.MarketCode = TG.marketCode
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(TG.StartDate as date) and cast(TG.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and TG.IsActive = 'Y'
			and FI.FilterValueDesc = 'MARKETGROUP'
			and FI.Action = '!='
			)



/******************************************
		CreditType Activation Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'CreditType,'
from #SPIFFTXNs T

where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CREDITTYPE'
			and FI.Action = '!='
		)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
			inner join dbo.tsdICSActivity IA on T.BillingSubsystemID = IA.BillingSubsystemID
				and T.ServiceUniversalID = IA.ServiceUniversalID
				and T.EventType = IA.EventType
				and T.EffectiveCalcDate = IA.EffectiveCalcDate
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CREDITTYPE'
			and FI.Action = '!='
			and FI.FilterValueText = IA.CreditType
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'CreditType,'
from #SPIFFTXNs T

where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CREDITTYPE'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
			inner join dbo.tsdICSActivity IA on T.BillingSubsystemID = IA.BillingSubsystemID
				and T.ServiceUniversalID = IA.ServiceUniversalID
				and T.EventType = IA.EventType
				and T.EffectiveCalcDate = IA.EffectiveCalcDate
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CREDITTYPE'
			and FI.Action = '='
			and FI.FilterValueText = IA.CreditType
			)
			
			
/******************************************
		Account Group Activation Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'AccountGroup,'
--select *
from #SPIFFTXNs T
	inner join tsdICSActivity RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.EventType = T.EventType
		and cast(RT.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'ACCOUNTGROUP'
			and FI.Action = '='
		)
	and not exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
			inner join dbo.cfgICSSpiffAccountGroups TG on FI.FilterValueText = TG.AccountGroupID
		where S.ID = T.cfgICSSpiffID
			and RT.AccountType = TG.AccountType
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(TG.StartDate as date) and cast(TG.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and TG.IsActive = 'Y'
			and FI.FilterValueDesc = 'ACCOUNTGROUP'
			and FI.Action = '='
			)
--order by T.ServiceUniversalID

update T
set T.RuleFiltered = T.RuleFiltered+'AccountGroup,'
from #SPIFFTXNs T
	inner join tsdICSActivity RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.EventType = T.EventType
		and cast(RT.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
where exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'ACCOUNTGROUP'
			and FI.Action = '!='
		)
	and exists(
		select * 
		from cfgICSSpiff S
			inner join cfgICSSpiffFilter F on S.SpiffID = F.SpiffID
			inner join cfgICSSpiffFilterItems FI on F.FilterTableItemID = FI.FilterTableItemID
			inner join dbo.cfgICSSpiffAccountGroups TG on FI.FilterValueText = TG.AccountGroupID
		where S.ID = T.cfgICSSpiffID
			and RT.AccountType = TG.AccountType
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(TG.StartDate as date) and cast(TG.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and TG.IsActive = 'Y'
			and FI.FilterValueDesc = 'ACCOUNTGROUP'
			and FI.Action = '!='
			)

			
----------------------------------------------------------------------------------------





--select * from #SPIFFTXNs where RuleFiltered like  'PlanFeatureLevel%' order by serviceUniversalID

--select COUNT(*) from #SPIFFTXNs


--update #SPIFFTXNs set RuleFiltered = ''

--select BillingSubsystemID, ServiceUniversalID, EffectiveCalcDate, EventType, SalesCode, Event, cfgICSSpiffID, Months 
--from #SPIFFTXNs where RuleFiltered like  'PlanFeatureLevel%'
--except
--select BillingSubsystemID, ServiceUniversalID, EffectiveCalcDate, EventType, SalesCode, Event, cfgICSSpiffID, Months  
--from dbo.UnionOfTrapActivations where RuleDescription = 'TRAP Transaction of PLANFEATURELEVEL Activations'
--except
--select BillingSubsystemID, ServiceUniversalID, EffectiveCalcDate, EventType, SalesCode, Event, cfgICSSpiffID, Months 
--from #SPIFFTXNs where RuleFiltered like  'PlanFeatureLevel%'

------select * from #SPIFFTXNs where ServiceUniversalID = '2301900933' 

--select *
--from #SPIFFTXNs T
--	--inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
--	--	and T.ServiceUniversalID = FA.ServiceUniversalID
--	--	and FA.EventType = 'ACT'
--	--	and Month(FA.EffectiveCalcDate) = Month(T.EffectiveCalcDate)
--	--	and Year(FA.EffectiveCalcDate) = Year(T.EffectiveCalcDate)
--	--inner join cfgICSProductCategory PC on PC.BillingSubsystemID = FA.BillingSubsystemID
--	--	and PC.ProductIDCode = FA.FeatureSOC
--	--	and cast(T.EffectiveCalcDate as DATE) between cast(PC.StartDate as date) and cast(PC.EndDate as date)
--where T.ServiceUniversalID = '101034921'