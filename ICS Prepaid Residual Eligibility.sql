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

/*************************************************************
*             MasterDealer without Contract                  *
*         #MasterDealerNoContract has all eligible records   *
**************************************************************/
IF OBJECT_ID('tempdb..#Month') is not Null
drop table #Month

select CurrentMonth,MIN(CAST(Date as date)) as StartDate, MAX(CAST(Date as date)) as EndDate
into #Month
from cfgDateString
group by CurrentMonth

-----Contract EOM Status------
IF OBJECT_ID('tempdb..#ContractStatus') is not Null
drop table #ContractStatus

select M.CurrentMonth,M.StartDate as MonthStartDate,M.EndDate as MonthEndDate,S.Eligibility,C.* 
into #ContractStatus
from cfgICSContract C
	inner join #Month M on (
		CAST(C.CompEffStartDate as date) <= CAST(M.EndDate as date)
		and CAST(C.CompEffEndDate as date) >= CAST(M.EndDate as date)
		OR
		CAST(C.CompEffStartDate as date) >= CAST(M.StartDate as date)
		and CAST(C.CompEffEndDate as date) <= CAST(M.EndDate as date)
		)
	inner join cfgICSTCMStatus S on C.StatusCode = S.StatusCode
		and CAST(S.EndDate as date) >= CAST(M.EndDate as date)
		and CAST(M.EndDate as date) >= CAST(S.StartDate as date)
		--and S.Eligibility = '1.00' 
where 1=1
	and cast(M.StartDate as date) >= '2013-01-01' and CAST(M.EndDate as date) <= '2014-12-31'


-----Contract Holder EOM Status------
IF OBJECT_ID('tempdb..#ContractHolderStatus') is not Null
drop table #ContractHolderStatus

select M.CurrentMonth,M.StartDate as MonthStartDate,M.EndDate as MonthEndDate,S.Eligibility,H.* 
into #ContractHolderStatus
from cfgICSContractHolder H
	inner join #Month M on (
		CAST(H.CompEffStartDate as date) <= CAST(M.EndDate as date)
		and CAST(H.CompEffEndDate as date) >= CAST(M.EndDate as date)
		OR
		CAST(H.CompEffStartDate as date) >= CAST(M.StartDate as date)
		and CAST(H.CompEffEndDate as date) <= CAST(M.EndDate as date)
		)
	inner join cfgICSTCMStatus S on H.StatusCode = S.StatusCode
		and CAST(S.EndDate as date) >= CAST(M.EndDate as date)
		and CAST(M.EndDate as date) >= CAST(S.StartDate as date)
		--and S.Eligibility = '1.00' 
where 1=1
	and cast(M.StartDate as date) >= '2013-01-01' and CAST(M.EndDate as date) <= '2014-12-31'


-----Sales Codes EOM Status------
IF OBJECT_ID('tempdb..#SalesCodesStatus') is not Null
drop table #SalesCodesStatus

select M.CurrentMonth,M.StartDate as MonthStartDate,M.EndDate as MonthEndDate,S.Eligibility,SC.* 
into #SalesCodesStatus
from cfgICSSalesCode SC
	inner join #Month M on (
		CAST(SC.CompEffStartDate as date) <= CAST(M.EndDate as date)
		and CAST(SC.CompEffEndDate as date) >= CAST(M.EndDate as date)
		OR
		CAST(SC.CompEffStartDate as date) >= CAST(M.StartDate as date)
		and CAST(SC.CompEffEndDate as date) <= CAST(M.EndDate as date)
		)
	inner join cfgICSTCMStatus S on SC.StatusCode = S.StatusCode
		and CAST(S.EndDate as date) >= CAST(M.EndDate as date)
		and CAST(M.EndDate as date) >= CAST(S.StartDate as date)
		--and S.Eligibility = '1.00' 
where 1=1
	and cast(M.StartDate as date) >= '2013-01-01' and CAST(M.EndDate as date) <= '2014-12-31'

-----Master Dealer without Contract------
IF OBJECT_ID('tempdb..#MasterDealerNoContract') is not Null
drop table #MasterDealerNoContract

select Distinct S.CurrentMonth, S.MonthStartDate, S.MonthEndDate, S.ContractHolderID, S.ContractID, H.MasterDealerCode, S.SalesCode, H.Channel, H.ChannelType
into #MasterDealerNoContract
from #SalesCodesStatus S
	inner join #ContractHolderStatus H on H.ContractHolderID = S.ContractHolderID
		and H.CurrentMonth = S.CurrentMonth
		and H.MasterDealerCode = S.SalesCode
	--inner join #ContractStatus C on S.ContractHolderID = C.ContractHolderID
	--	and C.CurrentMonth = S.CurrentMonth
where S.ContractID = ''
	and S.MonthStartDate between '2013-01-01' and '2014-03-31'
	
--select * from #MasterDealerNoContract

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
*  #PrepaidResidualTXNsEligibility has all eligible records    *
****************************************************************/

----- Process Dealer Logic -----

IF OBJECT_ID('tempdb..#TXNsEligibilityWT1') is not Null
drop table #TXNsEligibilityWT1

select R.*, D.DealerName, D.SubDealerID,D.ContractHolderID, D.ContractID, D.MasterDealerCode, D.ContractChannel, D.ContractHolderChannel, D.ChannelType, D.AgreementType, D.CurrentMonth
	, D.MonthStartDate, D.MonthEndDate
	, case when D.SalesCode IS null then '0' else '1' end as DealerFlag
into #TXNsEligibilityWT1
from tsdRefill R
	left join #DealerMonthlyEligibility D on R.DealerCode = D.SalesCode
		and cast(R.RefillDate as date) between D.MonthStartDate  and D.MonthEndDate	
--where cast(R.RefillDate as date) between '2013-04-01' and '2013-07-31'
--select * from #TXNsEligibilityWT1 where TransactionID = '3181662780'

----- Process Master Dealer Logic and apply Product commissionable logic -----

IF OBJECT_ID('tempdb..#TXNsEligibilityWT2') is not Null
drop table #TXNsEligibilityWT2

select X.*, P.BillingSubsystemID 
into #TXNsEligibilityWT2
from (
	select TransactionID, EventID, SubscriberID, ServiceNo,	ActivationDate,	RefillDate,	NPANXX,	IMEI
		, IMEI14, TACCode, BAN, SubscriberStatus, MarketCode, SIM, FirstName, LastName,	DealerCode,	RefillType,	RefillChannel
		, RatePlanCode,	AcctSubType,RefillAmt, BrandCode, PaymentVendorID, PaymentVendorTrxID, TransactionDate,	JobLogID, RefillReceivedDate
		, DealerName, SubDealerID,M.ContractHolderID, M.ContractID, M.MasterDealerCode, ContractChannel,M.Channel as ContractHolderChannel, M.ChannelType, AgreementType
		, M.CurrentMonth, M.MonthStartDate,M.MonthEndDate, DealerFlag 
	from #TXNsEligibilityWT1 T
		inner join #MasterDealerNoContract M on T.DealerCode = M.SalesCode
			and cast(T.RefillDate as date) between M.MonthStartDate and M.MonthEndDate
	where DealerFlag = '0'
	Union All
	select TransactionID, EventID, SubscriberID, ServiceNo,	ActivationDate,	RefillDate,	NPANXX,	IMEI
		, IMEI14, TACCode, BAN, SubscriberStatus, MarketCode, SIM, FirstName, LastName,	DealerCode,	RefillType,	RefillChannel
		, RatePlanCode,	AcctSubType,RefillAmt, BrandCode, PaymentVendorID, PaymentVendorTrxID, TransactionDate,	JobLogID, RefillReceivedDate
		, DealerName, SubDealerID, ContractHolderID, ContractID, MasterDealerCode, ContractChannel, ContractHolderChannel, ChannelType, AgreementType
		, CurrentMonth,	MonthStartDate,	MonthEndDate, DealerFlag
	from #TXNsEligibilityWT1 T
	where T.DealerFlag = '1'
	) X
	inner join #ProductEligibility P on X.RatePlanCode = P.ProductIDCode
		and X.CurrentMonth = P.CurrentMonth
		and P.BillingSubsystemID in ('2','5')	--- Only for PostPaid
--where TransactionID = '3181662780'
--order by TransactionID


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

IF OBJECT_ID('tempdb..#TXNsEligibilityWT3') is not Null
drop table #TXNsEligibilityWT3

select WT2.*, cast(P.ID as varchar(50)) as PayeeAssignID
into #TXNsEligibilityWT3
from #TXNsEligibilityWT2 WT2
	left join cfgICSCompPayeeAssignments P on P.EventType = 'PREPAID RESIDUAL'
		and P.HighLevelChannel = 'ALL'
		and P.AgreementTypeName = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.Contract = 'ALL'
		and P.Market = 'ALL'
		and P.SubDealerEntity = 'ALL'
		and P.SalesCode = 'ALL'
		and cast(WT2.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update WT3
set WT3.PayeeAssignID = P.ID
from #TXNsEligibilityWT3 WT3
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'PREPAID RESIDUAL'
		and P.HighLevelChannel = WT3.ContractHolderChannel
		and P.AgreementTypeName = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.Contract = 'ALL'
		and P.Market = 'ALL'
		and P.SubDealerEntity = 'ALL'
		and P.SalesCode = 'ALL'
		and cast(WT3.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'

update WT3
set WT3.PayeeAssignID = P.ID
from #TXNsEligibilityWT3 WT3
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'PREPAID RESIDUAL'
		and P.HighLevelChannel = WT3.ContractHolderChannel
		and P.AgreementTypeName = WT3.AgreementType
		and P.MasterDealerCode = 'ALL'
		and P.Contract = 'ALL'
		and P.Market = 'ALL'
		and P.SubDealerEntity = 'ALL'
		and P.SalesCode = 'ALL'
		and cast(WT3.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update WT3
set WT3.PayeeAssignID = P.ID
from #TXNsEligibilityWT3 WT3
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'PREPAID RESIDUAL'
		and P.HighLevelChannel = WT3.ContractHolderChannel
		and P.AgreementTypeName = WT3.AgreementType
		and P.MasterDealerCode = WT3.MasterDealerCode
		and P.Contract = 'ALL'
		and P.Market = 'ALL'
		and P.SubDealerEntity = 'ALL'
		and P.SalesCode = 'ALL'
		and cast(WT3.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update WT3
set WT3.PayeeAssignID = P.ID
from #TXNsEligibilityWT3 WT3
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'PREPAID RESIDUAL'
		and P.HighLevelChannel = WT3.ContractHolderChannel
		and P.AgreementTypeName = WT3.AgreementType
		and P.MasterDealerCode = WT3.MasterDealerCode
		and P.Contract = WT3.ContractID
		and P.Market = 'ALL'
		and P.SubDealerEntity = 'ALL'
		and P.SalesCode = 'ALL'
		and cast(WT3.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update WT3
set WT3.PayeeAssignID = P.ID
from #TXNsEligibilityWT3 WT3
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'PREPAID RESIDUAL'
		and P.HighLevelChannel = WT3.ContractHolderChannel
		and P.AgreementTypeName = WT3.AgreementType
		and P.MasterDealerCode = WT3.MasterDealerCode
		and P.Contract = WT3.ContractID
		and P.Market = WT3.MARKETCODE
		and P.SubDealerEntity = 'ALL'
		and P.SalesCode = 'ALL'
		and cast(WT3.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update WT3
set WT3.PayeeAssignID = P.ID
from #TXNsEligibilityWT3 WT3
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'PREPAID RESIDUAL'
		and P.HighLevelChannel = WT3.ContractHolderChannel
		and P.AgreementTypeName = WT3.AgreementType
		and P.MasterDealerCode = WT3.MasterDealerCode
		and P.Contract = WT3.ContractID
		and P.Market = 'ALL'
		and P.SubDealerEntity = WT3.SubdealerID
		and P.SalesCode = 'ALL'
		and cast(WT3.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update WT3
set WT3.PayeeAssignID = P.ID
from #TXNsEligibilityWT3 WT3
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'PREPAID RESIDUAL'
		and P.HighLevelChannel = WT3.ContractHolderChannel
		and P.AgreementTypeName = WT3.AgreementType
		and P.MasterDealerCode = WT3.MasterDealerCode
		and P.Contract = WT3.ContractID
		and P.Market = WT3.MARKETCODE
		and P.SubDealerEntity = WT3.SubdealerID
		and P.SalesCode = 'ALL'
		and cast(WT3.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'

update WT3
set WT3.PayeeAssignID = P.ID
from #TXNsEligibilityWT3 WT3
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'PREPAID RESIDUAL'
		and P.HighLevelChannel = WT3.ContractHolderChannel
		and P.AgreementTypeName = WT3.AgreementType
		and P.MasterDealerCode = WT3.MasterDealerCode
		and P.Contract = WT3.ContractID
		and P.Market = 'ALL'
		and P.SubDealerEntity = WT3.SubdealerID
		and P.SalesCode = WT3.DealerCode
		and cast(WT3.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'
		
update WT3
set WT3.PayeeAssignID = P.ID
from #TXNsEligibilityWT3 WT3
	inner join cfgICSCompPayeeAssignments P on P.EventType = 'PREPAID RESIDUAL'
		and P.HighLevelChannel = WT3.ContractHolderChannel
		and P.AgreementTypeName = WT3.AgreementType
		and P.MasterDealerCode = WT3.MasterDealerCode
		and P.Contract = WT3.ContractID
		and P.Market = WT3.MARKETCODE
		and P.SubDealerEntity = WT3.SubdealerID
		and P.SalesCode = WT3.DealerCode
		and cast(WT3.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.IsActive = 'Y'

------ Transactions without residual assigned, PayeeAssignID will be updated as 'N/A'		
update #TXNsEligibilityWT3 
set PayeeAssignID = 'N/A'
where PayeeAssignID is null
		
--select * from #TXNsEligibilityWT3 where TransactionID = 'E302514083596'

------- Process to match ResidualCompGroup Record ------- 

IF OBJECT_ID('tempdb..#TXNsEligibilityWT4') is not Null
drop table #TXNsEligibilityWT4

select *
	, DATEDIFF(mm, X.ActivationDate, X.RefillDate) as Tenure
	, ROW_NUMBER() over (partition by TransactionID order by case when ProductIDCode <> 'ALL' then 1 else 2 end) as ResidualCGSeq
into #TXNsEligibilityWT4
from (
	select T.*, G.ID as ResidualCGID, G.ProductIDCode ,G.ResidualCompTableCode
	from #TXNsEligibilityWT3 T
		inner join cfgICSCompPayeeAssignments P on T.PayeeAssignID = P.ID
		inner join cfgICSResidualCompGroup G on P.ICSCompGroup = G.ResidualCompGroup
			and G.ProductIDCode = 'ALL'
			and cast(T.MonthEndDate as date) between cast(G.StartDate as date) and cast(G.EndDate as date)
			and G.IsActive = 'Y'
		inner join cfgICSProductCategory PC on G.Level = PC.Level
			and T.RatePlanCode = PC.ProductIDCode
			and cast(T.MonthEndDate as date) between CAST(PC.StartDate as date) and CAST(PC.EndDate as date)
	where T.PayeeAssignID <> 'N/A'
		--and ServiceNumber = '5415151171'
	union all
	select T.*, G.ID as ResidualCGID, G.ProductIDCode ,G.ResidualCompTableCode
	from #TXNsEligibilityWT3 T
		inner join cfgICSCompPayeeAssignments P on T.PayeeAssignID = P.ID
		inner join cfgICSResidualCompGroup G on P.ICSCompGroup = G.ResidualCompGroup
			and G.ProductIDCode = T.RatePlanCode
			and cast(T.MonthEndDate as date) between cast(G.StartDate as date) and cast(G.EndDate as date)
			and G.IsActive = 'Y'
			and exists (
				select * from cfgICSProductCategory PC where PC.ProductIDCode = G.ProductIDCode 
					and cast(T.MonthEndDate as date) between CAST(PC.StartDate as date) and CAST(PC.EndDate as date)
					)
	where T.PayeeAssignID <> 'N/A'
	) X

--select * from #TXNsEligibilityWT4

------- Process to Validate Tenure ------- 

IF OBJECT_ID('tempdb..#PrepaidResidualTXNsEligibility') is not Null
drop table #PrepaidResidualTXNsEligibility

select T.*
into #PrepaidResidualTXNsEligibility
from #TXNsEligibilityWT4 T
where ResidualCGSeq = 1
	and exists(		----- Tenure Check
		select * 
		from cfgICSResidualCompDefinition D
		where D.ResidualCompTable = T.ResidualCompTableCode
			and cast(T.MonthEndDate as date) between cast(D.StartDate as date) and cast(D.EndDate as date)
			and cast(T.Tenure as float) between cast(D.MinTenure as float) and cast(D.MaxTenure as float)
			and cast(T.ActivationDate as date) between cast(D.OrigActStartDate as date) and cast(D.OrigActEndDate as date)
			and D.IsActive = 'Y'
		)
		
--select * from #PrepaidResidualTXNsEligibility

/******************************************************************************
*                                                                             *
*                  Positive Scenarios Test Result                             *
*                                                                             *
******************************************************************************/

--DEL0200	Residual Prepaid  - Comp Sellingpoint, Market & Contract Setup - Differentes Product Levels 		
--		Preconditions	
--			Record in tsdRefill table for a dealer in the hierarchy inbound 
--			Tenure based on contract setup for “Prepaid Residual” in ResidualCompTable table. The tenure calculated (RefillDate.MonthNum - ActivationDate.MonthNum) is less than tenure setup in ResidualCompTable table
--			Productcode is commissionable
--			Activationdate is between the “OrigActStartDate” and “OrigActEndDate” from the “cfgICSResidualCompDefinition” table. Tenure of the subscriber is between the minTenure and maxTenure configured in “cfgICSResidualCompDefinition” table.
--			Compensation levelGroup based on sellingpoint, market & contract setup for prepaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Prepaid residual comp was setup at differentes product levels 
			
--		Expected	Transaction is Eligible
--			Transaction available in the list of eligible for prepaid residual calculation

select * 
from #PrepaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
where T.ProductIDCode = 'ALL'						------Prepaid residual comp was setup at differentes product levels
	and C.SalesCode <> 'ALL'						------Compensation levelGroup based on sellingpoint, market & contract setup for prepaid residual
		and C.SubDealerEntity <> 'ALL'
		and C.Market <> 'ALL'		
		and C.Contract <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.AgreementTypeName <> 'ALL'
		and C.HighLevelChannel <> 'ALL'


--DEL0201	Residual Prepaid  - Comp Sellingpoint & Contract Setup - Differentes Product Levels 		
--		Preconditions	
--			Record in tsdRefill table for a dealer in the hierarchy inbound 
--			Tenure based on contract setup for “Prepaid Residual” in ResidualCompTable table. The tenure calculated (RefillDate.MonthNum - ActivationDate.MonthNum) is less than tenure setup in ResidualCompTable table
--			Productcode is commissionable
--			Activationdate is between the “OrigActStartDate” and “OrigActEndDate” from the “cfgICSResidualCompDefinition” table. Tenure of the subscriber is between the minTenure and maxTenure configured in “cfgICSResidualCompDefinition” table.
--			Compensation levelGroup based on sellingpoint & contract setup for prepaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Prepaid residual comp was setup at differentes product levels 
			
--		Expected	Transaction is Eligible
--			Transaction available in the list of eligible for prepaid residual calculation

select * 
from #PrepaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
where T.ProductIDCode = 'ALL'						------Prepaid residual comp was setup at differentes product levels
	and C.SalesCode <> 'ALL'						------Compensation levelGroup based on sellingpoint & contract setup for prepaid residual
		and C.SubDealerEntity <> 'ALL'
		and C.Market = 'ALL'		
		and C.Contract <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.AgreementTypeName <> 'ALL'
		and C.HighLevelChannel <> 'ALL'
		

--DEL0202	Residual Prepaid  - Comp SDE, Market & Contract Setup - Differentes Product Levels 		
--		Preconditions	
--			Record in tsdRefill table for a dealer in the hierarchy inbound 
--			Tenure based on contract setup for “Prepaid Residual” in ResidualCompTable table. The tenure calculated (RefillDate.MonthNum - ActivationDate.MonthNum) is less than tenure setup in ResidualCompTable table
--			Productcode is commissionable
--			Activationdate is between the “OrigActStartDate” and “OrigActEndDate” from the “cfgICSResidualCompDefinition” table. Tenure of the subscriber is between the minTenure and maxTenure configured in “cfgICSResidualCompDefinition” table.
--			Compensation levelGroup based on SDE, market & Contract setup for prepaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Prepaid residual comp was setup at differentes product levels 
			
--		Expected	Transaction is Eligible
--			Transaction available in the list of eligible for prepaid residual calculation

select * 
from #PrepaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
where T.ProductIDCode = 'ALL'						------Prepaid residual comp was setup at differentes product levels
	and C.SalesCode = 'ALL'							------Compensation levelGroup based on SDE, market & Contract setup for prepaid residual
		and C.SubDealerEntity <> 'ALL'
		and C.Market <> 'ALL'		
		and C.Contract <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.AgreementTypeName <> 'ALL'
		and C.HighLevelChannel <> 'ALL'
		
		
--DEL0203	Residual Prepaid  - Comp SDE - Differentes Product Levels 		
--		Preconditions	
--			Record in tsdRefill table for a dealer in the hierarchy inbound 
--			Tenure based on contract setup for “Prepaid Residual” in ResidualCompTable table. The tenure calculated (RefillDate.MonthNum - ActivationDate.MonthNum) is less than tenure setup in ResidualCompTable table
--			Productcode is commissionable
--			Activationdate is between the “OrigActStartDate” and “OrigActEndDate” from the “cfgICSResidualCompDefinition” table. Tenure of the subscriber is between the minTenure and maxTenure configured in “cfgICSResidualCompDefinition” table.
--			Compensation levelGroup based on SDE setup for prepaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Prepaid residual comp was setup at differentes product levels 
			
--		Expected	Transaction is Eligible
--			Transaction available in the list of eligible for prepaid residual calculation

select * 
from #PrepaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
where T.ProductIDCode = 'ALL'						------Prepaid residual comp was setup at differentes product levels
	and C.SalesCode = 'ALL'							------Compensation levelGroup based on SDE setup for prepaid residual
		and C.SubDealerEntity <> 'ALL'
		and C.Market = 'ALL'		
		and C.Contract <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.AgreementTypeName <> 'ALL'
		and C.HighLevelChannel <> 'ALL'
		

--DEL0204	Residual Prepaid  - Comp Market & Contract Setup - Differentes Product Levels 		
--		Preconditions	
--			Record in tsdRefill table for a dealer in the hierarchy inbound 
--			Tenure based on contract setup for “Prepaid Residual” in ResidualCompTable table. The tenure calculated (RefillDate.MonthNum - ActivationDate.MonthNum) is less than tenure setup in ResidualCompTable table
--			Productcode is commissionable
--			Activationdate is between the “OrigActStartDate” and “OrigActEndDate” from the “cfgICSResidualCompDefinition” table. Tenure of the subscriber is between the minTenure and maxTenure configured in “cfgICSResidualCompDefinition” table.
--			Compensation levelGroup based on market & Contract setup for prepaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Prepaid residual comp was setup at differentes product levels 
			
--		Expected	Transaction is Eligible
--			Transaction available in the list of eligible for prepaid residual calculation

select * 
from #PrepaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
where T.ProductIDCode = 'ALL'						------Prepaid residual comp was setup at differentes product levels
	and C.SalesCode = 'ALL'							------Compensation levelGroup based on market & Contract setup for prepaid residual
		and C.SubDealerEntity = 'ALL'
		and C.Market <> 'ALL'		
		and C.Contract <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.AgreementTypeName <> 'ALL'
		and C.HighLevelChannel <> 'ALL'
		
--DEL0205	Residual Prepaid  - Comp Contract Setup - Differentes Product Levels 		
--		Preconditions	
--			Record in tsdRefill table for a dealer in the hierarchy inbound 
--			Tenure based on contract setup for “Prepaid Residual” in ResidualCompTable table. The tenure calculated (RefillDate.MonthNum - ActivationDate.MonthNum) is less than tenure setup in ResidualCompTable table
--			Productcode is commissionable
--			Activationdate is between the “OrigActStartDate” and “OrigActEndDate” from the “cfgICSResidualCompDefinition” table. Tenure of the subscriber is between the minTenure and maxTenure configured in “cfgICSResidualCompDefinition” table.
--			Compensation levelGroup based on Contract setup for prepaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Prepaid residual comp was setup at differentes product levels 
			
--		Expected	Transaction is Eligible
--			Transaction available in the list of eligible for prepaid residual calculation

select * 
from #PrepaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
where T.ProductIDCode = 'ALL'						------Prepaid residual comp was setup at differentes product levels
	and C.SalesCode = 'ALL'							------Compensation levelGroup based on Contract setup for prepaid residual
		and C.SubDealerEntity = 'ALL'
		and C.Market = 'ALL'		
		and C.Contract <> 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.AgreementTypeName <> 'ALL'
		and C.HighLevelChannel <> 'ALL'
		
--DEL0206	Residual Prepaid  - Comp MasterDealer Setup - Differentes Product Levels 		
--		Preconditions	
--			Record in tsdRefill table for a dealer in the hierarchy inbound 
--			Tenure based on contract setup for “Prepaid Residual” in ResidualCompTable table. The tenure calculated (RefillDate.MonthNum - ActivationDate.MonthNum) is less than tenure setup in ResidualCompTable table
--			Productcode is commissionable
--			Activationdate is between the “OrigActStartDate” and “OrigActEndDate” from the “cfgICSResidualCompDefinition” table. Tenure of the subscriber is between the minTenure and maxTenure configured in “cfgICSResidualCompDefinition” table.
--			Compensation levelGroup based on MasterDealer setup for prepaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Prepaid residual comp was setup at differentes product levels 
			
--		Expected	Transaction is Eligible
--			Transaction available in the list of eligible for prepaid residual calculation

select * 
from #PrepaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
where T.ProductIDCode = 'ALL'						------Prepaid residual comp was setup at differentes product levels
	and C.SalesCode = 'ALL'							------Compensation levelGroup based on MasterDealer setup for prepaid residual
		and C.SubDealerEntity = 'ALL'
		and C.Market = 'ALL'		
		and C.Contract = 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.AgreementTypeName <> 'ALL'
		and C.HighLevelChannel <> 'ALL'
		
--DEL0207	Residual Prepaid  - Comp AgreementType Setup - Differentes Product Levels 		
--		Preconditions	
--			Record in tsdRefill table for a dealer in the hierarchy inbound 
--			Tenure based on contract setup for “Prepaid Residual” in ResidualCompTable table. The tenure calculated (RefillDate.MonthNum - ActivationDate.MonthNum) is less than tenure setup in ResidualCompTable table
--			Productcode is commissionable
--			Activationdate is between the “OrigActStartDate” and “OrigActEndDate” from the “cfgICSResidualCompDefinition” table. Tenure of the subscriber is between the minTenure and maxTenure configured in “cfgICSResidualCompDefinition” table.
--			Compensation levelGroup based on AgreementType setup for prepaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Prepaid residual comp was setup at differentes product levels 
			
--		Expected	Transaction is Eligible
--			Transaction available in the list of eligible for prepaid residual calculation

select * 
from #PrepaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
where T.ProductIDCode = 'ALL'						------Prepaid residual comp was setup at differentes product levels
	and C.SalesCode = 'ALL'							------Compensation levelGroup based on AgreementType setup for prepaid residual
		and C.SubDealerEntity = 'ALL'
		and C.Market = 'ALL'		
		and C.Contract = 'ALL'
		and C.MasterDealerCode = 'ALL'
		and C.AgreementTypeName <> 'ALL'
		and C.HighLevelChannel <> 'ALL'
		
		
--DEL0208	Residual Prepaid  - Comp HighLevelChannel Setup - Differentes Product Levels 		
--		Preconditions	
--			Record in tsdRefill table for a dealer in the hierarchy inbound 
--			Tenure based on contract setup for “Prepaid Residual” in ResidualCompTable table. The tenure calculated (RefillDate.MonthNum - ActivationDate.MonthNum) is less than tenure setup in ResidualCompTable table
--			Productcode is commissionable
--			Activationdate is between the “OrigActStartDate” and “OrigActEndDate” from the “cfgICSResidualCompDefinition” table. Tenure of the subscriber is between the minTenure and maxTenure configured in “cfgICSResidualCompDefinition” table.
--			Compensation levelGroup based on HighLevelChannel setup for prepaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Prepaid residual comp was setup at differentes product levels 
			
--		Expected	Transaction is Eligible
--			Transaction available in the list of eligible for prepaid residual calculation

select * 
from #PrepaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
where T.ProductIDCode = 'ALL'						------Prepaid residual comp was setup at differentes product levels
	and C.SalesCode = 'ALL'							------Compensation levelGroup based on HighLevelChannel setup for prepaid residual
		and C.SubDealerEntity = 'ALL'
		and C.Market = 'ALL'		
		and C.Contract = 'ALL'
		and C.MasterDealerCode = 'ALL'
		and C.AgreementTypeName = 'ALL'
		and C.HighLevelChannel <> 'ALL'
		
--DEL0209	Residual Prepaid  - Comp Contract Setup - Soc Code Product Level  		
--		Preconditions	
--			Record in tsdRefill table for a dealer in the hierarchy inbound 
--			Tenure based on contract setup for “Prepaid Residual” in ResidualCompTable table. The tenure calculated (RefillDate.MonthNum - ActivationDate.MonthNum) is less than tenure setup in ResidualCompTable table
--			Productcode is commissionable
--			Activationdate is between the “OrigActStartDate” and “OrigActEndDate” from the “cfgICSResidualCompDefinition” table. Tenure of the subscriber is between the minTenure and maxTenure configured in “cfgICSResidualCompDefinition” table.
--			Compensation levelGroup based on Contract setup for prepaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Prepaid residual comp has been setup at soc code level
			
--		Expected	Transaction is Eligible
--			Transaction available in the list of eligible for prepaid residual calculation

select * 
from #PrepaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
where T.ProductIDCode <> 'ALL'						------Prepaid residual comp has been setup at soc code level
	and C.SalesCode = 'ALL'							------Compensation levelGroup based on Contract setup for prepaid residual
		and C.SubDealerEntity = 'ALL'
		and C.Market = 'ALL'		
		and C.Contract = 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.AgreementTypeName <> 'ALL'
		and C.HighLevelChannel <> 'ALL'
		
--DEL0210	Residual Prepaid  - Comp Contract Setup - Only One Product Level  		
--		Preconditions	
--			Record in tsdRefill table for a dealer in the hierarchy inbound 
--			Tenure based on contract setup for “Prepaid Residual” in ResidualCompTable table. The tenure calculated (RefillDate.MonthNum - ActivationDate.MonthNum) is less than tenure setup in ResidualCompTable table
--			Productcode is commissionable
--			Activationdate is between the “OrigActStartDate” and “OrigActEndDate” from the “cfgICSResidualCompDefinition” table. Tenure of the subscriber is between the minTenure and maxTenure configured in “cfgICSResidualCompDefinition” table.
--			Compensation levelGroup based on Contract setup for prepaid residual  from the “cfgICSCompPayeeAssignments” table 
--			Prepaid residual comp was setup for only one product level
			
--		Expected	Transaction is Eligible
--			Transaction available in the list of eligible for prepaid residual calculation

select * 
from #PrepaidResidualTXNsEligibility T
	inner join cfgICSCompPayeeAssignments C on T.PayeeAssignID = C.ID
where T.ProductIDCode <> 'ALL'						------Prepaid residual comp has been setup at soc code level
	and C.SalesCode = 'ALL'							------Compensation levelGroup based on Contract setup for prepaid residual
		and C.SubDealerEntity = 'ALL'
		and C.Market = 'ALL'		
		and C.Contract = 'ALL'
		and C.MasterDealerCode <> 'ALL'
		and C.AgreementTypeName <> 'ALL'
		and C.HighLevelChannel <> 'ALL'
		

/******************************************************************************
*                                                                             *
*                  Negative Scenarios Test Result                             *
*                                                                             *
******************************************************************************/

--DEL0250N	Residual Prepaid Record in tsdRefill table for a dealer NOT in the hierarchy inbound 

select * from #TXNsEligibilityWT1 where DealerFlag = '0'

--DEL0251N	Residual Prepaid Tenure based on contract setup for “Prepaid Residual” in ResidualCompTable table. The tenure calculated (RefillDate.MonthNum - ActivationDate.MonthNum) is iqual or greater than tenure setup in ResidualCompTable table		
		
/*  	No need for this	*/

--DEL0252N	Residual Prepaid Productcode is NO-commissionable		

select X.*, P.BillingSubsystemID 
from (
	select TransactionID, EventID, SubscriberID, ServiceNo,	ActivationDate,	RefillDate,	NPANXX,	IMEI
		, IMEI14, TACCode, BAN, SubscriberStatus, MarketCode, SIM, FirstName, LastName,	DealerCode,	RefillType,	RefillChannel
		, RatePlanCode,	AcctSubType,RefillAmt, BrandCode, PaymentVendorID, PaymentVendorTrxID, TransactionDate,	JobLogID, RefillReceivedDate
		, DealerName, SubDealerID,M.ContractHolderID, M.ContractID, M.MasterDealerCode, ContractChannel,M.Channel as ContractHolderChannel, M.ChannelType, AgreementType
		, M.CurrentMonth, M.MonthStartDate,M.MonthEndDate, DealerFlag 
	from #TXNsEligibilityWT1 T
		inner join #MasterDealerNoContract M on T.DealerCode = M.SalesCode
			and cast(T.RefillDate as date) between M.MonthStartDate and M.MonthEndDate
	where DealerFlag = '0'
	Union All
	select TransactionID, EventID, SubscriberID, ServiceNo,	ActivationDate,	RefillDate,	NPANXX,	IMEI
		, IMEI14, TACCode, BAN, SubscriberStatus, MarketCode, SIM, FirstName, LastName,	DealerCode,	RefillType,	RefillChannel
		, RatePlanCode,	AcctSubType,RefillAmt, BrandCode, PaymentVendorID, PaymentVendorTrxID, TransactionDate,	JobLogID, RefillReceivedDate
		, DealerName, SubDealerID, ContractHolderID, ContractID, MasterDealerCode, ContractChannel, ContractHolderChannel, ChannelType, AgreementType
		, CurrentMonth,	MonthStartDate,	MonthEndDate, DealerFlag
	from #TXNsEligibilityWT1 T
	where T.DealerFlag = '1'
	) X
	left join #ProductEligibility P on X.RatePlanCode = P.ProductIDCode
		and X.CurrentMonth = P.CurrentMonth
		and P.BillingSubsystemID in ('2','5')	--- Only for PostPaid
where P.ProductIDCode is null


--DEL0253N	Residual Prepaid comp has NOT been setup		

select * from #TXNsEligibilityWT3 where PayeeAssignID = 'N/A'

--DEL0254N	Residual Prepaid Activationdate is between the “OrigActStartDate” and “OrigActEndDate” from the “cfgICSResidualCompDefinition” table. Tenure of the subscriber is NOT between the minTenure and maxTenure configured in “cfgICSResidualCompDefinition” table.		

select T.*
from #TXNsEligibilityWT4 T
where ResidualCGSeq = 1
	and exists(		----- Tenure Check
		select * 
		from cfgICSResidualCompDefinition D
		where D.ResidualCompTable = T.ResidualCompTableCode
			and cast(T.MonthEndDate as date) between cast(D.StartDate as date) and cast(D.EndDate as date)
			and NOT cast(T.Tenure as float) between cast(D.MinTenure as float) and cast(D.MaxTenure as float)
			and cast(T.ActivationDate as date) between cast(D.OrigActStartDate as date) and cast(D.OrigActEndDate as date)
			and D.IsActive = 'Y'
		)

--DEL0255N	Residual Prepaid Activationdate is NOT between the “OrigActStartDate” and “OrigActEndDate” from the “cfgICSResidualCompDefinition” table. Tenure of the subscriber is between the minTenure and maxTenure configured in “cfgICSResidualCompDefinition” table.		

select T.*
from #TXNsEligibilityWT4 T
where ResidualCGSeq = 1
	and exists(		----- Tenure Check
		select * 
		from cfgICSResidualCompDefinition D
		where D.ResidualCompTable = T.ResidualCompTableCode
			and cast(T.MonthEndDate as date) between cast(D.StartDate as date) and cast(D.EndDate as date)
			and cast(T.Tenure as float) between cast(D.MinTenure as float) and cast(D.MaxTenure as float)
			and NOT cast(T.ActivationDate as date) between cast(D.OrigActStartDate as date) and cast(D.OrigActEndDate as date)
			and D.IsActive = 'Y'
		)