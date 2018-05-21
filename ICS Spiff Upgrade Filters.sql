/******************************
		Raw Transactions
*******************************/

IF OBJECT_ID('tempdb..#SPIFFUpgradeTXNs') is not Null
drop table #SPIFFUpgradeTXNs

select T.*, S.AssignmentID, S.ID as cfgICSSpiffPayeeGroupID,S.ID2 as cfgICSSpiffID
	,CAST('' as varchar(500)) as RuleFiltered
into #SPIFFUpgradeTXNs
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
		
--select * from #SPIFFUpgradeTXNs where ServiceUniversalID = '119773289'
		
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
from #SPIFFUpgradeTXNs T
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
from #SPIFFUpgradeTXNs T
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
from #SPIFFUpgradeTXNs T
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
from #SPIFFUpgradeTXNs T
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
from #SPIFFUpgradeTXNs T
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
from #SPIFFUpgradeTXNs T
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
from #SPIFFUpgradeTXNs T
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
from #SPIFFUpgradeTXNs T
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
from #SPIFFUpgradeTXNs T
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
from #SPIFFUpgradeTXNs T
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
--select *
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
		HOTI Upgrade Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'HOTI Upgrade,'
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
			and FI.FilterValueText = RT.HOTI
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'HOTI Upgrade,'
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
			and FI.FilterValueText = RT.HOTI
			)

/******************************************
		Credit Class Upgrade Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'CreditClass Upgrade,'
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
			and FI.FilterValueText = RT.CreditClass
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'CreditClass Upgrade,'
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
			and FI.FilterValueText = RT.CreditClass
			)


/******************************************
		MonthsToUpgrade Filter
*******************************************/

IF OBJECT_ID('tempdb..#MonthsToUpgradeTable') is not Null
drop table #MonthsToUpgradeTable

select T.*, RT.LastUpgradeDate
	,case when (RT.LastUpgradeDate is null OR RT.LastUpgradeDate = '') then 0
	 else DATEDIFF(dd,RT.LastUpgradeDate ,RT.EffectiveCalcDate) end as DaysToUpgrade
into #MonthsToUpgradeTable
from #SPIFFUpgradeTXNs T
	left join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
		and RT.EventType = T.EventType
		and cast(RT.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
--where T.ServiceUniversalID = '119773289'

update T1
set T1.RuleFiltered = T1.RuleFiltered+'MonthsToUpgrade,'
from #SPIFFUpgradeTXNs T1
left join (
	----- Pass Through TXNs------
	select T.*
	from #SPIFFUpgradeTXNs T
		inner join #MonthsToUpgradeTable DTU on T.ServiceUniversalID = DTU.ServiceUniversalID
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
	where FI.FilterValueDesc = 'MONTHSTOUPGRADE'
		and ( FI.Action = '<' and cast(DTU.DaysToUpgrade as float) < cast(FI.FilterValueNum as float)
			or FI.Action = '<=' and cast(DTU.DaysToUpgrade as float) <= cast(FI.FilterValueNum as float)
			or FI.Action = '=' and cast(DTU.DaysToUpgrade as float) = cast(FI.FilterValueNum as float)
			or FI.Action = '>=' and cast(DTU.DaysToUpgrade as float) >= cast(FI.FilterValueNum as float)
			or FI.Action = '>' and cast(DTU.DaysToUpgrade as float) > cast(FI.FilterValueNum as float)
			)
	union 
	select T.*
	from #SPIFFUpgradeTXNs T
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
				and FI.FilterValueDesc = 'MONTHSTOUPGRADE'
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
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
			and FI.FilterValueText = RT.TAC
			)

--select *	
update T
set T.RuleFiltered = T.RuleFiltered+'TAC,'
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
			and FI.FilterValueText = RT.TAC
			)


/******************************************
		Location Market Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'LocationMarket,'
from #SPIFFUpgradeTXNs T
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
from #SPIFFUpgradeTXNs T
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
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
			and FI.FilterValueDesc = 'COBINDICATOR'
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
			and FI.FilterValueDesc = 'COBINDICATOR'
			and FI.Action = '='
			and FI.FilterValueText = RT.COBIndicator
			)

update T
set T.RuleFiltered = T.RuleFiltered+'COBIndicator,'
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
			and FI.FilterValueDesc = 'COBINDICATOR'
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
			and FI.FilterValueDesc = 'COBINDICATOR'
			and FI.Action = '!='
			and FI.FilterValueText = RT.COBIndicator
			)
			

/******************************************
		TAC Group Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'TACGroup,'
--select *
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
--order by T.ServiceUniversalID

update T
set T.RuleFiltered = T.RuleFiltered+'TACGroup,'
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
--select *
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
--order by T.ServiceUniversalID

update T
set T.RuleFiltered = T.RuleFiltered+'MarketGroup,'
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
		Credit Type Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'CreditType,'
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
			and FI.FilterValueDesc = 'CREDITTYPE'
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
			and FI.FilterValueDesc = 'CREDITTYPE'
			and FI.Action = '='
			and FI.FilterValueText = RT.CreditType
			)

update T
set T.RuleFiltered = T.RuleFiltered+'CreditType,'
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
			and FI.FilterValueDesc = 'CREDITTYPE'
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
			and FI.FilterValueDesc = 'CREDITTYPE'
			and FI.Action = '!='
			and FI.FilterValueText = RT.CreditType
			)
			

/******************************************
		Account Group Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'AccountGroup,'
--select *
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
	
	
/******************************************
		    Jump Filter
*******************************************/		
			
update T
set T.RuleFiltered = T.RuleFiltered+'Jump,'
--select * 
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
			and FI.FilterValueDesc = 'JUMPINDICATOR'
			and FI.Action = '='
		)
		--and T.cfgICSSpiffID = '4'
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
			and FI.FilterValueDesc = 'JUMPINDICATOR'
			and FI.Action = '='
			and FI.FilterValueText = RT.JumpIndicator
			)

update T
set T.RuleFiltered = T.RuleFiltered+'Jump,'
from #SPIFFUpgradeTXNs T
	inner join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
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
			and FI.FilterValueDesc = 'JUMPINDICATOR'
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
			and FI.FilterValueDesc = 'JUMPINDICATOR'
			and FI.Action = '!='
			and FI.FilterValueText = RT.JumpIndicator
			)
		----- Difference is becuase for upgrade Varicent didn't pull out CAP validated records in SPT4000

/******************************************
		Upgrade Tenure Filter
*******************************************/

IF OBJECT_ID('tempdb..#UpgradeTenureTable') is not Null
drop table #UpgradeTenureTable

select T.*, RT.LastUpgradeDate
	,case when (RT.LastUpgradeDate is null OR RT.LastUpgradeDate = '' OR CAST(RT.LastUpgradeDate AS date)<'2001-01-01') 
		then DATEDIFF(MM,'2011-01-01' ,RT.EffectiveCalcDate)
		--when CAST(RT.LastUpgradeDate AS date)<'2001-01-01' then DATEDIFF(MM,'2001-01-01' ,RT.EffectiveCalcDate)
	 else DATEDIFF(MM,RT.LastUpgradeDate ,RT.EffectiveCalcDate) end as TenureMonths
into #UpgradeTenureTable
from #SPIFFUpgradeTXNs T
	left join tsdICSUpgrades RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.OrderDetailID = T.ServiceUniversalID
		and RT.EventType = T.EventType
		and cast(RT.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
--where T.ServiceUniversalID = '119773289'
--order by T.ServiceUniversalID

update T1
set T1.RuleFiltered = T1.RuleFiltered+'UpgradeTenure,'
from #SPIFFUpgradeTXNs T1
left join (
	----- Pass Through TXNs------
	select T.*
	from #SPIFFUpgradeTXNs T
		inner join #UpgradeTenureTable DTU on T.ServiceUniversalID = DTU.ServiceUniversalID
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
	where FI.FilterValueDesc = 'UPGRADETENURE'
		and ( FI.Action = '<' and cast(DTU.TenureMonths as float) < cast(FI.FilterValueNum as float)
			or FI.Action = '<=' and cast(DTU.TenureMonths as float) <= cast(FI.FilterValueNum as float)
			or FI.Action = '=' and cast(DTU.TenureMonths as float) = cast(FI.FilterValueNum as float)
			or FI.Action = '>=' and cast(DTU.TenureMonths as float) >= cast(FI.FilterValueNum as float)
			or FI.Action = '>' and cast(DTU.TenureMonths as float) > cast(FI.FilterValueNum as float)
			)
	union 
	select T.*
	from #SPIFFUpgradeTXNs T
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
				and FI.FilterValueDesc = 'UPGRADETENURE'
				)
	) X on T1.BillingSubsystemID = X.BillingSubsystemID
		and T1.ServiceUniversalID = X.ServiceUniversalID
		and T1.EventType = X.EventType
		and cast(T1.EffectiveCalcDate as date) = cast(X.EffectiveCalcDate as date)
where X.ServiceUniversalID is null




----------------------------------------------------------------------------------------------------------------------------
			
			

--update #SPIFFUpgradeTXNs set RuleFiltered = '' where RuleFiltered like  'TACGroup%'

--select * from #SPIFFUpgradeTXNs where RuleFiltered like  'TACGroup%'

--select BillingSubsystemID, ServiceUniversalID, EffectiveCalcDate, EventType, SalesCode, Event, cfgICSSpiffID, Months 
--from #SPIFFUpgradeTXNs where RuleFiltered like  'ContractTerm%'
--except
--select BillingSubsystemID, ServiceUniversalID, EffectiveCalcDate, EventType, SalesCode, Event, cfgICSSpiffID, Months  
--from dbo.UnionOfTrapActivations where RuleDescription = 'TRAP Transaction of PLANFEATURELEVEL Activations'
--except
--select BillingSubsystemID, ServiceUniversalID, EffectiveCalcDate, EventType, SalesCode, Event, cfgICSSpiffID, Months 
--from #SPIFFTXNs where RuleFiltered like  'PlanFeatureLevel%'