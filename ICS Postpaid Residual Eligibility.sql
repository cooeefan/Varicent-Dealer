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
--select * from #MarketEligibility

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

/***************************************************************
*  		                TXNs Eligibility   	                   *
*  #PostpaidResidualTXNsEligibility has all eligible records   *
****************************************************************/

----- Process Market Logic -----

IF OBJECT_ID('tempdb..#TXNsEligibilityWT1') is not Null
drop table #TXNsEligibilityWT1

select DATEDIFF(MM,CAST(BEGSERVDATE as date), MonthStartDate) as Tenure 
	,B.*, D.DealerName, D.SubDealerID,D.ContractHolderID, D.ContractID, D.MasterDealerCode, D.ContractChannel, D.ContractHolderChannel, D.ChannelType, D.AgreementType, D.CurrentMonth
	, D.MonthStartDate, D.MonthEndDate, M.NPANXX as MKTNPANXX, M.StartDate as MKTStartDate, M.EndDate as MKTEndDate
into #TXNsEligibilityWT1
from tsdICSSubscriberBase B
	inner join #DealerMonthlyEligibility D on B.SUBSCRIBERDEALERCODE = D.SalesCode
		and cast(B.STARTDATE as date) <= D.MonthStartDate  and cast(B.ENDDATE as date) >= D.MonthEndDate	----- Varicent Logic
		--and cast(B.STARTDATE as date) <= D.MonthEndDate and cast(B.ENDDATE as date) >= D.MonthEndDate		----- Correct Logic should be used
	inner join #MarketEligibility M on D.ContractID = M.ContractID
		and ((ISNULL(M.NPANXX,'')='' and B.MarketCode = M.SamsonMktName))
		and D.MonthEndDate between M.StartDate and M.EndDate
where B.STATUS = 'A'
	and D.CurrentMonth in ('2013, Month 06','2013, Month 07')
	
update WT1
set WT1.MARKETCODE = M.MarketCode, WT1.MKTNPANXX = M.NPANXX
from #TXNsEligibilityWT1 WT1
	inner join #MarketEligibility M on M.NPANXX = WT1.NPANXX
		and M.NPANXX is not null
		and WT1.MonthEndDate between M.StartDate and M.EndDate
		
--select * from #TXNsEligibilityWT1 where MARKETCODE = 'AL1' and CurrentMonth = '2013, Month 07'
--select count(*) from #TXNsEligibilityWT1

--select * from cfgICSSalesCode where Status = 'Inactive' and StatusReason = 'Location Closed'

------ Process 'Location Closed' ------
IF OBJECT_ID('tempdb..#TXNsEligibilityWT2') is not Null
drop table #TXNsEligibilityWT2

select T.*
	,S.CompEffStartDate,S.CompEffEndDate,S.SalesCodeDeactDate,S.Status as SalesCodeStatus,S.StatusCode,S.StatusReason,cast('' as varchar(100)) as IncludeFlag 
into #TXNsEligibilityWT2
from #TXNsEligibilityWT1 T
	inner join cfgICSSalesCode S on T.SUBSCRIBERDEALERCODE = S.SalesCode
		and T.ContractHolderID = S.ContractHolderID
		and S.Status = 'Inactive' and S.StatusReason = 'Location Closed'
		and cast(T.MonthEndDate as date) >= cast(S.SalesCodeDeactDate as date)
--order by SERVICENUMBER

update TWK2
set TWK2.IncludeFlag = 'GLOBLE: '+'ID='+cast(C.ID as varchar) 
from #TXNsEligibilityWT2 TWK2
	inner join cfgICSContractParams C on C.Name = 'CLOSEDDOORRESIDUAL'
		and C.HighLevelChannel = 'ALL'
		and C.AgreementType = 'ALL'
		and C.MasterDealerCode = 'ALL'
		and C.ContractID = 'ALL'
		and C.ValueText = 'N'
		and cast(TWK2.MonthEndDate as date) between cast(C.StartDate as date) and cast(C.EndDate as date) 

update TWK2
set TWK2.IncludeFlag = 'HLC: '+'ID='+cast(C.ID as varchar) 
from #TXNsEligibilityWT2 TWK2
	inner join cfgICSContractParams C on C.Name = 'CLOSEDDOORRESIDUAL'
		and C.HighLevelChannel = TWK2.ContractHolderChannel
		and C.AgreementType = 'ALL'
		and C.MasterDealerCode = 'ALL'
		and C.ContractID = 'ALL'
		and cast(TWK2.MonthEndDate as date) between cast(C.StartDate as date) and cast(C.EndDate as date) 
where isnull(TWK2.IncludeFlag,'')=''

update TWK2
set TWK2.IncludeFlag = 'AgreementType: '+'ID='+cast(C.ID as varchar) 
from #TXNsEligibilityWT2 TWK2
	inner join cfgICSContractParams C on C.Name = 'CLOSEDDOORRESIDUAL'
		and C.HighLevelChannel = TWK2.ContractHolderChannel
		and C.AgreementType = TWK2.AgreementType
		and C.MasterDealerCode = 'ALL'
		and C.ContractID = 'ALL'
		and cast(TWK2.MonthEndDate as date) between cast(C.StartDate as date) and cast(C.EndDate as date) 
where isnull(TWK2.IncludeFlag,'')=''

update TWK2
set TWK2.IncludeFlag = 'MasterDealer: '+'ID='+cast(C.ID as varchar) 
from #TXNsEligibilityWT2 TWK2
	inner join cfgICSContractParams C on C.Name = 'CLOSEDDOORRESIDUAL'
		and C.HighLevelChannel = TWK2.ContractHolderChannel
		and C.AgreementType = TWK2.AgreementType
		and C.MasterDealerCode = TWK2.MasterDealerCode
		and C.ContractID = 'ALL'
		and cast(TWK2.MonthEndDate as date) between cast(C.StartDate as date) and cast(C.EndDate as date) 
where isnull(TWK2.IncludeFlag,'')=''

update TWK2
set TWK2.IncludeFlag = 'Contract: '+'ID='+cast(C.ID as varchar) 
from #TXNsEligibilityWT2 TWK2
	inner join cfgICSContractParams C on C.Name = 'CLOSEDDOORRESIDUAL'
		and C.HighLevelChannel = TWK2.ContractHolderChannel
		and C.AgreementType = TWK2.AgreementType
		and C.MasterDealerCode = TWK2.MasterDealerCode
		and C.ContractID = TWK2.ContractID
		and cast(TWK2.MonthEndDate as date) between cast(C.StartDate as date) and cast(C.EndDate as date) 
where isnull(TWK2.IncludeFlag,'')=''

--select * from #TXNsEligibilityWT2 where ServiceNumber = '5415151171'

------ Union back regular TXNs and apply Product commissionable logic ------
IF OBJECT_ID('tempdb..#TXNsEligibilityWT3') is not Null
drop table #TXNsEligibilityWT3

select P.BillingSubsystemID,X.* 
into #TXNsEligibilityWT3
from (
	select T.*
		,S.CompEffStartDate,S.CompEffEndDate,S.SalesCodeDeactDate,S.Status as SalesCodeStatus,S.StatusCode,S.StatusReason,'Regular' as IncludeFlag
		,case when ISNULL(T.ADDALINESOC,'') <> '' then T.ADDALINESOC else T.PLANCODE end as AssignPlanCode 
	from #TXNsEligibilityWT1 T
		left join cfgICSSalesCode S on T.SUBSCRIBERDEALERCODE = S.SalesCode
			and T.ContractHolderID = S.ContractHolderID
			and S.Status = 'Inactive' and S.StatusReason = 'Location Closed'
			and cast(T.MonthEndDate as date) >= cast(S.SalesCodeDeactDate as date) 
	where S.SalesCode is null
	UNION
	select * 
		,case when ISNULL(ADDALINESOC,'') <> '' then ADDALINESOC else PLANCODE end as AssignPlanCode 
	from #TXNsEligibilityWT2
	where isnull(IncludeFlag,'')<>''
	) X 
	inner join #ProductEligibility P on X.AssignPlanCode = P.ProductIDCode
		and X.CurrentMonth = P.CurrentMonth
		and P.BillingSubsystemID = '1'	--- Only for PostPaid
-- select * from #TXNsEligibilityWT3 where ServiceNumber = '5415151171'
		
------ Process Residual in cfgICSCompPayeeAssignments Logic ------

/******************************************************************************************************
Priority	HLChannel	AgreementType	MasterDealer	Contract	Market		SubDealer	SalesCode
12			Specific	ALL				ALL				ALL			ALL			ALL			ALL
11			Specific	Specific		ALL				ALL			ALL			ALL			ALL
10			Specific	Specific		Specific		ALL			ALL			ALL			ALL
9			Specific	Specific		Specific		Specific	ALL			ALL			ALL
5			Specific	Specific		Specific		Specific	Specific	ALL			ALL
4			Specific	Specific		Specific		Specific	ALL			Specific	ALL
3			Specific	Specific		Specific		Specific	Specific	Specific	ALL
2			Specific	Specific		Specific		Specific	ALL			Specific	Specific
1			Specific	Specific		Specific		Specific	Specific	Specific	Specific
******************************************************************************************************/

IF OBJECT_ID('tempdb..#TXNsEligibilityWT4') is not Null
drop table #TXNsEligibilityWT4

select WT3.*, cast(P.ID as varchar(50)) as PayeeAssignID
into #TXNsEligibilityWT4
from #TXNsEligibilityWT3 WT3
	left join cfgICSCompPayeeAssignments P on P.EventType = 'RESIDUAL'
		and P.HighLevelChannel = 'ALL'
		and P.AgreementTypeName = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.Contract = 'ALL'
		and P.Market = 'ALL'
		and P.SubDealerEntity = 'ALL'
		and P.SalesCode = 'ALL'
		and cast(WT3.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update WT4
set WT4.PayeeAssignID = P.ID
from #TXNsEligibilityWT4 WT4
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'RESIDUAL'
		and P.HighLevelChannel = WT4.ContractHolderChannel
		and P.AgreementTypeName = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.Contract = 'ALL'
		and P.Market = 'ALL'
		and P.SubDealerEntity = 'ALL'
		and P.SalesCode = 'ALL'
		and cast(WT4.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'

update WT4
set WT4.PayeeAssignID = P.ID
from #TXNsEligibilityWT4 WT4
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'RESIDUAL'
		and P.HighLevelChannel = WT4.ContractHolderChannel
		and P.AgreementTypeName = WT4.AgreementType
		and P.MasterDealerCode = 'ALL'
		and P.Contract = 'ALL'
		and P.Market = 'ALL'
		and P.SubDealerEntity = 'ALL'
		and P.SalesCode = 'ALL'
		and cast(WT4.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update WT4
set WT4.PayeeAssignID = P.ID
from #TXNsEligibilityWT4 WT4
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'RESIDUAL'
		and P.HighLevelChannel = WT4.ContractHolderChannel
		and P.AgreementTypeName = WT4.AgreementType
		and P.MasterDealerCode = WT4.MasterDealerCode
		and P.Contract = 'ALL'
		and P.Market = 'ALL'
		and P.SubDealerEntity = 'ALL'
		and P.SalesCode = 'ALL'
		and cast(WT4.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update WT4
set WT4.PayeeAssignID = P.ID
from #TXNsEligibilityWT4 WT4
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'RESIDUAL'
		and P.HighLevelChannel = WT4.ContractHolderChannel
		and P.AgreementTypeName = WT4.AgreementType
		and P.MasterDealerCode = WT4.MasterDealerCode
		and P.Contract = WT4.ContractID
		and P.Market = 'ALL'
		and P.SubDealerEntity = 'ALL'
		and P.SalesCode = 'ALL'
		and cast(WT4.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update WT4
set WT4.PayeeAssignID = P.ID
from #TXNsEligibilityWT4 WT4
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'RESIDUAL'
		and P.HighLevelChannel = WT4.ContractHolderChannel
		and P.AgreementTypeName = WT4.AgreementType
		and P.MasterDealerCode = WT4.MasterDealerCode
		and P.Contract = WT4.ContractID
		and P.Market = WT4.MARKETCODE
		and P.SubDealerEntity = 'ALL'
		and P.SalesCode = 'ALL'
		and cast(WT4.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update WT4
set WT4.PayeeAssignID = P.ID
from #TXNsEligibilityWT4 WT4
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'RESIDUAL'
		and P.HighLevelChannel = WT4.ContractHolderChannel
		and P.AgreementTypeName = WT4.AgreementType
		and P.MasterDealerCode = WT4.MasterDealerCode
		and P.Contract = WT4.ContractID
		and P.Market = 'ALL'
		and P.SubDealerEntity = WT4.SubdealerID
		and P.SalesCode = 'ALL'
		and cast(WT4.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update WT4
set WT4.PayeeAssignID = P.ID
from #TXNsEligibilityWT4 WT4
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'RESIDUAL'
		and P.HighLevelChannel = WT4.ContractHolderChannel
		and P.AgreementTypeName = WT4.AgreementType
		and P.MasterDealerCode = WT4.MasterDealerCode
		and P.Contract = WT4.ContractID
		and P.Market = WT4.MARKETCODE
		and P.SubDealerEntity = WT4.SubdealerID
		and P.SalesCode = 'ALL'
		and cast(WT4.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'

update WT4
set WT4.PayeeAssignID = P.ID
from #TXNsEligibilityWT4 WT4
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'RESIDUAL'
		and P.HighLevelChannel = WT4.ContractHolderChannel
		and P.AgreementTypeName = WT4.AgreementType
		and P.MasterDealerCode = WT4.MasterDealerCode
		and P.Contract = WT4.ContractID
		and P.Market = 'ALL'
		and P.SubDealerEntity = WT4.SubdealerID
		and P.SalesCode = WT4.SUBSCRIBERDEALERCODE
		and cast(WT4.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update WT4
set WT4.PayeeAssignID = P.ID
from #TXNsEligibilityWT4 WT4
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'RESIDUAL'
		and P.HighLevelChannel = WT4.ContractHolderChannel
		and P.AgreementTypeName = WT4.AgreementType
		and P.MasterDealerCode = WT4.MasterDealerCode
		and P.Contract = WT4.ContractID
		and P.Market = WT4.MARKETCODE
		and P.SubDealerEntity = WT4.SubdealerID
		and P.SalesCode = WT4.SUBSCRIBERDEALERCODE
		and cast(WT4.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
--select * from #TXNsEligibilityWT4 where ServiceNumber = '5415151171'

------- Process to match ResidualCompGroup Record ------- 

IF OBJECT_ID('tempdb..#TXNsEligibilityWT5') is not Null
drop table #TXNsEligibilityWT5

select *
	, ROW_NUMBER() over (partition by BAN, ServiceNumber,StartDate,CurrentMonth order by case when ProductIDCode <> 'ALL' then 1 else 2 end) as ResidualCGSeq
into #TXNsEligibilityWT5
from (
	select T.*, G.ID as ResidualCGID, G.ProductIDCode ,G.ResidualCompTableCode
	from #TXNsEligibilityWT4 T
		inner join cfgICSCompPayeeAssignments P on T.PayeeAssignID = P.ID
		inner join cfgICSResidualCompGroup G on P.ICSCompGroup = G.ResidualCompGroup
			and G.ProductIDCode = 'ALL'
			and cast(T.MonthEndDate as date) between cast(G.StartDate as date) and cast(G.EndDate as date)
			and G.IsActive = 'Y'
		inner join cfgICSProductCategory PC on G.Level = PC.Level
			and T.AssignPlanCode = PC.ProductIDCode
			and cast(T.MonthEndDate as date) between CAST(PC.StartDate as date) and CAST(PC.EndDate as date)
	where isNull(T.PayeeAssignID,'') <> ''
		--and ServiceNumber = '5415151171'
	union all
	select T.*, G.ID as ResidualCGID, G.ProductIDCode ,G.ResidualCompTableCode
	from #TXNsEligibilityWT4 T
		inner join cfgICSCompPayeeAssignments P on T.PayeeAssignID = P.ID
		inner join cfgICSResidualCompGroup G on P.ICSCompGroup = G.ResidualCompGroup
			and G.ProductIDCode = T.AssignPlanCode
			and cast(T.MonthEndDate as date) between cast(G.StartDate as date) and cast(G.EndDate as date)
			and G.IsActive = 'Y'
			and exists (
				select * from cfgICSProductCategory PC where PC.ProductIDCode = G.ProductIDCode 
					and cast(T.MonthEndDate as date) between CAST(PC.StartDate as date) and CAST(PC.EndDate as date)
					)
	where isNull(T.PayeeAssignID,'') <> ''
	) X
	
--select count(*) from #TXNsEligibilityWT5 where ResidualCGSeq = 1 ServiceNumber = '5415151171'

-------- Tenure Check and Process MRC Logic ------------
IF OBJECT_ID('tempdb..#TXNsEligibilityWT6') is not Null
drop table #TXNsEligibilityWT6

select T.*, P.ID as MRCID, P.ValueText as MRCText
into #TXNsEligibilityWT6
from #TXNsEligibilityWT5 T
	left join cfgICSContractParams P on P.Name = 'MRCRESIDUAL'
		and P.HighLevelChannel = 'ALL'
		and P.AgreementType = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
		and cast(T.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
where ResidualCGSeq = 1
	and exists(		----- Tenure Check
		select * 
		from cfgICSResidualCompDefinition D
		where D.ResidualCompTable = T.ResidualCompTableCode
			and cast(T.MonthEndDate as date) between cast(D.StartDate as date) and cast(D.EndDate as date)
			and cast(T.Tenure as float) between cast(D.MinTenure as float) and cast(D.MaxTenure as float)
			and cast(T.BEGSERVDATE as date) between cast(D.OrigActStartDate as date) and cast(D.OrigActEndDate as date)
			and D.IsActive = 'Y'
		)
--order by CurrentMonth,BAN, SERVICENUMBER

update WT
set WT.MRCID = P.ID, WT.MRCText = P.ValueText
from #TXNsEligibilityWT6 WT
	inner join cfgICSContractParams P on P.Name = 'MRCRESIDUAL'
		and WT.ContractHolderChannel = P.HighLevelChannel
		and P.AgreementType = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
		and cast(WT.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)

update WT
set WT.MRCID = P.ID, WT.MRCText = P.ValueText
from #TXNsEligibilityWT6 WT
	inner join cfgICSContractParams P on P.Name = 'MRCRESIDUAL'
		and WT.ContractHolderChannel = P.HighLevelChannel
		and P.AgreementType = WT.AgreementType
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
		and cast(WT.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		
update WT
set WT.MRCID = P.ID, WT.MRCText = P.ValueText
from #TXNsEligibilityWT6 WT
	inner join cfgICSContractParams P on P.Name = 'MRCRESIDUAL'
		and WT.ContractHolderChannel = P.HighLevelChannel
		and P.AgreementType = WT.AgreementType
		and P.MasterDealerCode = WT.MasterDealerCode
		and P.ContractID = 'ALL'
		and cast(WT.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		
update WT
set WT.MRCID = P.ID, WT.MRCText = P.ValueText
from #TXNsEligibilityWT6 WT
	inner join cfgICSContractParams P on P.Name = 'MRCRESIDUAL'
		and WT.ContractHolderChannel = P.HighLevelChannel
		and P.AgreementType = WT.AgreementType
		and P.MasterDealerCode = WT.MasterDealerCode
		and P.ContractID = WT.ContractID
		and cast(WT.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)

--select * from #TXNsEligibilityWT6

IF OBJECT_ID('tempdb..#PostpaidResidualTXNsEligibility') is not Null
drop table #PostpaidResidualTXNsEligibility

select *
	, case when WT.MRCText = 'POOLING' then WT.PLANMRC
		when WT.MRCText = 'LINE' then WT.LINEMRC
		when WT.MRCText = 'TOTAL' then WT.TotalMRC
		when WT.MRCText = 'BTV' then WT.REDUCEDMRC
	  else '-1' end as MRCValue
into #PostpaidResidualTXNsEligibility
from #TXNsEligibilityWT6 WT

--select * from #PostpaidResidualTXNsEligibility order by CurrentMonth, BAN,SERVICENUMBER 

/******************************************************************************
*                                                                             *
*                  Positive Scenarios Test Result                             *
*                                                                             *
******************************************************************************/

--DEL0300	Residual PostPaid - Comp Sellingpoint, Market & Contract Setup, MRCSelection = PLANMRC		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			None of the parameters are set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on sellingpoint, market & contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from the cfgICSContractParms table where HighlevelChannel, agreementtype,contract and masterdealer are setup with values.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.PLANMRC


select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market 
	and ISNULL(T.ADDALINESOC,'') = ''				------Not Addline
	and T.IncludeFlag like 'Contract:%'				------None of the parameters are set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value
	and C.SalesCode <> 'ALL'						------Compensation levelGroup based on sellingpoint, market & contract setup
		and C.SubDealerEntity <> 'ALL'
		and C.Market <> 'ALL'		
		and C.Contract <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.AgreementTypeName <> 'ALL'
		and C.HighLevelChannel <> 'ALL'
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from the cfgICSContractParms table where HighlevelChannel, agreementtype,contract and masterdealer are setup with values.
		and P.AgreementType <> 'ALL'
		and P.MasterDealerCode <> 'ALL'
		and P.ContractID <> 'ALL'
	and P.ValueText = 'POOLING'						------PLANMRC
	
--DEL0301	Residual PostPaid - Comp Sellingpoint & Contract Setup, MRCSelection = TotalMRC		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on sellingpoint & contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from the cfgICSContractParms table where contractID and masterdealer are set to ALL.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.TotalMRC

select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market 
	and ISNULL(T.ADDALINESOC,'') = ''				------Not Addline
	and T.IncludeFlag like 'MasterDealer:%'			------ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value.
	and C.SalesCode <> 'ALL'						------Compensation levelGroup based on sellingpoint & contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
		and C.SubDealerEntity <> 'ALL'
		and C.Market = 'ALL'		
		and C.Contract <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.AgreementTypeName <> 'ALL'
		and C.HighLevelChannel <> 'ALL'
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from the cfgICSContractParms table where contractID and masterdealer are set to ALL.
		and P.AgreementType <> 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
	and P.ValueText = 'TOTAL'						------TotalMRC
	
--DEL0302	Residual PostPaid - Comp SDE, Market & Contract Setup, MRCSelection = REDUCEDMRC		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			Masterdealercode &contractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on SDE, market & Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from cfgICSContractParms table where agreementtype, contractID and masterdealer are set to ALL.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.REDUCEDMRC

select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market 
	and ISNULL(T.ADDALINESOC,'') = ''				------Not Addline
	and T.IncludeFlag like 'AgreementType:%'		------Masterdealercode &contractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value.
	and C.SalesCode = 'ALL'						------Compensation levelGroup based on SDE, market & Contract setup for postpaid residual
		and C.SubDealerEntity <> 'ALL'
		and C.Market <> 'ALL'		
		and C.Contract <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.AgreementTypeName <> 'ALL'
		and C.HighLevelChannel <> 'ALL'
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from the cfgICSContractParms table where contractID and masterdealer are set to ALL.
		and P.AgreementType <> 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
	and P.ValueText = 'BTV'							------REDUCEDMRC
	
--DEL0303	Residual PostPaid - Comp SDE Setup, MRCSelection = LINEMRC		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			AgreementType, Masterdealercode &contractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on SDE setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from cfgICSContractParms table where contractID is set to ALL.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.LINEMRC

select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market 
	and ISNULL(T.ADDALINESOC,'') = ''				------Not Addline
	and T.IncludeFlag like 'HLC:%'					------AgreementType, Masterdealercode &contractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value.
	and C.SalesCode = 'ALL'						------Compensation levelGroup based on SDE setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table
		and C.SubDealerEntity <> 'ALL'
		and C.Market = 'ALL'		
		and C.Contract <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.AgreementTypeName <> 'ALL'
		and C.HighLevelChannel <> 'ALL'
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from cfgICSContractParms table where contractID is set to ALL.
		and P.AgreementType <> 'ALL'
		and P.MasterDealerCode <> 'ALL'
		and P.ContractID = 'ALL'
	and P.ValueText = 'LINE'						------LINEMRC
	

--DEL0304	Residual PostPaid - Comp Market & Contract Setup, MRCSelection = PLANMRC		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			Retrieve value of the “ClosedDoorResidual” parameter from the cfgICSGlobal table. Check if the dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on market & Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from the cfgICSContractParms table where HighlevelChannel, agreementtype,contract and masterdealer are setup with values.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.PLANMRC

select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market 
	and ISNULL(T.ADDALINESOC,'') = ''				------Not Addline
	and T.IncludeFlag like 'GLOBLE:%'				------Retrieve value of the “ClosedDoorResidual” parameter from the cfgICSGlobal table
	and C.SalesCode = 'ALL'							------Compensation levelGroup based on market & Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
		and C.SubDealerEntity = 'ALL'
		and C.Market <> 'ALL'		
		and C.Contract <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.AgreementTypeName <> 'ALL'
		and C.HighLevelChannel <> 'ALL'
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from the cfgICSContractParms table where HighlevelChannel, agreementtype,contract and masterdealer are setup with values.
		and P.AgreementType <> 'ALL'
		and P.MasterDealerCode <> 'ALL'
		and P.ContractID <> 'ALL'
	and P.ValueText = 'POOLING'						------PLANMRC
	

--DEL0305	Residual PostPaid - Comp Contract Setup, MRCSelection = TotalMRC		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from the cfgICSContractParms table where contractID and masterdealer are set to ALL.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.TotalMRC

select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market 
	and ISNULL(T.ADDALINESOC,'') = ''				------Not Addline
	and T.IncludeFlag like 'GLOBLE:%'				------ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value.
	and C.HighLevelChannel <> 'ALL'					------Compensation levelGroup based on Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
		and C.AgreementTypeName <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.Contract <> 'ALL'
		and C.Market = 'ALL'
		and C.SubDealerEntity = 'ALL'
		and C.SalesCode = 'ALL'							
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from the cfgICSContractParms table where contractID and masterdealer are set to ALL.
		and P.AgreementType <> 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
	and P.ValueText = 'TOTAL'						------TotalMRC
	

--DEL0306	Residual PostPaid - Comp MasterDealer, MRCSelection = REDUCEDMRC		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			Masterdealercode &contractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on MasterDealer setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from cfgICSContractParms table where agreementtype, contractID and masterdealer are set to ALL.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.REDUCEDMRC


select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market 
	and ISNULL(T.ADDALINESOC,'') = ''				------Not Addline
	and T.IncludeFlag like 'AgreementType:%'		------Masterdealercode &contractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value.
	and C.HighLevelChannel <> 'ALL'					------Compensation levelGroup based on MasterDealer setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table  
		and C.AgreementTypeName <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.Contract = 'ALL'		
		and C.Market = 'ALL'
		and C.SubDealerEntity = 'ALL'
		and C.SalesCode = 'ALL'					
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from cfgICSContractParms table where agreementtype, contractID and masterdealer are set to ALL.
		and P.AgreementType = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
	and P.ValueText = 'BTV'							------REDUCEDMRC
	
--DEL0307	Residual PostPaid - Comp AgreementType Setup, MRCSelection = LINEMRC		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			AgreementType, Masterdealercode &contractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on AgreementType setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from cfgICSContractParms table where contractID is set to ALL.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.LINEMRC


select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market 
	and ISNULL(T.ADDALINESOC,'') = ''				------Not Addline
	and T.IncludeFlag like 'HLC:%'					------AgreementType, Masterdealercode &contractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value.
	and C.HighLevelChannel <> 'ALL'					------Compensation levelGroup based on AgreementType setup for postpaid residual  
		and C.AgreementTypeName <> 'ALL'
		and C.MasterDealerCode = 'ALL'
		and C.Contract = 'ALL'		
		and C.Market = 'ALL'
		and C.SubDealerEntity = 'ALL'
		and C.SalesCode = 'ALL'					
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from cfgICSContractParms table where contractID is set to ALL.
		and P.AgreementType <> 'ALL'
		and P.MasterDealerCode <> 'ALL'
		and P.ContractID = 'ALL'
	and P.ValueText = 'LINE'						------LINEMRC
	
--DEL0308	Residual PostPaid - Comp HighLevelChannel Setup, MRCSelection = PLANMRC		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			Retrieve value of the “ClosedDoorResidual” parameter from the cfgICSGlobal table. Check if the dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on HighLevelChannel setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from the cfgICSContractParms table where HighlevelChannel, agreementtype,contract and masterdealer are setup with values.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.PLANMRC

select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market 
	and ISNULL(T.ADDALINESOC,'') = ''				------Not Addline
	and T.IncludeFlag like 'GLOBLE:%'				------Retrieve value of the “ClosedDoorResidual” parameter from the cfgICSGlobal table
	and C.HighLevelChannel <> 'ALL'					------Compensation levelGroup based on HighLevelChannel setup for postpaid residual  
		and C.AgreementTypeName = 'ALL'
		and C.MasterDealerCode = 'ALL'
		and C.Contract = 'ALL'		
		and C.Market = 'ALL'
		and C.SubDealerEntity = 'ALL'
		and C.SalesCode = 'ALL'					
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from the cfgICSContractParms table where HighlevelChannel, agreementtype,contract and masterdealer are setup with values.
		and P.AgreementType <> 'ALL'
		and P.MasterDealerCode <> 'ALL'
		and P.ContractID <> 'ALL'
	and P.ValueText = 'POOLING'						------PLANMRC
	
--DEL0309	Residual PostPaid - Comp Contract Setup, Phantom Market		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Phantom  or UDF (user defined\phantom markets ) market
--			ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from the cfgICSContractParms table where contractID and masterdealer are set to ALL.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.TotalMRC

select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE  like '%[0-9]'					------Contract is for a Phantom  or UDF (user defined\phantom markets ) market
	and ISNULL(T.ADDALINESOC,'') = ''				------Not Addline
	and T.IncludeFlag like 'MasterDealer:%'			------ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value.
	and C.HighLevelChannel <> 'ALL'					------Compensation levelGroup based on Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table  
		and C.AgreementTypeName <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.Contract <> 'ALL'		
		and C.Market = 'ALL'
		and C.SubDealerEntity = 'ALL'
		and C.SalesCode = 'ALL'					
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from the cfgICSContractParms table where contractID and masterdealer are set to ALL
		and P.AgreementType <> 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
	and P.ValueText = 'TOTAL'						------TotalMRC
	

--DEL0310	Residual PostPaid - Comp Contract Setup, Override value is defined for the “ClosedDoorResidual” parameter 		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is defined for the “ClosedDoorResidual” parameter 
--			Product is Commissionable
--			Compensation levelGroup based on Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from the cfgICSContractParms table where HighlevelChannel, agreementtype,contract and masterdealer are setup with values.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.PLANMRC


/* Need to get clear with Paul*/


--DEL0311	Residual PostPaid - Comp Contract Setup, Override value is defined for the “ClosedDoorResidual” parameter  from “cfgICSGlobal ”		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is defined for the “ClosedDoorResidual” parameter  from “cfgICSGlobal ”
--			Product is Commissionable
--			Compensation levelGroup based on Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from cfgICSContractParms table where agreementtype, contractID and masterdealer are set to ALL.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.REDUCEDMRC


/* Need to get clear with Paul*/


--DEL0312	Residual PostPaid - Comp Contract Setup, Product Level = Defined at Soc Level		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from cfgICSContractParms table where contractID is set to ALL.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.LINEMRC


select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market
	and ISNULL(T.ADDALINESOC,'') = ''				------Not Addline
	and T.IncludeFlag like 'MasterDealer:%'			------ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value.
	and C.HighLevelChannel <> 'ALL'					------Compensation levelGroup based on Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table  
		and C.AgreementTypeName <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.Contract <> 'ALL'		
		and C.Market = 'ALL'
		and C.SubDealerEntity = 'ALL'
		and C.SalesCode = 'ALL'					
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from the cfgICSContractParms table where contractID and masterdealer are set to ALL
		and P.AgreementType <> 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
	and P.ValueText = 'LINE'						------LINEMRC
	

--DEL0313	Residual PostPaid - Comp Contract Setup, MRCSelection = cfgICSGlobal		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value defined in the cfgICSGlobal table
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = parameter value defined in the cfgICSGlobal table

select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market
	and ISNULL(T.ADDALINESOC,'') = ''				------Not Addline
	and T.IncludeFlag like 'MasterDealer:%'			------ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value.
	and C.HighLevelChannel <> 'ALL'					------Compensation levelGroup based on Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table  
		and C.AgreementTypeName <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.Contract <> 'ALL'		
		and C.Market = 'ALL'
		and C.SubDealerEntity = 'ALL'
		and C.SalesCode = 'ALL'					
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel = 'ALL'					------“MRCSelection” parameter value defined in the cfgICSGlobal table
		and P.AgreementType = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'


--DEL0314	Residual PostPaid AddALine - Comp Sellingpoint, Market & Contract Setup, MRCSelection = PLANMRC		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			None of the parameters are set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on sellingpoint, market & contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from the cfgICSContractParms table where HighlevelChannel, agreementtype,contract and masterdealer are setup with values.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.PLANMRC


select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market
	and ISNULL(T.ADDALINESOC,'') <> ''				------Addline
	and T.IncludeFlag like 'Contract:%'				------None of the parameters are set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value.
	and C.HighLevelChannel <> 'ALL'					------Compensation levelGroup based on sellingpoint, market & contract setup for postpaid residual  
		and C.AgreementTypeName <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.Contract <> 'ALL'		
		and C.Market <> 'ALL'
		and C.SubDealerEntity <> 'ALL'
		and C.SalesCode <> 'ALL'					
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from the cfgICSContractParms table where HighlevelChannel, agreementtype,contract and masterdealer are setup with values.
		and P.AgreementType <> 'ALL'
		and P.MasterDealerCode <> 'ALL'
		and P.ContractID <> 'ALL'
	and P.ValueText = 'POOLING'						------PLANMRC
	

--DEL0315	Residual PostPaid AddALine - Comp Sellingpoint & Contract Setup, MRCSelection = TotalMRC		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on sellingpoint & contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from the cfgICSContractParms table where contractID and masterdealer are set to ALL.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.TotalMRC

select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market
	and ISNULL(T.ADDALINESOC,'') <> ''				------Addline
	and T.IncludeFlag like 'MasterDealer:%'			------ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value.
	and C.HighLevelChannel <> 'ALL'					------Compensation levelGroup based on sellingpoint & contract setup for postpaid residual  
		and C.AgreementTypeName <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.Contract <> 'ALL'		
		and C.Market = 'ALL'
		and C.SubDealerEntity <> 'ALL'
		and C.SalesCode <> 'ALL'					
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from the cfgICSContractParms table where contractID and masterdealer are set to ALL.
		and P.AgreementType <> 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
	and P.ValueText = 'TOTAL'						------TotalMRC
	

--DEL0316	Residual PostPaid AddALine - Comp SDE, Market & Contract Setup, MRCSelection = REDUCEDMRC		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			Masterdealercode &contractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on SDE, market & Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from cfgICSContractParms table where agreementtype, contractID and masterdealer are set to ALL.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.REDUCEDMRC

select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market
	and ISNULL(T.ADDALINESOC,'') <> ''				------Addline
	and T.IncludeFlag like 'AgreementType:%'		------Masterdealercode &contractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value.
	and C.HighLevelChannel <> 'ALL'					------Compensation levelGroup based on SDE, market & Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table   
		and C.AgreementTypeName <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.Contract <> 'ALL'		
		and C.Market <> 'ALL'
		and C.SubDealerEntity <> 'ALL'
		and C.SalesCode <> 'ALL'					
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from cfgICSContractParms table where agreementtype, contractID and masterdealer are set to ALL.
		and P.AgreementType = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
	and P.ValueText = 'BTV'							------REDUCEDMRC
	
--DEL0317	Residual PostPaid AddALine - Comp SDE Setup, MRCSelection = LINEMRC		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			AgreementType, Masterdealercode &contractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on SDE setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from cfgICSContractParms table where contractID is set to ALL.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.LINEMRC

select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market
	and ISNULL(T.ADDALINESOC,'') <> ''				------Addline
	and T.IncludeFlag like 'HLC:%'					------AgreementType, Masterdealercode &contractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value.
	and C.HighLevelChannel <> 'ALL'					------Compensation levelGroup based on SDE setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table   
		and C.AgreementTypeName <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.Contract <> 'ALL'		
		and C.Market = 'ALL'
		and C.SubDealerEntity <> 'ALL'
		and C.SalesCode = 'ALL'					
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from cfgICSContractParms table where contractID is set to ALL.
		and P.AgreementType <> 'ALL'
		and P.MasterDealerCode <> 'ALL'
		and P.ContractID = 'ALL'
	and P.ValueText = 'LINE'						------LINEMRC
	

--DEL0318	Residual PostPaid AddALine - Comp Contract Setup, Phantom Market		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Phantom  or UDF (user defined\phantom markets ) market
--			ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from the cfgICSContractParms table where contractID and masterdealer are set to ALL.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.TotalMRC


select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE like '%[0-9]'					------Contract is for a Phantom  or UDF (user defined\phantom markets ) market
	and ISNULL(T.ADDALINESOC,'') <> ''				------Addline
	and T.IncludeFlag like 'MasterDealer:%'			------ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value.
	and C.HighLevelChannel <> 'ALL'					------Compensation levelGroup based on Contract setup for postpaid residual   
		and C.AgreementTypeName <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.Contract <> 'ALL'		
		and C.Market = 'ALL'
		and C.SubDealerEntity = 'ALL'
		and C.SalesCode = 'ALL'					
	and T.ProductIDCode = 'ALL'						------Residual CompSetup Product Level NOT Defined at Soc Level
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from the cfgICSContractParms table where contractID and masterdealer are set to ALL.
		and P.AgreementType <> 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'
	and P.ValueText = 'TOTAL'						------TotalMRC
	
--DEL0319	Residual PostPaid AddALine - Comp Contract Setup, Override value is defined for the “ClosedDoorResidual” parameter 		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is defined for the “ClosedDoorResidual” parameter 
--			Product is Commissionable
--			Compensation levelGroup based on Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from the cfgICSContractParms table where HighlevelChannel, agreementtype,contract and masterdealer are setup with values.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.PLANMRC

/* Need to get clear with Paul*/

--DEL0320	Residual PostPaid AddALine - Comp Contract Setup, Override value is defined for the “ClosedDoorResidual” parameter  from “cfgICSGlobal ”		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is defined for the “ClosedDoorResidual” parameter  from “cfgICSGlobal ”
--			Product is Commissionable
--			Compensation levelGroup based on Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from cfgICSContractParms table where agreementtype, contractID and masterdealer are set to ALL.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.REDUCEDMRC

/* Need to get clear with Paul*/


--DEL0321	Residual PostPaid AddALine - Comp Contract Setup, Product Level = Defined at Soc Level		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value from cfgICSContractParms table where contractID is set to ALL.
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = tsdICSSubscriberBase.LINEMRC

select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market 
	and ISNULL(T.ADDALINESOC,'') <> ''				------Addline
	and T.IncludeFlag like 'MasterDealer:%'			------ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value.
	and C.HighLevelChannel <> 'ALL'					------Compensation levelGroup based on Contract setup for postpaid residual   
		and C.AgreementTypeName <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.Contract <> 'ALL'		
		and C.Market = 'ALL'
		and C.SubDealerEntity = 'ALL'
		and C.SalesCode = 'ALL'					
	and T.ProductIDCode <> 'ALL'					------Residual CompSetup Product Level Defined at Soc Level (Level 1, 2, etc)
	and P.HighLevelChannel <> 'ALL'					------“MRCSelection” parameter value from cfgICSContractParms table where contractID is set to ALL.
		and P.AgreementType <> 'ALL'
		and P.MasterDealerCode <> 'ALL'
		and P.ContractID = 'ALL'
	and P.ValueText = 'LINE'						------LINEMRC
	
--DEL0322	Residual PostPaid AddALine - Comp Contract Setup, MRCSelection = cfgICSGlobal		
--		Preconditions	
--			Records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals
--			Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is within this max tenure limit
--			Contract is for a Samson market 
--			ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value. Dealercode status is “inactive” and status reason is “Location closed” in the table “cfgICSSalesCode”
--			Override value is NOT defined.
--			Product is Commissionable
--			Compensation levelGroup based on Contract setup for postpaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Residual CompSetup Product Level NOT Defined at Soc Level (Level 1, 2, etc)
--			“MRCSelection” parameter value defined in the cfgICSGlobal table
			
--		Expected	Transaction is Eligible
--			MRC for residual eligible transactions = parameter value defined in the cfgICSGlobal table


select * 
from #PostpaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
	inner join cfgICSContractParams P on T.MRCID = P.ID
where T.MARKETCODE not like '%[0-9]'				------Contract is for a Samson market 
	and ISNULL(T.ADDALINESOC,'') <> ''				------Addline
	and T.IncludeFlag like 'MasterDealer:%'			------ContractID is set to “ALL” in  cfgICSContractParms table for  “ClosedDoorResidual” value.
	and C.HighLevelChannel <> 'ALL'					------Compensation levelGroup based on Contract setup for postpaid residual   
		and C.AgreementTypeName <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.Contract <> 'ALL'		
		and C.Market = 'ALL'
		and C.SubDealerEntity = 'ALL'
		and C.SalesCode = 'ALL'					
	and T.ProductIDCode <> 'ALL'					------Residual CompSetup Product Level Defined at Soc Level (Level 1, 2, etc)
	and P.HighLevelChannel = 'ALL'					------“MRCSelection” parameter value defined in the cfgICSGlobal table
		and P.AgreementType = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.ContractID = 'ALL'


/******************************************************************************
*                                                                             *
*                  Negative Scenarios Test Result                             *
*                                                                             *
******************************************************************************/

--DEL0350N	Residual PostPaid NO records in subscriberbase data from tsdICSSubscriberBase table for the MasterDealer/SalesCode we are calculating residuals		

/***??????*****/

--DEL0351N	Residual PostPaid Dealer Code not found		

select DATEDIFF(MM,CAST(BEGSERVDATE as date), MonthStartDate) as Tenure 
	,B.*, D.DealerName, D.SubDealerID,D.ContractHolderID, D.ContractID, D.MasterDealerCode, D.ContractChannel, D.ContractHolderChannel, D.ChannelType, D.AgreementType, D.CurrentMonth
	, D.MonthStartDate, D.MonthEndDate, M.NPANXX as MKTNPANXX, M.StartDate as MKTStartDate, M.EndDate as MKTEndDate
from tsdICSSubscriberBase B
	left join #DealerMonthlyEligibility D on B.SUBSCRIBERDEALERCODE = D.SalesCode
		and cast(B.STARTDATE as date) <= D.MonthStartDate  and cast(B.ENDDATE as date) >= D.MonthEndDate	----- Varicent Logic
		--and cast(B.STARTDATE as date) <= D.MonthEndDate and cast(B.ENDDATE as date) >= D.MonthEndDate		----- Correct Logic should be used
where D.SalesCode is null

--DEL0352N	Residual PostPaid Tenure of the subscriber based on the “BegServDate” column of the tsdICSSubscriberBase table. Calculate max tenure setup by the business for the contract based on “ResidualCompTable” table. Tenure calculated in previous step is NOT within this max tenure 		

select distinct T.*
from #TXNsEligibilityWT5 T
where ResidualCGSeq = 1
	and not exists(		----- Tenure Check
		select * 
		from cfgICSResidualCompDefinition D
		where D.ResidualCompTable = T.ResidualCompTableCode
			and cast(T.MonthEndDate as date) between cast(D.StartDate as date) and cast(D.EndDate as date)
			and cast(T.Tenure as float) between cast(D.MinTenure as float) and cast(D.MaxTenure as float)
			and cast(T.BEGSERVDATE as date) between cast(D.OrigActStartDate as date) and cast(D.OrigActEndDate as date)
			and D.IsActive = 'Y'
		)
		
--DEL0353N	Residual PostPaid Contract based not found on “ResidualCompTable” table.	

/***We don't need this one*****/


--DEL0354N	Residual PostPaid Compensation not setup in  cfgICSContractParms for AgreementType, Masterdealercode &contractID		

select * 
from #TXNsEligibilityWT2
where isnull(IncludeFlag,'')=''


--DEL0355N	Residual PostPaid Product is NOT Commissionable		

select distinct X.* 
from (
	select T.*
		,S.CompEffStartDate,S.CompEffEndDate,S.SalesCodeDeactDate,S.Status as SalesCodeStatus,S.StatusCode,S.StatusReason,'Regular' as IncludeFlag
		,case when ISNULL(T.ADDALINESOC,'') <> '' then T.ADDALINESOC else T.PLANCODE end as AssignPlanCode 
	from #TXNsEligibilityWT1 T
		left join cfgICSSalesCode S on T.SUBSCRIBERDEALERCODE = S.SalesCode
			and T.ContractHolderID = S.ContractHolderID
			and S.Status = 'Inactive' and S.StatusReason = 'Location Closed'
			and cast(T.MonthEndDate as date) >= cast(S.SalesCodeDeactDate as date) 
	where S.SalesCode is null
	UNION
	select * 
		,case when ISNULL(ADDALINESOC,'') <> '' then ADDALINESOC else PLANCODE end as AssignPlanCode 
	from #TXNsEligibilityWT2
	where isnull(IncludeFlag,'')<>''
	) X 
	left join #ProductEligibility P on X.AssignPlanCode = P.ProductIDCode
		and X.CurrentMonth = P.CurrentMonth
		and P.BillingSubsystemID = '1'	--- Only for PostPaid
where P.ProductIDCode is null


--DEL0356N	Residual PostPaid Residual CompSetup NOT found		

select * from #TXNsEligibilityWT4 where Isnull(PayeeAssignID,'') = ''

--DEL0357N	Residual PostPaid MRCSelection parameter NOT setup		

select *
from #PostpaidResidualTXNsEligibility
where MRCValue = '-1'
