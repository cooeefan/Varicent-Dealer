/******************************
           Raw Transactions
*******************************/

IF OBJECT_ID('tempdb..#SPIFFFeatureTXNs') is not Null
drop table #SPIFFFeatureTXNs

select T.*, S.AssignmentID, S.ID as cfgICSSpiffPayeeGroupID,S.ID2 as cfgICSSpiffID
     ,CAST('' as varchar(500)) as RuleFiltered
into #SPIFFFeatureTXNs
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
where EVENT in ('FEATURE','PREPAID FEATURE') 
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
           
--select top 10 * from #SPIFFFeatureTXNs
           
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
from #SPIFFFeatureTXNs T
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
from #SPIFFFeatureTXNs T
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
from #SPIFFFeatureTXNs T
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
--select *
from #SPIFFFeatureTXNs T
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
from #SPIFFFeatureTXNs T
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
from #SPIFFFeatureTXNs T
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
from #SPIFFFeatureTXNs T
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
from #SPIFFFeatureTXNs T
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
from #SPIFFFeatureTXNs T
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
from #SPIFFFeatureTXNs T
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
from #SPIFFFeatureTXNs T
	inner join tsdICSFeatureActivation RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.FeatureSOC = T.PlanCode
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
from #SPIFFFeatureTXNs T
	inner join tsdICSFeatureActivation RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.FeatureSOC = T.PlanCode
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
from #SPIFFFeatureTXNs T
	inner join tsdICSFeatureActivation RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.FeatureSOC = T.PlanCode
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
from #SPIFFFeatureTXNs T
	inner join tsdICSFeatureActivation RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.FeatureSOC = T.PlanCode
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
	     	Feature Plan Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'FeaturePlan,'
from #SPIFFFeatureTXNs T
	inner join tsdICSFeatureActivation RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.FeatureSOC = T.PlanCode
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
			and FI.FilterValueDesc = 'FEATUREPLAN'
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
			and FI.FilterValueDesc = 'FEATUREPLAN'
			and FI.Action = '!='
			and FI.FilterValueText = RT.PlanCode
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'FeaturePlan,'
from #SPIFFFeatureTXNs T
	inner join tsdICSFeatureActivation RT on RT.BillingSubsystemID = T.BillingSubsystemID
		and RT.ServiceUniversalID = T.ServiceUniversalID
		and RT.FeatureSOC = T.PlanCode
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
			and FI.FilterValueDesc = 'FEATUREPLAN'
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
			and FI.FilterValueDesc = 'FEATUREPLAN'
			and FI.Action = '='
			and FI.FilterValueText = RT.PlanCode
			)
			

/******************************************
	      PlanFeatureLevel Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'PlanFeatureLevel,'
from #SPIFFFeatureTXNs T
	inner join tsdICSFeatureActivation FA on FA.BillingSubsystemID = T.BillingSubsystemID
		and FA.ServiceUniversalID = T.ServiceUniversalID
		and FA.FeatureSOC = T.PlanCode
		and FA.EventType = T.EventType
		and cast(FA.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
	inner join cfgICSProductCategory PC on PC.BillingSubsystemID = FA.BillingSubsystemID
		and PC.ProductIDCode = FA.PlanCode
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
from #SPIFFFeatureTXNs T
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
			inner join tsdICSFeatureActivation FA on FA.PlanCode = PC.ProductIDCode
		where S.ID = T.cfgICSSpiffID
			and T.BillingSubsystemID = FA.BillingSubsystemID
			and T.BillingSubsystemID = PC.BillingSubsystemID
			and T.ServiceUniversalID = FA.ServiceUniversalID
			and PC.ProductIDCode = FA.PlanCode
			and FA.EventType = T.EventType
			and cast(FA.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
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
from #SPIFFFeatureTXNs T
	left join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
		and FA.ServiceUniversalID = T.ServiceUniversalID
		and FA.FeatureSOC = T.PlanCode
		and FA.EventType = T.EventType
		and cast(FA.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
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


--select * from #SPIFFFeatureTXNs where RuleFiltered like  'PlanFeatureLevel%' order by serviceUniversalID

--select COUNT(*) from #SPIFFFeatureTXNs


--update #SPIFFFeatureTXNs set RuleFiltered = ''

--select BillingSubsystemID, ServiceUniversalID, EffectiveCalcDate, EventType, SalesCode, Event, cfgICSSpiffID, Months 
--from #SPIFFFeatureTXNs where RuleFiltered like  'PlanFeatureLevel%'
--except
--select BillingSubsystemID, ServiceUniversalID, EffectiveCalcDate, EventType, SalesCode, Event, cfgICSSpiffID, Months  
--from dbo.UnionOfTrapActivations where RuleDescription = 'TRAP Transaction of PLANFEATURELEVEL Activations'
--except
--select BillingSubsystemID, ServiceUniversalID, EffectiveCalcDate, EventType, SalesCode, Event, cfgICSSpiffID, Months 
--from #SPIFFFeatureTXNs where RuleFiltered like  'PlanFeatureLevel%'

--select * from #SPIFFFeatureTXNs where ServiceUniversalID = '2292000318' 
--select * from tsdICSFeatureActivation where ServiceUniversalID = '2292000318' 
--select * from UnionOfTrapActivations where ServiceUniversalID = '2292000318' 

--select *
--from #SPIFFFeatureTXNs T
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
		HOTI Activation Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'HOTI Activation,'
from #SPIFFFeatureTXNs T
	inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
		and FA.ServiceUniversalID = T.ServiceUniversalID
		and FA.FeatureSOC = T.FeatureSOC
		and FA.EventType = T.EventType
		and cast(FA.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
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
			and FI.FilterValueText = FA.HOTI
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'HOTI Activation,'
from #SPIFFFeatureTXNs T
	inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
		and FA.ServiceUniversalID = T.ServiceUniversalID
		and FA.FeatureSOC = T.FeatureSOC
		and FA.EventType = T.EventType
		and cast(FA.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
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
			and FI.FilterValueText = FA.HOTI
			)
			

/******************************************
		Credit Class Activation Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'CreditClass Activation,'
from #SPIFFFeatureTXNs T
	inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
		and FA.ServiceUniversalID = T.ServiceUniversalID
		and FA.FeatureSOC = T.FeatureSOC
		and FA.EventType = T.EventType
		and cast(FA.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
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
			and FI.FilterValueText = FA.CreditClass
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'CreditClass Activation,'
from #SPIFFFeatureTXNs T
	inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
		and FA.ServiceUniversalID = T.ServiceUniversalID
		and FA.FeatureSOC = T.FeatureSOC
		and FA.EventType = T.EventType
		and cast(FA.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
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
			and FI.FilterValueText = FA.CreditClass
			)

/******************************************
		Port Type Activation Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'PortType Activation,'
from #SPIFFFeatureTXNs T
	inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
		and FA.ServiceUniversalID = T.ServiceUniversalID
		and FA.FeatureSOC = T.FeatureSOC
		and FA.EventType = T.EventType
		and cast(FA.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
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
			and FI.FilterValueText = FA.PortType
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'PortType Activation,'
from #SPIFFFeatureTXNs T
	inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
		and FA.ServiceUniversalID = T.ServiceUniversalID
		and FA.FeatureSOC = T.FeatureSOC
		and FA.EventType = T.EventType
		and cast(FA.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
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
			and FI.FilterValueText = FA.PortType
			)



/******************************************
		Feature in Month Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'Feature in Month,'
from #SPIFFFeatureTXNs T
	inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
		and FA.ServiceUniversalID = T.ServiceUniversalID
		and FA.FeatureSOC = T.FeatureSOC
		and FA.EventType = T.EventType
		and cast(FA.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
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
			and FI.FilterValueDesc = 'FEATUREINMONTHOFSUBSCRIBERACT'
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
			and FI.FilterValueDesc = 'FEATUREINMONTHOFSUBSCRIBERACT'
			and FI.Action = '='
			and FI.FilterValueText = 'Y'
			and Month(FA.BeginServiceDate) = Month(EffectiveCalcDate)
			and Year(FA.BeginServiceDate) = Year(EffectiveCalcDate)
			)
			

/******************************************
		Feature Days To Act Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'FeatureDaysToAct,'
from #SPIFFFeatureTXNs T INNER JOIN dbo.cfgICSSpiff CIS ON CIS.ID = T.cfgICSSpiffID

INNER JOIN dbo.cfgICSSpiffFilter SF ON SF.SpiffID = CIS.SpiffID
AND SF.IsActive = 'Y'
AND CAST(T.EffectiveCalcDate AS DATE) BETWEEN CAST(SF.StartDate AS DATE) AND CAST(SF.EndDate AS DATE) 

INNER JOIN dbo.cfgICSSpiffFilterItems FI ON FI.FilterTableItemID = SF.FilterTableItemID
AND CAST(T.EffectiveCalcDate AS DATE) BETWEEN CAST(FI.StartDate AS DATE) AND CAST(FI.EndDate AS DATE) 
AND FI.FilterValueDesc = 'FEATUREDAYSTOACTIVATION'

LEFT OUTER JOIN dbo.tsdICSFeatureActivation TIA ON T.BillingSubSystemID = TIA.BillingSubsystemID
AND T.ServiceUniversalID = TIA.ServiceUniversalID
AND T.FeatureSOC = TIA.FeatureSOC
AND T.EventType = TIA.EventType
AND CAST(T.EffectiveCalcDate AS DATE) = CAST(TIA.EffectiveCalcDate AS DATE)
AND
(
   CASE WHEN FI.Action = '=' THEN DATEDIFF(day, CAST(TIA.BegServDate AS DATE), CAST(T.EffectiveCalcDate AS DATE)) END = CAST(FI.FilterValueNum AS FLOAT) 
OR CASE WHEN FI.Action = '<=' THEN DATEDIFF(day, CAST(TIA.BegServDate AS DATE), CAST(T.EffectiveCalcDate AS DATE)) END <= CAST(FI.FilterValueNum AS FLOAT) 
OR CASE WHEN FI.Action = '>=' THEN DATEDIFF(day, CAST(TIA.BegServDate AS DATE), CAST(T.EffectiveCalcDate AS DATE)) END >= CAST(FI.FilterValueNum AS FLOAT) 
OR CASE WHEN FI.Action = '<' THEN DATEDIFF(day, CAST(TIA.BegServDate AS DATE), CAST(T.EffectiveCalcDate AS DATE)) END < CAST(FI.FilterValueNum AS FLOAT) 
OR CASE WHEN FI.Action = '>' THEN DATEDIFF(day, CAST(TIA.BegServDate AS DATE), CAST(T.EffectiveCalcDate AS DATE)) END > CAST(FI.FilterValueNum AS FLOAT) 
)

WHERE TIA.BillingSubsystemID IS NULL


/******************************************
		Location Market Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'LocationMarket,'
from #SPIFFFeatureTXNs T

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
from #SPIFFFeatureTXNs T

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
		Market Group Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'MarketGroup,'
from #SPIFFFeatureTXNs T

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
			inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
				and FA.ServiceUniversalID = T.ServiceUniversalID
				and FA.FeatureSOC = T.FeatureSOC
				and FA.EventType = T.EventType
				and cast(FA.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
			inner join dbo.cfgICSSpiffMarketGroups MG on IA.MarketCode = MG.MarketCode
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(MG.StartDate as date) and cast(MG.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and MG.IsActive = 'Y'
			and T.ServiceUniversalID = IA.ServiceUniversalID
			and T.EventType = IA.EventType
			and FI.FilterValueDesc = 'MARKETGROUP'
			and FI.Action = '='
			and FI.FilterValueText = MG.MarketGroupID
			)

update T
set T.RuleFiltered = T.RuleFiltered+'MarketGroup,'
from #SPIFFFeatureTXNs T

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
			inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
				and FA.ServiceUniversalID = T.ServiceUniversalID
				and FA.FeatureSOC = T.FeatureSOC
				and FA.EventType = T.EventType
				and cast(FA.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
			inner join dbo.cfgICSSpiffMarketGroups MG on IA.MarketCode = MG.MarketCode
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(MG.StartDate as date) and cast(MG.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and MG.IsActive = 'Y'
			and T.ServiceUniversalID = IA.ServiceUniversalID
			and T.EventType = IA.EventType
			and FI.FilterValueDesc = 'MARKETGROUP'
			and FI.Action = '!='
			and FI.FilterValueText = MG.MarketGroupID
			)



/******************************************
		CreditType Activation Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'CreditType,'
from #SPIFFFeatureTXNs T

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
			inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
				and FA.ServiceUniversalID = T.ServiceUniversalID
				and FA.FeatureSOC = T.FeatureSOC
				and FA.EventType = T.EventType
				and cast(FA.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CREDITTYPE'
			and FI.Action = '!='
			and FI.FilterValueText = FA.CreditType
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'CreditType,'
from #SPIFFFeatureTXNs T

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
			inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
				and FA.ServiceUniversalID = T.ServiceUniversalID
				and FA.FeatureSOC = T.FeatureSOC
				and FA.EventType = T.EventType
				and cast(FA.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'CREDITTYPE'
			and FI.Action = '='
			and FI.FilterValueText = FA.CreditType
			)
			
			
/******************************************
		Account Group Activation Filter
*******************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'AccountGroup,'
from #SPIFFFeatureTXNs T

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
			inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
				and FA.ServiceUniversalID = T.ServiceUniversalID
				and FA.FeatureSOC = T.FeatureSOC
				and FA.EventType = T.EventType
				and cast(FA.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
			inner join cfgICSSpiffAccountGroups IAG on IA.AccountTypeID = IAG.AccountType
				and IAG.AccountSubType = IA.AccountSubTypeID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(IAG.StartDate as date) and cast(IAG.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'ACCOUNTGROUP'
			and FI.Action = '!='
			and FI.FilterValueText = IAG.AccountGroupID
			)
	
update T
set T.RuleFiltered = T.RuleFiltered+'AccountGroup,'

from #SPIFFFeatureTXNs T

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
			inner join dbo.tsdICSFeatureActivation FA on T.BillingSubsystemID = FA.BillingSubsystemID
				and FA.ServiceUniversalID = T.ServiceUniversalID
				and FA.FeatureSOC = T.FeatureSOC
				and FA.EventType = T.EventType
				and cast(FA.EffectiveCalcDate as date) = cast(T.EffectiveCalcDate as date)
			inner join cfgICSSpiffAccountGroups IAG on IA.AccountTypeID = IAG.AccountType
				and IAG.AccountSubType = IA.AccountSubTypeID
		where S.ID = T.cfgICSSpiffID
			and cast(T.EffectiveCalcDate as date) between cast(S.StartDate as date) and cast(S.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(F.StartDate as date) and cast(F.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(FI.StartDate as date) and cast(FI.EndDate as date)
			and cast(T.EffectiveCalcDate as date) between cast(IAG.StartDate as date) and cast(IAG.EndDate as date)
			and S.IsActive = 'Y'
			and F.IsActive = 'Y'
			and FI.IsActive = 'Y'
			and FI.FilterValueDesc = 'ACCOUNTGROUP'
			and FI.Action = '='
			and FI.FilterValueText = IAG.AccountGroupID
			)

	
/********************************************
     Feature and Upgrade in Same Month
*********************************************/

update T
set T.RuleFiltered = T.RuleFiltered+'FEATUREINMONTHOFSUBSCRIBERACTUPGRADE,'
from #SPIFFFeatureTXNs T INNER JOIN dbo.cfgICSSpiff CIS ON CIS.ID = T.cfgICSSpiffID

INNER JOIN dbo.cfgICSSpiffFilter SF ON SF.SpiffID = CIS.SpiffID
AND SF.IsActive = 'Y'
AND CAST(T.EffectiveCalcDate AS DATE) BETWEEN CAST(SF.StartDate AS DATE) AND CAST(SF.EndDate AS DATE) 

INNER JOIN dbo.cfgICSSpiffFilterItems FI ON FI.FilterTableItemID = SF.FilterTableItemID
AND CAST(T.EffectiveCalcDate AS DATE) BETWEEN CAST(FI.StartDate AS DATE) AND CAST(FI.EndDate AS DATE) 
AND FI.Action = '='
AND FI.FilterValueDesc = 'FEATUREINMONTHOFSUBSCRIBERACTUPGRADE'

LEFT OUTER JOIN dbo.tsdICSFeatureActivation TIA ON T.BillingSubSystemID = TIA.BillingSubsystemID
AND T.ServiceUniversalID = TIA.ServiceUniversalID
AND T.FeatureSOC = TIA.FeatureSOC
AND T.EventType = TIA.EventType
AND CAST(T.EffectiveCalcDate AS DATE) = CAST(TIA.EffectiveCalcDate AS DATE)

LEFT JOIN dbo.tsdICSUpgrades IU ON T.ServiceUniversalID = IU.ServiceUniversalID
AND T.BillingSubsystemID = IU.BillingSubSystemID

LEFT JOIN dbo.ICSOOM1240UpgradesWithOOMCap OOM ON T.Months = OOM.Months
AND T.EventType = OOM.EventType
AND IU.OrderDetailID = OOM.ServiceUniversalID   -- ServiceUniversalID is same as OrderDetailID 
AND IU.BillingSubSystemID = OOM.BillingSubsystemID
AND CAST(IU.EffectiveCalcDate AS DATE) = CAST(OOM.EffectiveCalcDate AS DATE)

WHERE (FI.FilterValueText = 'Y' AND OOM.BillingSubsystemID IS NULL)
   OR (FI.FilterValueText = 'N' AND OOM.BillingSubsystemID IS NOT NULL)			