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
*                    Feature Activation                      *
*          #FeatureActivation has all eligible Act           *
**************************************************************/
IF OBJECT_ID('tempdb..#FeatureActivation') is not Null
drop table #FeatureActivation

select * 
into #FeatureActivation
from (
-----Ban Level Feature-----
select BillingSubsystemID,ServiceUniversalID,FeatureSOC,EventType,EffectiveCalcDate,FeatureActivityKey,ProfileID,MarketCode,MSISDN,NPANXX,ActivationDate,DeactivationDate
	,MRC,BAN,PlanCode,DealerCode,AccountSubtypeID,EffectiveIssueDate,BTVIndicator,ReducedMRC,SIM,IMEI,SubscriberName,AccountType,CreditType,PortType,PICarrier,ContractTerm
	,BegServDate,HOTI,AddALineSOC,CreditClass,IsValid,SameMonth,SourceHOTI,DealerName,MasterDealerCode,CurrentMonth,ContractHolderID,ContractID,ContractHolderChannel
	,ContractChannel,ChannelType,AgreementType,UDFMarketCode,SamsonMktName,InMarketFlag,'BAN' as BANFlag
from (
	select X.*, ROW_NUMBER() over (Partition by X.Ban,X.FeatureSOC order by cast(X.EffectiveCalcDate as date) desc) as BANOrder
	from (
		select F.*, D.DealerName,D.MasterDealerCode,D.CurrentMonth,D.ContractHolderID,D.ContractID,D.ContractHolderChannel,D.ContractChannel,D.ChannelType,D.AgreementType
				, M.MarketCode as UDFMarketCode,M.SamsonMktName
				, Case when M.ContractID is not null then 1 else 0 end as InMarketFlag
				,ROW_NUMBER() over (partition by F.BillingSubsystemID,F.ServiceUniversalID, F.FeatureSOC,F.EventType, F.EffectiveCalcDate order by case when M.MarketCode like '%[0-9]' then 1 else 2 end ) as MKTOrder 
		from tsdICSFeatureActivation F
			left join tsdICSManualExcludeFeatures E on F.ServiceUniversalID = E.ServiceUniversalID
				and F.EventType = E.EventType 
				and F.EffectiveCalcDate = E.EffectiveCalcDate
				and F.FeatureSOC = E.FeatureSOC
			left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = F.AccountSubtypeID and A.AccountType = F.AccountType)
			inner join cfgICSProductCategory B on B.BillingSubsystemID = F.BillingSubsystemID and B.ProductIDCode = F.FeatureSOC
				and B.Level = 'BAN LEVEL FEATURE SOC'
				and cast(F.EffectiveCalcDate as date) between cast(B.StartDate as date) and cast(B.EndDate as date)
			inner join #DealerMonthlyEligibility D on D.SalesCode = F.DealerCode
				and CAST(F.EffectiveCalcDate as date) between D.MonthStartDate and D.MonthEndDate 
			inner join #ProductEligibility P on F.FeatureSOC = P.ProductIDCode
				and F.BillingSubsystemID = P.BillingSubsystemID
				and CAST(F.EffectiveCalcDate as date) between P.StartDate and P.EndDate
			left join #MarketEligibility M on D.ContractID = M.ContractID
				and ((ISNULL(M.NPANXX,'')<>'' and F.NPANXX = M.NPANXX) or (ISNULL(M.NPANXX,'')='' and F.MarketCode = M.SamsonMktName))
				and CAST(F.EffectiveCalcDate as date) between M.StartDate and M.EndDate
			left join cfgICSHistoricalBANLevelFeatures HB on F.BAN = HB.BAN
				and F.FeatureSOC = HB.FeatureSOC
		where E.ServiceUniversalID is null 
			and F.IsValid = '1.00'
			and (F.EventType = 'ACT' and F.SameMonth = 'N' or F.EventType = 'REACT' and F.SameMonth = 'Y')
			and A.StartDate is null
			and HB.BAN is null 
		) X
	where X.MKTOrder = 1
	) Y
where Y.BANOrder = 1

-----Non-Ban Feature-----
union all
select BillingSubsystemID,ServiceUniversalID,FeatureSOC,EventType,EffectiveCalcDate,FeatureActivityKey,ProfileID,MarketCode,MSISDN,NPANXX,ActivationDate,DeactivationDate
	,MRC,BAN,PlanCode,DealerCode,AccountSubtypeID,EffectiveIssueDate,BTVIndicator,ReducedMRC,SIM,IMEI,SubscriberName,AccountType,CreditType,PortType,PICarrier,ContractTerm
	,BegServDate,HOTI,AddALineSOC,CreditClass,IsValid,SameMonth,SourceHOTI,DealerName,MasterDealerCode,CurrentMonth,ContractHolderID,ContractID,ContractHolderChannel
	,ContractChannel,ChannelType,AgreementType,UDFMarketCode,SamsonMktName,InMarketFlag,'Non-BAN' as BANFlag
from (
	select F.*, D.DealerName,D.MasterDealerCode,D.CurrentMonth,D.ContractHolderID,D.ContractID,D.ContractHolderChannel,D.ContractChannel,D.ChannelType,D.AgreementType
		, M.MarketCode as UDFMarketCode,M.SamsonMktName
		, Case when M.ContractID is not null then 1 else 0 end as InMarketFlag
		,ROW_NUMBER() over (partition by F.BillingSubsystemID,F.ServiceUniversalID, F.FeatureSOC,F.EventType, F.EffectiveCalcDate order by case when M.MarketCode like '%[0-9]' then 1 else 2 end ) as MKTOrder 
	from tsdICSFeatureActivation F
		left join tsdICSManualExcludeFeatures E on F.ServiceUniversalID = E.ServiceUniversalID
			and F.EventType = E.EventType 
			and F.EffectiveCalcDate = E.EffectiveCalcDate
			and F.FeatureSOC = E.FeatureSOC
		left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = F.AccountSubtypeID and A.AccountType = F.AccountType)
		left join cfgICSProductCategory B on B.BillingSubsystemID = F.BillingSubsystemID and B.ProductIDCode = F.FeatureSOC
			and B.Level = 'BAN LEVEL FEATURE SOC'
			and cast(F.EffectiveCalcDate as date) between cast(B.StartDate as date) and cast(B.EndDate as date)
		inner join #DealerMonthlyEligibility D on D.SalesCode = F.DealerCode
			and CAST(F.EffectiveCalcDate as date) between D.MonthStartDate and D.MonthEndDate 
		inner join #ProductEligibility P on F.FeatureSOC = P.ProductIDCode
			and F.BillingSubsystemID = P.BillingSubsystemID
			and CAST(F.EffectiveCalcDate as date) between P.StartDate and P.EndDate
		left join #MarketEligibility M on D.ContractID = M.ContractID
			and ((ISNULL(M.NPANXX,'')<>'' and F.NPANXX = M.NPANXX) or (ISNULL(M.NPANXX,'')='' and F.MarketCode = M.SamsonMktName))
			and CAST(F.EffectiveCalcDate as date) between M.StartDate and M.EndDate
	where E.ServiceUniversalID is null 
		and F.IsValid = '1.00'
		and (F.EventType = 'ACT' and F.SameMonth = 'N' or F.EventType = 'REACT' and F.SameMonth = 'Y')
		and A.StartDate is null
		and B.ProductIDCode is null
	) Z
where Z.MKTOrder = 1
) W

--Be cautious, In order to pull out only one TXN for Ban level feature, Varicent partition by Ban,FeatureSOC and CurrentMonth, not sure why we need the last condition

--select * from #FeatureActivation where CurrentMonth = '2013, Month 07'  and MasterDealerCode = '2680270' and contractID = '1-18P83B'
--select * from #FeatureActivation where ServiceUniversalID = '86268539'
--select * from #ProductEligibility where productidcode = 'C6HDATA'
--select * from cfgICSProductCategory where ProductIDCode = 'C6HDATA'


/******************************************************************************
*          Activity Feature Deactivation&Non-Same month Reactivation          *
*    #ActivityFeatureDeactReact has all eligible Act&Non-SameMonth React      *
******************************************************************************/

IF OBJECT_ID('tempdb..#EligibleTxnForReactDeact') is not Null
drop table #EligibleTxnForReactDeact

select * 
into #EligibleTxnForReactDeact
from (
	--select distinct A.ServiceUniversalID,A.EventType,A.DealerCode,A.EffectiveCalcDate
	--from #FeatureActivation A
	--union 
	select distinct B.ServiceUniversalID,B.EventType,B.FeatureSOC,B.SalesCode,B.EffectiveCalcDate
	from dbo.archICSPaidFeatureActivations B
	) X

IF OBJECT_ID('tempdb..#EligibleFeatureReactDeactWT1') is not Null
drop table #EligibleFeatureReactDeactWT1

select X.*, D.DealerName,D.MasterDealerCode,D.CurrentMonth,D.ContractHolderID,D.ContractID,D.ContractHolderChannel,D.ContractChannel,D.ChannelType,D.AgreementType
		, M.MarketCode as UDFMarketCode,M.SamsonMktName
		, Case when M.ContractID is not null then 1 else 0 end as InMarketFlag
	,ROW_NUMBER() over (partition by X.BillingSubsystemID,X.ServiceUniversalID, X.FeatureSOC,X.EventType, X.EffectiveCalcDate order by case when M.MarketCode like '%[0-9]' then 1 else 2 end ) as MKTOrder 
into #EligibleFeatureReactDeactWT1
from (
	-----Non Same Month Reactivation-----
	select T.*, Act.SalesCode as SubscriberSalesCode,Act.EffectiveCalcDate as SubscriberActDate,Deact.EffectiveCalcDate as  SubscriberDeactDate
	from tsdICSFeatureActivation T
		left join tsdICSManualExcludeFeatures E on T.ServiceUniversalID = E.ServiceUniversalID
			and T.EventType = E.EventType
			and T.EffectiveCalcDate = E.EffectiveCalcDate
			and T.FeatureSOC = E.FeatureSOC
		left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubTypeID and A.AccountType = T.AccountType)
		inner join #EligibleTxnForReactDeact Act on T.ServiceUniversalID = Act.ServiceUniversalID
			and Act.FeatureSOC = T.FeatureSOC
			and Act.EventType in ('ACT','REACT') 
		inner join #EligibleTxnForReactDeact Deact on T.ServiceUniversalID = Deact.ServiceUniversalID 
			and Deact.FeatureSOC = T.FeatureSOC
			and Deact.EventType = 'DEACT' 
	where E.ServiceUniversalID is null
		and T.EventType = 'REACT' and isnull(SameMonth,'N/A') <> 'Y'
		and A.StartDate is null
	-----Deactivation-----
	union
	select T.*, Act.SalesCode as SubscriberSalesCode, Act.EffectiveCalcDate as SubscriberActDate,'' as SubscriberDeactDate
	from tsdICSFeatureActivation T
		left join tsdICSManualExcludeFeatures E on T.ServiceUniversalID = E.ServiceUniversalID
			and T.EventType = E.EventType
			and T.EffectiveCalcDate = E.EffectiveCalcDate
		left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubTypeID and A.AccountType = T.AccountType)
		inner join #EligibleTxnForReactDeact Act on T.ServiceUniversalID = Act.ServiceUniversalID 
			and Act.FeatureSOC = T.FeatureSOC
			and Act.EventType in ('ACT','REACT')  and cast(T.EffectiveCalcDate as date)>= cast(Act.EffectiveCalcDate as date)
	where E.ServiceUniversalID is null
		and T.EventType = 'DEACT' and isnull(SameMonth,'N/A') <> 'Y'
		and A.StartDate is null
		--and T.ServiceUniversalID = '2305497747'
		) X
	inner join #DealerMonthlyEligibility D on D.SalesCode = X.SubscriberSalesCode
		and CAST(X.SubscriberActDate as date) between D.MonthStartDate and D.MonthEndDate 
	inner join #ProductEligibility P on X.FeatureSOC = P.ProductIDCode
		and X.BillingSubsystemID = P.BillingSubsystemID
		and CAST(X.SubscriberActDate as date) between P.StartDate and P.EndDate
	left join #MarketEligibility M on D.ContractID = M.ContractID
		and ((ISNULL(M.NPANXX,'')<>'' and X.NPANXX = M.NPANXX) or (ISNULL(M.NPANXX,'')='' and X.MarketCode = M.SamsonMktName))
		and CAST(X.SubscriberActDate as date) between M.StartDate and M.EndDate
where X.IsValid = '1.00'

--select * from #EligibleFeatureReactDeactWT1 where MKTOrder = 1 and cast(EffectiveCalcDate as date) between '2013-07-01' and '2013-07-31'

IF OBJECT_ID('tempdb..#EligibleFeatureReactDeactWT2') is not Null
drop table #EligibleFeatureReactDeactWT2

select DR.*
	,P.HighLevelChannel as CRHighLevelChannel,P.AgreementType as CRAgreementType,P.MasterDealerCode as CRMasterDealerCode,P.ContractID as CRContractID,P.ValueText as CRLevel
into #EligibleFeatureReactDeactWT2
from #EligibleFeatureReactDeactWT1 DR
	left join cfgICSContractParams P on P.Name = 'CHARGEBACKLEVEL'
		and P.HighLevelChannel = 'ALL' and P.AgreementType = 'ALL' and P.MasterDealerCode = 'ALL' and P.ContractID = 'ALL'
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
where DR.MKTOrder = 1

-----Begin to apply the level by sequence, Contract > MasterDealer > AgreementType > HighLevelChannel

update DR 
set DR.CRLevel = P.ValueText, DR.CRHighLevelChannel = P.HighLevelChannel
from #EligibleFeatureReactDeactWT2 DR
	inner join cfgICSContractParams P on P.Name = 'CHARGEBACKLEVEL'
		and DR.ContractHolderChannel = P.HighLevelChannel
		and P.AgreementType = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		
update DR 
set DR.CRLevel = P.ValueText, DR.CRHighLevelChannel = P.HighLevelChannel,DR.CRAgreementType = P.AgreementType
from #EligibleFeatureReactDeactWT2 DR
	inner join cfgICSContractParams P on P.Name = 'CHARGEBACKLEVEL'
		and DR.ContractHolderChannel = P.HighLevelChannel
		and P.AgreementType = DR.AgreementType
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		
update DR 
set DR.CRLevel = P.ValueText, DR.CRHighLevelChannel = P.HighLevelChannel,DR.CRAgreementType = P.AgreementType,DR.CRMasterDealerCode = P.MasterDealerCode
from #EligibleFeatureReactDeactWT2 DR
	inner join cfgICSContractParams P on P.Name = 'CHARGEBACKLEVEL'
		and DR.ContractHolderChannel = P.HighLevelChannel
		and P.AgreementType = DR.AgreementType
		and P.MasterDealerCode = DR.MasterDealerCode
		and P.ContractID = 'ALL'
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		
update DR 
set DR.CRLevel = P.ValueText, DR.CRHighLevelChannel = P.HighLevelChannel,DR.CRAgreementType = P.AgreementType,DR.CRMasterDealerCode = P.MasterDealerCode,DR.CRContractID = P.ContractID
from #EligibleFeatureReactDeactWT2 DR
	inner join cfgICSContractParams P on P.Name = 'CHARGEBACKLEVEL'
		and DR.ContractHolderChannel = P.HighLevelChannel
		and P.AgreementType = DR.AgreementType
		and P.MasterDealerCode = DR.MasterDealerCode
		and P.ContractID = DR.ContractID
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		
Delete From
#EligibleFeatureReactDeactWT2 
where ISNULL(CRHighLevelChannel,'') = ''
	and ISNULL(CRAgreementType,'') = ''
	and ISNULL(CRMasterDealerCode,'') = ''
	and ISNULL(CRContractID,'') = ''
		
--select * from #EligibleFeatureReactDeactWT2 where CRLevel = 'WM'

IF OBJECT_ID('tempdb..#ActivityFeatureDeactReact') is not Null
drop table #ActivityFeatureDeactReact

select * 
into #ActivityFeatureDeactReact
from (
	select T.*,P.Level,P.LevelNumber,P.LongName,C.Event,C.LevelGroup,C.ChargeBackDays,C.ReactDays
		,ROW_NUMBER() Over(Partition by FeatureActivityKey,EventType order by P.LevelNumber desc) as SocLevel 
	from #EligibleFeatureReactDeactWT2 T
		inner join cfgICSProductCategory P on T.FeatureSOC = P.ProductIDCode
		inner join cfgICSContractProductLevels C on P.Level = C.Level
			and T.CRLevel = C.LevelGroup
	where P.Level in (
		'POSTPAID FEATURE',	
		--'PREPAID CATEGORIES',	
		'PREPAID FEATURE'
		--'POSTPAID CATEGORIES',
		--'POSTPAID CATEGORIES',
		--'POSTPAID CATEGORIES'
		)
		and ((P.Level = 'PREPAID FEATURE' and C.Event = 'PREPAID FEATURE')
			or (P.Level = 'POSTPAID FEATURE' and C.Event = 'FEATURE')) 
		-----ChargeBack&React Window check-----
		and (EventType = 'DEACT' and (datediff(dd, T.ActivationDate, T.EffectiveCalcDate)<= ChargeBackDays)
			OR (EventType = 'REACT' and datediff(dd, T.DeactivationDate, T.ActivationDate)<= ReactDays))
		) X
where X.SocLevel = 1
	
