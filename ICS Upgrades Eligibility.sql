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
*                    Upgrades Activation                     *
*           #UpgradesActivation has all eligible Act         *
**************************************************************/

IF OBJECT_ID('tempdb..#UpgradesActivationWT1') is not Null
drop table #UpgradesActivationWT1

select T.*,D.AgreementType,D.ChannelType,D.ContractChannel,D.ContractHolderChannel,D.ContractHolderID,D.ContractID,D.CurrentMonth,D.DealerName,D.MasterDealerCode,D.MonthStartDate,D.MonthEndDate
	, case when D.SalesCode is not null then 1 else 0 end as DealerFlag
	, cast('' as varchar(30)) as ContractParamsID,cast('' as varchar(30)) as CPValueText, cast('' as varchar(30)) as CPName, cast('' as varchar(30)) as CPValue
into #UpgradesActivationWT1
from dbo.tsdICSUpgrades T
	left join tsdICSManulaExcludeUpgrades E on T.OrderDetailID = E.OrderDetailID
		and T.EventType = E.EventType
		and T.EffectiveCalcDate = E.EffectiveCalcDate
	left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubType and A.AccountType = T.AccountType)
	left join #DealerMonthlyEligibility D on D.SalesCode = T.SalesCode
		and CAST(T.EffectiveCalcDate as date) between D.MonthStartDate and D.MonthEndDate 
where E.OrderDetailID is null
	and (T.EventType = 'ACT' and isnull(T.SameMonth,'N/A') <> 'Y')          -----Same Month logic for Act maybe not in the Varicent yet
	and A.StartDate is null
	and T.IsValid = '1'
		
--select * from #UpgradesActivationWT1 where CurrentMonth in ('2013, Month 06','2013, Month 07') and DealerFlag = 1

-----Update the Contract Parameters by the sequence of ALL->ChannelType->AgreementType->MasterDealer->Contract

update DR 
set DR.ContractParamsID = P.ID, DR.CPValueText = P.ValueText,DR.CPName = P.Name, DR.CPValue = cast(P.ValueNumeric as varchar)
from #UpgradesActivationWT1 DR
	inner join cfgICSContractParams P on (P.Name = 'UPGRADETENURE' and DR.JumpIndicator = 'N' or P.Name = 'JUMPUPGRADETENURE' and DR.JumpIndicator = 'Y')
		and P.HighLevelChannel = 'ALL'
		and P.AgreementType = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'

--select * from #UpgradesActivationWT1 where ContractParamsID = '' 	

update DR 
set DR.ContractParamsID = P.ID, DR.CPValueText = P.ValueText,DR.CPName = P.Name, DR.CPValue = cast(P.ValueNumeric as varchar)
from #UpgradesActivationWT1 DR
	inner join cfgICSContractParams P on (P.Name = 'UPGRADETENURE' and DR.JumpIndicator = 'N' or P.Name = 'JUMPUPGRADETENURE' and DR.JumpIndicator = 'Y')
		and P.HighLevelChannel = DR.ContractHolderChannel
		and P.AgreementType = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update DR 
set DR.ContractParamsID = P.ID, DR.CPValueText = P.ValueText,DR.CPName = P.Name, DR.CPValue = cast(P.ValueNumeric as varchar)
from #UpgradesActivationWT1 DR
	inner join cfgICSContractParams P on (P.Name = 'UPGRADETENURE' and DR.JumpIndicator = 'N' or P.Name = 'JUMPUPGRADETENURE' and DR.JumpIndicator = 'Y')
		and P.HighLevelChannel = DR.ContractHolderChannel
		and P.AgreementType = DR.AgreementType
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update DR 
set DR.ContractParamsID = P.ID, DR.CPValueText = P.ValueText,DR.CPName = P.Name, DR.CPValue = cast(P.ValueNumeric as varchar)
from #UpgradesActivationWT1 DR
	inner join cfgICSContractParams P on (P.Name = 'UPGRADETENURE' and DR.JumpIndicator = 'N' or P.Name = 'JUMPUPGRADETENURE' and DR.JumpIndicator = 'Y')
		and P.HighLevelChannel = DR.ContractHolderChannel
		and P.AgreementType = DR.AgreementType
		and P.MasterDealerCode = DR.MasterDealerCode
		and P.ContractID = 'ALL'
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update DR 
set DR.ContractParamsID = P.ID, DR.CPValueText = P.ValueText,DR.CPName = P.Name, DR.CPValue = cast(P.ValueNumeric as varchar)
from #UpgradesActivationWT1 DR
	inner join cfgICSContractParams P on (P.Name = 'UPGRADETENURE' and DR.JumpIndicator = 'N' or P.Name = 'JUMPUPGRADETENURE' and DR.JumpIndicator = 'Y')
		and P.HighLevelChannel = DR.ContractHolderChannel
		and P.AgreementType = DR.AgreementType
		and P.MasterDealerCode = DR.MasterDealerCode
		and P.ContractID = DR.ContractID
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		

IF OBJECT_ID('tempdb..#UpgradesActivationWT2') is not Null
drop table #UpgradesActivationWT2

select *,
	case when DATEDIFF(mm,ISNULL(LastUpgradeDate,'1900-01-01'),EffectiveCalcDate) >= CPValue then 1 else 0 end as UEFlag
into #UpgradesActivationWT2
from #UpgradesActivationWT1

--select * from #UpgradesActivationWT2 where CurrentMonth in ('2013, Month 06','2013, Month 07') and DealerFlag = 1 and UEFlag = 1

IF OBJECT_ID('tempdb..#UpgradesActivation') is not Null
drop table #UpgradesActivation

select * 
into #UpgradesActivation
from (
	select T.*, M.MarketCode as UDFMarketCode,M.SamsonMktName
		,ROW_NUMBER() over (partition by T.BillingSubSystemID,T.OrderDetailID, T.EventType, T.EffectiveCalcDate order by case when M.MarketCode like '%[0-9]' then 1 else 2 end ) as MKTOrder
		,case when M.ContractID is not null then 1 else 0 end as InMarketFlag
	from #UpgradesActivationWT2 T
		inner join #ProductEligibility P on T.PlanCode = P.ProductIDCode
			and T.BillingSubsystemID = P.BillingSubsystemID
			and CAST(T.EffectiveCalcDate as date) between P.StartDate and P.EndDate
		inner join cfgICSProductCategory C on C.BillingSubsystemID = T.BillingSubSystemID
			and C.ProductIDCode = T.PlanCode
			and cast(T.EffectiveCalcDate as date) between cast(C.StartDate as date) and cast(C.EndDate as date)
		inner join cfgICSUpgradeParms U on U.HighLevelChannel = T.ContractHolderChannel 
			and U.Level = C.Level
			and cast(T.EffectiveCalcDate as date) between cast(U.StartDate as date) and cast(U.EndDate as date)
			and (
				(U.HSOB2V = '1' and U.HSOB2V = T.HSOContractExtNoBTV)
				or
				(U.HSOContractExt = '1' and U.HSOContractExt = T.HSOContractExt)
				or
				(U.PointofSale = '1' and U.PointofSale = T.TPRPos)
				or
				(U.DirectFullfillment = '1' and U.DirectFullfillment = T.TPRDirect)
				or
				(U.HSONoAct = '1' and U.HSONoAct = T.HSONoAct)
				)
		left join #MarketEligibility M on T.ContractID = M.ContractID
			and ((ISNULL(M.NPANXX,'')<>'' and T.NPANXX = M.NPANXX) or (ISNULL(M.NPANXX,'')='' and T.MarketCode = M.SamsonMktName))
			and CAST(T.EffectiveCalcDate as date) between M.StartDate and M.EndDate
	) X
where X.MKTOrder = 1

--select * from #UpgradesActivation where CurrentMonth in ('2013, Month 06','2013, Month 07') and DealerFlag = 1 and UEFlag = 1 and InMarketFlag = 0

/******************************************************************************
*                         Upgrades Deactivation                               *
*           #UpgradesDeact has all eligible Upgrades Deactivation             *
******************************************************************************/

IF OBJECT_ID('tempdb..#EligibleTxnForUpgradeDeact') is not Null
drop table #EligibleTxnForUpgradeDeact

select * 
into #EligibleTxnForUpgradeDeact
from (
	--select distinct A.ServiceUniversalID,A.EventType,A.SalesCode,A.EffectiveCalcDate
	--from #ActivityPostPaidActivation A
	--union 
	select distinct B.OrderDetailID,B.EventType,B.SalesCode,B.EffectiveCalcDate
	from archICSPaidUpgradeActivations B
	) X
	
IF OBJECT_ID('tempdb..#EligibleUpgradeDeactWT1') is not Null
drop table #EligibleUpgradeDeactWT1

select X.*, D.DealerName,D.MasterDealerCode,D.CurrentMonth,D.ContractHolderID,D.ContractID,D.ContractHolderChannel,D.ContractChannel,D.ChannelType,D.AgreementType
		, M.MarketCode as UDFMarketCode,M.SamsonMktName
	,ROW_NUMBER() over (partition by X.BillingSubSystemID,X.OrderDetailID, X.EventType, X.EffectiveCalcDate order by case when M.MarketCode like '%[0-9]' then 1 else 2 end ) as MKTOrder 
	,case when M.ContractID is not null then 1 else 0 end as InMarketFlag
into #EligibleUpgradeDeactWT1
from (
	select T.*, Act.SalesCode as SubscriberSalesCode, Act.EffectiveCalcDate as SubscriberActDate,'' as SubscriberDeactDate
	from tsdICSUpgrades T
		left join tsdICSManualExclude E on T.ServiceUniversalID = E.ServiceUniversalID
			and T.EventType = E.EventType
			and T.EffectiveCalcDate = E.EffectiveCalcDate
		left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubType and A.AccountType = T.AccountType)
		inner join #EligibleTxnForUpgradeDeact Act on T.OrderDetailID = Act.OrderDetailID 
			and Act.EventType = 'ACT' and cast(T.EffectiveCalcDate as date)>= cast(Act.EffectiveCalcDate as date)
	where E.ServiceUniversalID is null
		and T.EventType = 'DEACT' and isnull(SameMonth,'N/A') <> 'Y'
		and A.StartDate is null
		and T.IsValid = '1'
		--and T.ServiceUniversalID = '2305497747'
		) X
	inner join #DealerMonthlyEligibility D on D.SalesCode = X.SubscriberSalesCode
		and CAST(X.EffectiveCalcDate as date) between D.MonthStartDate and D.MonthEndDate 
	inner join #ProductEligibility P on X.PlanCode = P.ProductIDCode
		and X.BillingSubsystemID = P.BillingSubsystemID
		and CAST(X.EffectiveCalcDate as date) between P.StartDate and P.EndDate

	inner join cfgICSProductCategory C on C.BillingSubsystemID = X.BillingSubSystemID
		and C.ProductIDCode = X.PlanCode
		and cast(X.EffectiveCalcDate as date) between cast(C.StartDate as date) and cast(C.EndDate as date)
	inner join cfgICSUpgradeParms U on U.HighLevelChannel = D.ContractHolderChannel 
		and U.Level = C.Level
		and cast(X.EffectiveCalcDate as date) between cast(U.StartDate as date) and cast(U.EndDate as date)
		and (
			(U.HSOB2V = '1' and U.HSOB2V = X.HSOContractExtNoBTV)
			or
			(U.HSOContractExt = '1' and U.HSOContractExt = X.HSOContractExt)
			or
			(U.PointofSale = '1' and U.PointofSale = X.TPRPos)
			or
			(U.DirectFullfillment = '1' and U.DirectFullfillment = X.TPRDirect)
			or
			(U.HSONoAct = '1' and U.HSONoAct = X.HSONoAct)
			)
	left join #MarketEligibility M on D.ContractID = M.ContractID
		and ((ISNULL(M.NPANXX,'')<>'' and X.NPANXX = M.NPANXX) or (ISNULL(M.NPANXX,'')='' and X.MarketCode = M.SamsonMktName))
		and CAST(X.EffectiveCalcDate as date) between M.StartDate and M.EndDate
		
--select * from #EligibleUpgradeDeactWT1	

IF OBJECT_ID('tempdb..#EligibleUpgradeDeactWT2') is not Null
drop table #EligibleUpgradeDeactWT2


select DR.*
	,P.HighLevelChannel as CRHighLevelChannel,P.AgreementType as CRAgreementType,P.MasterDealerCode as CRMasterDealerCode,P.ContractID as CRContractID,P.ValueText as CRLevel
into #EligibleUpgradeDeactWT2
from #EligibleUpgradeDeactWT1 DR
	left join cfgICSContractParams P on P.Name = 'CHARGEBACKLEVEL'
		and P.HighLevelChannel = 'ALL' and P.AgreementType = 'ALL' and P.MasterDealerCode = 'ALL' and P.ContractID = 'ALL'
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
where DR.MKTOrder = 1
	--and ServiceUniversalID = '2306048568'
--order by ServiceUniversalID


-----Begin to apply the level by sequence, Contract > MasterDealer > AgreementType > HighLevelChannel

update DR 
set DR.CRLevel = P.ValueText, DR.CRHighLevelChannel = P.HighLevelChannel
from #EligibleUpgradeDeactWT2 DR
	inner join cfgICSContractParams P on P.Name = 'CHARGEBACKLEVEL'
		and DR.ContractHolderChannel = P.HighLevelChannel
		and P.AgreementType = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)

update DR 
set DR.CRLevel = P.ValueText, DR.CRHighLevelChannel = P.HighLevelChannel,DR.CRAgreementType = P.AgreementType
from #EligibleUpgradeDeactWT2 DR
	inner join cfgICSContractParams P on P.Name = 'CHARGEBACKLEVEL'
		and DR.ContractHolderChannel = P.HighLevelChannel
		and P.AgreementType = DR.AgreementType
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		
update DR 
set DR.CRLevel = P.ValueText, DR.CRHighLevelChannel = P.HighLevelChannel,DR.CRAgreementType = P.AgreementType,DR.CRMasterDealerCode = P.MasterDealerCode
from #EligibleUpgradeDeactWT2 DR
	inner join cfgICSContractParams P on P.Name = 'CHARGEBACKLEVEL'
		and DR.ContractHolderChannel = P.HighLevelChannel
		and P.AgreementType = DR.AgreementType
		and P.MasterDealerCode = DR.MasterDealerCode
		and P.ContractID = 'ALL'
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		
update DR 
set DR.CRLevel = P.ValueText, DR.CRHighLevelChannel = P.HighLevelChannel,DR.CRAgreementType = P.AgreementType,DR.CRMasterDealerCode = P.MasterDealerCode,DR.CRContractID = P.ContractID
from #EligibleUpgradeDeactWT2 DR
	inner join cfgICSContractParams P on P.Name = 'CHARGEBACKLEVEL'
		and DR.ContractHolderChannel = P.HighLevelChannel
		and P.AgreementType = DR.AgreementType
		and P.MasterDealerCode = DR.MasterDealerCode
		and P.ContractID = DR.ContractID
		and cast(DR.EffectiveCalcDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		
Delete From
#EligibleUpgradeDeactWT2 
where ISNULL(CRHighLevelChannel,'') = ''
	and ISNULL(CRAgreementType,'') = ''
	and ISNULL(CRMasterDealerCode,'') = ''
	and ISNULL(CRContractID,'') = ''
		
--select * from #EligibleUpgradeDeactWT2 where ServiceUniversalID = '2306048568'

IF OBJECT_ID('tempdb..#UpgradesDeact') is not Null
drop table #UpgradesDeact

select * 
into #UpgradesDeact
from (
	select T.*,P.Level,P.LevelNumber,P.LongName,C.Event,C.LevelGroup,C.ChargeBackDays,C.ReactDays
		,ROW_NUMBER() Over(Partition by OrderDetailID,EventType order by P.LevelNumber desc) as SocLevel 
	from #EligibleUpgradeDeactWT2 T
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
		and (P.Level = 'POSTPAID CATEGORIES' and C.Event = 'UPGRADE') 
		-----ChargeBack&React Window check-----
		and (EventType = 'DEACT' and (datediff(dd, T.SubscriberActDate, T.EffectiveCalcDate)<= ChargeBackDays))
	) X
where X.SocLevel = 1
	
--select * from #UpgradesDeact
	
/******************************************************************************
*                                                                             *
*                  Positive Scenarios Test Result                             *
*                                                                             *
******************************************************************************/

--DEL0100	Upgrades PostPaid Activation				
--		Preconditions			
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business		
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business		
--			Dealer codes eligible for activation transactions based on sales code hierarchy		
--			In market activations for dealers		
					
--		Expected	Transaction is Eligible		Calc: ICS Upgrades Eligibility UE2020
--			Transaction available in the list of eligible upgrade acts		
--			Transaction available in the list of eligible upgrade with plancode details and OOM identifier Value of 1 in market.	

select * 
from #UpgradesActivation
where CurrentMonth in ('2013, Month 06','2013, Month 07') and DealerFlag = 1 and UEFlag = 1 --and InMarketFlag = 0


--DEL0101	Upgrades AddALine Activation				
--		Preconditions			
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business		
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business		
--			Dealer codes eligible for activation transactions based on sales code hierarchy		
--			In market activations for dealers		
					
--		Expected	Transaction is Eligible		Calc: ICS Upgrades Eligibility UE2020
--			Transaction available in the list of eligible upgrade acts		
--			Transaction available in the list of eligible upgrade with plancode details and OOM identifier Value of 1 in market.	

select * 
from #UpgradesActivation T
	inner join tsdICSActivity A on T.ServiceUniversalID = A.ServiceUniversalID
where T.CurrentMonth in ('2013, Month 06','2013, Month 07') and DealerFlag = 1 and UEFlag = 1
	and (A.EventType = 'ACT' and A.IsAddALine = 'Y')


--DEL0102	Upgrades Prepaid Activation				
--		Preconditions			
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business		
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business		
--			Dealer codes eligible for activation transactions based on sales code hierarchy		
--			In market activations for dealers		
					
--		Expected	Transaction is Eligible		
--			Transaction available in the list of eligible upgrade acts		
--			Transaction available in the list of eligible upgrade with plancode details and OOM identifier Value of 1 in market.		

select * 
from #UpgradesActivation T
where BillingSubSystemID in ('2','5','9') 
	
--DEL0103	Upgrades PostPaid Deactivation - Comp Contract Setup				
--		Preconditions			
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business		
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business		
--			Deactivations match with paid historical activations based on archICSPaidActivations table		
--			Eligible dealer codes for deact transactions based on sales code hierarchy		
--			Eligible commissionable products for all deactivation transactions		
--			The date difference between the deact date and act date is within the timeframe defined in the “ChargeBackDays” parameter in the “cfgICSContractProductLevel” table for the deact transactions		
--			Tag out of market\in market deactivations for dealers and filter out of market deacts		
--			Compensation levelGroup based on  Contracts setup for chargebacks from the “cfgICSContractParms” table.		
					
--		Expected	Transaction is Eligible		Calc: ICS Upgrades Eligibility 1012a
--			Transaction available in the list of eligible upgrade deacts		
--			Transaction available in the list of eligible upgrade with plancode details and OOM identifier Value of 1 in market.	


select * 
from #UpgradesDeact	T2
where 1=1
	and BillingSubsystemID = '1'
    and EventType = 'DEACT'
    and CRHighLevelChannel <> 'ALL'
    and CRAgreementType <> 'ALL'
    and CRMasterDealerCode <> 'ALL'
    and CRContractID <> 'ALL'
    

--DEL0104	Upgrades PostPaid Deactivation - Comp Masterdealer Setup				
--		Preconditions			
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business		
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business		
--			Deactivations match with paid historical activations based on archICSPaidActivations table		
--			Eligible dealer codes for deact transactions based on sales code hierarchy		
--			Eligible commissionable products for all deactivation transactions		
--			The date difference between the deact date and act date is within the timeframe defined in the “ChargeBackDays” parameter in the “cfgICSContractProductLevel” table for the deact transactions		
--			Tag out of market\in market deactivations for dealers and filter out of market deacts		
--			Compensation levelGroup based on Masterdealer setup for chargebacks from the “cfgICSContractParms” table.		
					
--		Expected	Transaction is Eligible		Calc: ICS Upgrades Eligibility 1012b
--			Transaction available in the list of eligible upgrade deacts		
--			Transaction available in the list of eligible upgrade with plancode details and OOM identifier Value of 1 in market.		


select * 
from #UpgradesDeact	T2
where 1=1
	and BillingSubsystemID = '1'
    and EventType = 'DEACT'
    and CRHighLevelChannel <> 'ALL'
    and CRAgreementType <> 'ALL'
    and CRMasterDealerCode <> 'ALL'
    and CRContractID = 'ALL'
    

--DEL0105	Upgrades PostPaid Deactivation - Comp AgreementType Setup				
--		Preconditions			
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business		
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business		
--			Deactivations match with paid historical activations based on archICSPaidActivations table		
--			Eligible dealer codes for deact transactions based on sales code hierarchy		
--			Eligible commissionable products for all deactivation transactions		
--			The date difference between the deact date and act date is within the timeframe defined in the “ChargeBackDays” parameter in the “cfgICSContractProductLevel” table for the deact transactions		
--			Tag out of market\in market deactivations for dealers and filter out of market deacts		
--			Compensation levelGroup based on AgreementType setup for chargebacks from the “cfgICSContractParms” table.		
					
--		Expected	Transaction is Eligible		Calc: ICS Upgrades Eligibility 1012c
--			Transaction available in the list of eligible upgrade deacts		
--			Transaction available in the list of eligible upgrade with plancode details and OOM identifier Value of 1 in market.		

select * 
from #UpgradesDeact	T2
where 1=1
	and BillingSubsystemID = '1'
    and EventType = 'DEACT'
    and CRHighLevelChannel <> 'ALL'
    and CRAgreementType <> 'ALL'
    and CRMasterDealerCode = 'ALL'
    and CRContractID = 'ALL'
    
--DEL0106	Upgrades PostPaid Deactivation - Comp HighLevelChannel Setup				
--		Preconditions			
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business		
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business		
--			Deactivations match with paid historical activations based on archICSPaidActivations table		
--			Eligible dealer codes for deact transactions based on sales code hierarchy		
--			Eligible commissionable products for all deactivation transactions		
--			The date difference between the deact date and act date is within the timeframe defined in the “ChargeBackDays” parameter in the “cfgICSContractProductLevel” table for the deact transactions		
--			Tag out of market\in market deactivations for dealers and filter out of market deacts		
--			Compensation levelGroup based on HighLevelChannel  setup for chargebacks from the “cfgICSContractParms” table.		
					
--		Expected	Transaction is Eligible		
--			Transaction available in the list of eligible upgrade deacts	Calc: ICS Upgrades Eligibility 1012d	
--			Transaction available in the list of eligible upgrade with plancode details and OOM identifier Value of 1 in market.		

select * 
from #UpgradesDeact	T2
where 1=1
	and BillingSubsystemID = '1'
    and EventType = 'DEACT'
    and CRHighLevelChannel <> 'ALL'
    and CRAgreementType = 'ALL'
    and CRMasterDealerCode = 'ALL'
    and CRContractID = 'ALL'
    
--DEL0107	Upgrades AddALine Deactivation				
--		Preconditions			
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business		
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business		
--			Deactivations match with paid historical activations based on archICSPaidActivations table		
--			Eligible dealer codes for deact transactions based on sales code hierarchy		
--			Eligible commissionable products for all deactivation transactions		
--			The date difference between the deact date and act date is within the timeframe defined in the “ChargeBackDays” parameter in the “cfgICSContractProductLevel” table for the deact transactions		
--			Tag out of market\in market deactivations for dealers and filter out of market deacts		
--			Compensation levelGroup based on  Contracts setup for chargebacks from the “cfgICSContractParms” table.		
					
--		Expected	Transaction is Eligible		
--			Transaction available in the list of eligible upgrade deacts		
--			Transaction available in the list of eligible upgrade with plancode details and OOM identifier Value of 1 in market.		

select * 
from #UpgradesDeact T
	inner join tsdICSActivity A on T.ServiceUniversalID = A.ServiceUniversalID
where T.CurrentMonth in ('2013, Month 06','2013, Month 07') 
	and (A.EventType = 'ACT' and A.IsAddALine = 'Y')
	
--DEL0108	Upgrades Prepaid Deactivation				
--		Preconditions			
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business		
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business		
--			Deactivations match with paid historical activations based on archICSPaidActivations table		
--			Eligible dealer codes for deact transactions based on sales code hierarchy		
--			Eligible commissionable products for all deactivation transactions		
--			The date difference between the deact date and act date is within the timeframe defined in the “ChargeBackDays” parameter in the “cfgICSContractProductLevel” table for the deact transactions		
--			Tag out of market\in market deactivations for dealers and filter out of market deacts		
--			Compensation levelGroup based on  Contracts setup for chargebacks from the “cfgICSContractParms” table.		
					
--		Expected	Transaction is Eligible		
--			Transaction available in the list of eligible upgrade deacts		
--			Transaction available in the list of eligible upgrade with plancode details and OOM identifier Value of 1 in market.		

select * 
from #UpgradesDeact T
where BillingSubSystemID in ('2','5','9') 


--DEL0106	Upgrades PostPaid Deactivation - Global Setup				
--		Preconditions			
--			Transactions not present in table “tsdICSManualExclude”, there were manually excluded by the business		
--			AccountTypes for transactions not present in  table “cfgICSAccountTypeExclude”,  there where excluded AccountTypes by the business		
--			Deactivations match with paid historical activations based on archICSPaidActivations table		
--			Eligible dealer codes for deact transactions based on sales code hierarchy		
--			Eligible commissionable products for all deactivation transactions		
--			The date difference between the deact date and act date is within the timeframe defined in the “ChargeBackDays” parameter in the “cfgICSContractProductLevel” table for the deact transactions		
--			Tag out of market\in market deactivations for dealers and filter out of market deacts		
--			Compensation levelGroup based on Global  setup for chargebacks from the “cfgICSContractParms” table.		
					
--		Expected	Transaction is Eligible		Calc: ICS Upgrades Eligibility 1012e
--			Transaction available in the list of eligible upgrade deacts		
--			Transaction available in the list of eligible upgrade with plancode details and OOM identifier Value of 1 in market.		

select * 
from #UpgradesDeact	T2
where 1=1
	and BillingSubsystemID = '1'
    and EventType = 'DEACT'
    and CRHighLevelChannel = 'ALL'
    and CRAgreementType = 'ALL'
    and CRMasterDealerCode = 'ALL'
    and CRContractID = 'ALL'
    
    
/******************************************************************************
*                                                                             *
*                  Negative Scenarios Test Result                             *
*                                                                             *
******************************************************************************/

--DEL0150N	Upgrades Transactions  have been manually excluded by the business in the table “tsdICSManualExclude”	

select *			
from dbo.tsdICSUpgrades T
	inner join tsdICSManulaExcludeUpgrades E on T.OrderDetailID = E.OrderDetailID
		and T.EventType = E.EventType
		and T.EffectiveCalcDate = E.EffectiveCalcDate
where T.IsValid = '1'


--DEL0151N	Upgrades Transactions correspond to an excluded AccountTypes based on data in the table “cfgICSAccountTypeExclude”				

select distinct T.*
from dbo.tsdICSUpgrades T
	inner join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubType and A.AccountType = T.AccountType)
where not( EventType in ('ACT','DEACT') and SameMonth = 'Y')
	and T.IsValid = '1'
	

--DEL0152N	Upgrades Non-eligible dealer codes for activation transactions based on sales code hierarchy				

select * 
from #UpgradesActivationWT1
where DealerFlag = 0

--DEL0153N	Upgrades Out of market activations for dealers		

select *
from #UpgradesActivation
where InMarketFlag = 0		

--DEL0154N	Upgrades Deactivations does not match with paid historical upgrade acts based on archICSPaidActivations table	

select *
from tsdICSUpgrades T
	left join tsdICSManualExclude E on T.ServiceUniversalID = E.ServiceUniversalID
		and T.EventType = E.EventType
		and T.EffectiveCalcDate = E.EffectiveCalcDate
	left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubType and A.AccountType = T.AccountType)
	left join #EligibleTxnForUpgradeDeact Act on T.OrderDetailID = Act.OrderDetailID 
		and Act.EventType = 'ACT' and cast(T.EffectiveCalcDate as date)>= cast(Act.EffectiveCalcDate as date)
where E.ServiceUniversalID is null
	and T.EventType = 'DEACT' and isnull(SameMonth,'N/A') <> 'Y'
	and A.StartDate is null
	and T.IsValid = '1'		
	and Act.OrderDetailID is null	


--DEL0155N	Upgrades Deactivations Non-eligible dealer codes for deact transactions based on sales code hierarchy				

select distinct  X.*
from (
	select T.*, Act.SalesCode as SubscriberSalesCode, Act.EffectiveCalcDate as SubscriberActDate,'' as SubscriberDeactDate
	from tsdICSUpgrades T
		left join tsdICSManualExclude E on T.ServiceUniversalID = E.ServiceUniversalID
			and T.EventType = E.EventType
			and T.EffectiveCalcDate = E.EffectiveCalcDate
		left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubType and A.AccountType = T.AccountType)
		inner join #EligibleTxnForUpgradeDeact Act on T.OrderDetailID = Act.OrderDetailID 
			and Act.EventType = 'ACT' and cast(T.EffectiveCalcDate as date)>= cast(Act.EffectiveCalcDate as date)
	where E.ServiceUniversalID is null
		and T.EventType = 'DEACT' and isnull(SameMonth,'N/A') <> 'Y'
		and A.StartDate is null
		and T.IsValid = '1'
		--and T.ServiceUniversalID = '2305497747'
		) X
	left join #DealerMonthlyEligibility D on D.SalesCode = X.SubscriberSalesCode
		and CAST(X.EffectiveCalcDate as date) between D.MonthStartDate and D.MonthEndDate
where D.SalesCode is null

--DEL0156N	Upgrades Deactivations Non-eligible commissionable products for all deactivation transactions				

select distinct  X.*
from (
	select T.*, Act.SalesCode as SubscriberSalesCode, Act.EffectiveCalcDate as SubscriberActDate,'' as SubscriberDeactDate
	from tsdICSUpgrades T
		left join tsdICSManualExclude E on T.ServiceUniversalID = E.ServiceUniversalID
			and T.EventType = E.EventType
			and T.EffectiveCalcDate = E.EffectiveCalcDate
		left join dbo.cfgICSAccountTypeExclude A on (A.AccountSubType = T.AccountSubType and A.AccountType = T.AccountType)
		inner join #EligibleTxnForUpgradeDeact Act on T.OrderDetailID = Act.OrderDetailID 
			and Act.EventType = 'ACT' and cast(T.EffectiveCalcDate as date)>= cast(Act.EffectiveCalcDate as date)
	where E.ServiceUniversalID is null
		and T.EventType = 'DEACT' and isnull(SameMonth,'N/A') <> 'Y'
		and A.StartDate is null
		and T.IsValid = '1'
		--and T.ServiceUniversalID = '2305497747'
		) X
	inner join #DealerMonthlyEligibility D on D.SalesCode = X.SubscriberSalesCode
		and CAST(X.EffectiveCalcDate as date) between D.MonthStartDate and D.MonthEndDate
	left join #ProductEligibility P on X.PlanCode = P.ProductIDCode
		and X.BillingSubsystemID = P.BillingSubsystemID
		and CAST(X.EffectiveCalcDate as date) between P.StartDate and P.EndDate
where P.ProductIDCode is null


--DEL0157N	Upgrades Deactivations The date difference between the deact date and act date is outside the timeframe defined in the “ChargeBackDays” parameter in the “cfgICSContractProductLevel” table for the deact transactions				

select distinct T.*
from #EligibleUpgradeDeactWT2 T
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
	and (P.Level = 'POSTPAID CATEGORIES' and C.Event = 'UPGRADE') 
	-----ChargeBack&React Window check-----
	and (EventType = 'DEACT' and (datediff(dd, T.SubscriberActDate, T.EffectiveCalcDate)> ChargeBackDays))
	
--DEL0158N	Upgrades Deactivations Out of market deactivations for dealers				

select * 
from #UpgradesDeact
where InMarketFlag = 0