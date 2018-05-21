--DEH0000	Hierarchy Market Contract Level		
--		Preconditions	
--			Market present in refICSNpanxx
--			Market NOT present in cfgICSNpanxxUDF
--			Market present in cfgICSContractMarket
			
--		Expected	Market Code from cfgICSContractMarket present in List of Valid Market Codes for Contracts 
--		Calc: ICS Hierarchy MKT2000 Valid MarketCodes for Contracts

select distinct CM.SamsonMktName
from cfgICSContractMarket CM
	inner join (
		select * from refICSNpanxx RN
		where NOT exists (
			select * 
			from cfgICSNpanxxUDF CN
			where CN.NPANXX = RN.NPANXX	
				and cast(CN.STARTDATE as date) <= cast(RN.ENDDATE as date) and cast(CN.ENDDATE as date) >= cast(RN.STARTDATE as date)
				) 
			) X on CM.SamsonMktName = X.MARKET 
			and cast(CM.StartDate as date) <= cast(X.ENDDATE as date) and cast(CM.EndDate as date) >= cast(X.STARTDATE as date)
where ContractID = '1-18P83B'	----- Input the Contract that you want to test

--except
--select distinct SamsonMktName
--from ICSHierarchyMKT2000ValidMarketCodes
--where ContractID = '1-18P83B'


--DEH0001	Hierarchy Market NO Npanxx and UDF		
--		Preconditions	
--			Market NOT present in refICSNpanxx
--			Market NOT present in cfgICSNpanxxUDF
--			Market present in cfgICSContractMarket
			
--		Expected	Market Code from refICSNpanxx NOT present in List of Valid Market Codes for Contracts 
--		Calc: ICS Hierarchy MKT2000 Valid MarketCodes for Contracts

select distinct CM.SamsonMktName
from cfgICSContractMarket CM
	left join (
		select MARKET,MARKETCODE,CN.STARTDATE,CN.ENDDATE
		from refICSNpanxx RN
			inner join cfgICSNpanxxUDF CN on RN.NPANXX = CN.NPANXX
				and cast(CN.STARTDATE as date) <= cast(RN.ENDDATE as date) and cast(CN.ENDDATE as date) >= cast(RN.STARTDATE as date)
		) X on CM.SamsonMktName = X.MARKET 
			and cast(CM.StartDate as date) <= cast(X.ENDDATE as date) and cast(CM.EndDate as date) >= cast(X.STARTDATE as date)
where X.MARKET is null

--except
--select distinct SamsonMktName
--from ICSHierarchyMKT2000ValidMarketCodes
--where ContractID = '1-18P83B'


--DEH0007	Hierarchy Market ALL		
--		Preconditions	
--			Market present in refICSNpanxx
--			Market present in cfgICSNpanxxUDF
--			Market present in cfgICSContractMarket
			
--		Expected	Contract UDF Market Code from cfgICSNpanxx present in List of Valid Market Codes for Contracts 
--		Calc: ICS Hierarchy MKT2000 Valid MarketCodes for Contracts


select ContractHolderID,ContractID,SamsonMktName,MARKETCODE
from cfgICSContractMarket CM
	inner join (
		select MARKET,MARKETCODE,CN.STARTDATE,CN.ENDDATE
		from refICSNpanxx RN
			inner join cfgICSNpanxxUDF CN on RN.NPANXX = CN.NPANXX
				and cast(CN.STARTDATE as date) <= cast(RN.ENDDATE as date) and cast(CN.ENDDATE as date) >= cast(RN.STARTDATE as date)
		) X on CM.SamsonMktName = X.MARKET 
			and cast(CM.StartDate as date) <= cast(X.ENDDATE as date) and cast(CM.EndDate as date) >= cast(X.STARTDATE as date)


--except
--select ContractHolderID,ContractID,SamsonMktName,MARKETCODE
--from ICSHierarchyMKT2000ValidMarketCodes
--where MARKETCODE like '%[0-9]'


--DEH0002	Hierarchy MasterDealer without Contracts cfgICSContractHolder Inactive		
--		Preconditions	
--			MasterDealer in cfgICSContractHolder.status  =  0 (InActive)
			
--		Expected	MasterDealer is present in List of MasterDealer without Contracts

IF OBJECT_ID('tempdb..#Month') is not Null
drop table #Month

select CurrentMonth,MIN(CAST(Date as date)) as StartDate, MAX(CAST(Date as date)) as EndDate
into #Month  
from cfgDateString
group by CurrentMonth

select H.ContractHolderID,H.Channel,H.MasterDealerCode,M.CurrentMonth,H.* 
from cfgICSContractHolder H
	inner join #Month M on CAST(H.CompEffStartDate as date) <= CAST(M.EndDate as date)
		and CAST(H.CompEffEndDate as date) >= CAST(M.EndDate as date)
where 1=1
	and cast(M.StartDate as date) >= '2013-01-01' and CAST(M.EndDate as date) <= '2014-03-31'
	and H.StatusCode not in ('A','P','TC')		-----From cfgICSTCMStatus table
	
--select * from cfgICSTCMStatus
--select * from cfgDateString


--DEH0003	Hierarchy MasterDealer without Contracts cfgICSContract.status Inactive		
--		Preconditions	
--			MasterDealer in cfgICSContractHolder.status   =  1 (Active)
--			MasterDealer in cfgICSContract.status  =  0 (InActive)
			
--		Expected	MasterDealer is present in List of MasterDealer without Contracts
	
IF OBJECT_ID('tempdb..#Month') is not Null
drop table #Month
IF OBJECT_ID('tempdb..#ContractEligibility') is not Null
drop table #ContractEligibility
IF OBJECT_ID('tempdb..#ContractHolderEligibility') is not Null
drop table #ContractHolderEligibility

select CurrentMonth,MIN(CAST(Date as date)) as StartDate, MAX(CAST(Date as date)) as EndDate
into #Month  
from cfgDateString
group by CurrentMonth

select  M.CurrentMonth,M.StartDate as MonthStartDate,M.EndDate as MonthEndDate,H.*  
into #ContractHolderEligibility
from cfgICSContractHolder H
	inner join #Month M on CAST(H.CompEffStartDate as date) <= CAST(M.EndDate as date)
		and CAST(H.CompEffEndDate as date) >= CAST(M.EndDate as date)
where 1=1
	and cast(M.StartDate as date) >= '2013-01-01' and CAST(M.EndDate as date) <= '2014-03-31'
	--and H.Status not in ('Active','Pending','Terminated with ChargeBack')
	
select M.CurrentMonth,M.StartDate as MonthStartDate,M.EndDate as MonthEndDate,C.* 
into #ContractEligibility
from cfgICSContract C
	inner join #Month M on CAST(C.CompEffStartDate as date) <= CAST(M.EndDate as date)
		and CAST(C.CompEffEndDate as date) >= CAST(M.EndDate as date)
where 1=1
	and cast(M.StartDate as date) >= '2013-01-01' and CAST(M.EndDate as date) <= '2014-03-31'
	
select C.CurrentMonth, H.ContractHolderID, C.ContractID, H.Status as ContractHoldStatus, C.Status as ContractStatus 
from #ContractEligibility C
	inner join #ContractHolderEligibility H on H.ContractHolderID = C.ContractHolderID
		and H.CurrentMonth = C.CurrentMonth
where H.StatusCode in ('A','P','TC')
	and IsNull(C.StatusCode,'N/A') not in ('A','P','TC')
	
	
--DEH0004	Hierarchy MasterDealer without Contracts cfgICSSalescode.status Inactive		
--		Preconditions	
--			MasterDealer in cfgICSContractHolder.status   =  1 (Active)
--			MasterDealer in cfgICSContract.status  =  1 (Active)
--			MasterDealer in cfgICSSalescode.status  =  0 (InActive)
			
--		Expected	MasterDealer is present in List of MasterDealer without Contracts

IF OBJECT_ID('tempdb..#Month') is not Null
drop table #Month
IF OBJECT_ID('tempdb..#ContractEligibility') is not Null
drop table #ContractEligibility
IF OBJECT_ID('tempdb..#ContractHolderEligibility') is not Null
drop table #ContractHolderEligibility
IF OBJECT_ID('tempdb..#SalesCodesEligibility') is not Null
drop table #SalesCodesEligibility


select CurrentMonth,MIN(CAST(Date as date)) as StartDate, MAX(CAST(Date as date)) as EndDate
into #Month  
from cfgDateString
group by CurrentMonth

select  M.CurrentMonth,M.StartDate as MonthStartDate,M.EndDate as MonthEndDate,H.*  
into #ContractHolderEligibility
from cfgICSContractHolder H
	inner join #Month M on CAST(H.CompEffStartDate as date) <= CAST(M.EndDate as date)
		and CAST(H.CompEffEndDate as date) >= CAST(M.EndDate as date)
where 1=1
	and cast(M.StartDate as date) >= '2013-01-01' and CAST(M.EndDate as date) <= '2014-03-31'
	--and H.Status not in ('Active','Pending','Terminated with ChargeBack')
	
select M.CurrentMonth,M.StartDate as MonthStartDate,M.EndDate as MonthEndDate,C.* 
into #ContractEligibility
from cfgICSContract C
	inner join #Month M on CAST(C.CompEffStartDate as date) <= CAST(M.EndDate as date)
		and CAST(C.CompEffEndDate as date) >= CAST(M.EndDate as date)
where 1=1
	and cast(M.StartDate as date) >= '2013-01-01' and CAST(M.EndDate as date) <= '2014-03-31'
	
select M.CurrentMonth,M.StartDate as MonthStartDate,M.EndDate as MonthEndDate,SC.* 
into #SalesCodesEligibility
from cfgICSSalesCode SC
	inner join #Month M on CAST(SC.CompEffStartDate as date) <= CAST(M.EndDate as date)
		and CAST(SC.CompEffEndDate as date) >= CAST(M.EndDate as date)
where 1=1
	and cast(M.StartDate as date) >= '2013-01-01' and CAST(M.EndDate as date) <= '2014-03-31'
	
select distinct SC.SalesCode,sc.DealerName,sc.ContractHolderID,S.ContractID,H.MasterDealerCode,S.Channel as ContractChannel,H.Channel as ContractHolderChannel,H.ChannelType,S.AgreementType
	,cast(S.MonthStartDate as date) as MonthStartDate,cast(S.MonthEndDate as date) as MonthEndDate,S.CurrentMonth
from #SalesCodesEligibility SC
	inner join #ContractHolderEligibility H on SC.ContractHolderID = H.ContractHolderID and SC.CurrentMonth = H.CurrentMonth --and SC.SalesCode = H.MasterDealerCode
	inner join #ContractEligibility S on S.ContractID = SC.ContractID and S.ContractHolderID = S.ContractHolderID and S.CurrentMonth = SC.CurrentMonth
where  H.StatusCode in ('A','P','TC')
	and S.StatusCode in ('A','P','TC')
	and IsNull(SC.StatusCode, 'N/A') not in ('A','P','TC')


------Here we need pull out the real one
--Question: If SalerCode is only valid within one month, what is the expectation? The logic current in Varicent will consider as valid for whole month

--select distinct SC.SalesCode,sc.DealerName,sc.ContractHolderID,H.MasterDealerCode,S.Channel as ContractChannel,H.Channel as ContractHolderChannel,H.ChannelType,cast(S.MonthStartDate as date) as MonthStartDate,cast(S.MonthEndDate as date) as MonthEndDate,S.CurrentMonth
select * 
from #SalesCodesEligibility SC
	inner join #ContractHolderEligibility H on SC.ContractHolderID = H.ContractHolderID and SC.CurrentMonth = H.CurrentMonth and SC.SalesCode = H.MasterDealerCode
	--inner join #ContractEligibility S on  H.ContractHolderID = S.ContractHolderID and S.CurrentMonth = SC.CurrentMonth
where IsNull(SC.ContractID,'') = ''
	and SC.CurrentMonth = '2013, Month 01'
	and SC.SalesCode = '0013329'



--DEH0005	Hierarchy SalesCode Attributes without Residual		
--		Preconditions	
--			SalesCode in cfgICSContractHolder.status   =  1 (Active)
--			SalesCode in cfgICSContract.status  =  1 (Active)
--			SalesCode in cfgICSSalescode.status  = 1 (Active)
			
--		Expected	SalesCode is present in List of SalesCode Attributes
--			SalesCode is present in List of Contract Mapping
--			SalesCode is present in List of Master Dealer Mapping
--			SalesCode is present in List of High Level Channel to Agreement type Mapping
--			SalesCode is NOT present in List of Residual Comp Table Values by Contract

--DEH0006	Hierarchy SalesCode Attributes with Residual		
--		Preconditions	
--			SalesCode in cfgICSContractHolder.status   =  1 (Active)
--			SalesCode in cfgICSContract.status  =  1 (Active)
--			SalesCode in cfgICSSalescode.status  = 1 (Active)
--			Residual tenure at Channel Level based on ICS CompGroup from the cfgICSCompPayeeAssignment table
			
--		Expected	SalesCode is present in List of SalesCode Attributes
--			SalesCode is present in List of Contract Mapping
--			SalesCode is present in List of Master Dealer Mapping
--			SalesCode is present in List of High Level Channel to Agreement type Mapping
--			SalesCode is present in List of Residual Comp Table Values by Contract with max tenure based on Residualcompgroup  from cfgICSResidualcompgroup table and sort by datestring



---------------------- Dealer Eligibility ------------------------------------

IF OBJECT_ID('tempdb..#DealerMonthlyEligibility') is not Null
drop table #DealerMonthlyEligibility

select * 
into #DealerMonthlyEligibility
from dbo.ufn_DealerMonthlyEligibility('2012-11-01', '2013-12-31')

--select * from #DealerMonthlyEligibility

IF OBJECT_ID('tempdb..#ResidualAssigneWT1') is not Null
drop table #ResidualAssigneWT1

select D.*,R.refEventType, P.ID, P.ICSCompGroup ,P.EventType, P.HighLevelChannel as AssignHighLevelChannel, P.AgreementTypeName as AssignAgreementTypeName
		,P.MasterDealerCode as AssignMasterDealerCode, P.Contract as AssignContract, P.SalesCode as AssignSalesCode
into #ResidualAssigneWT1
from #DealerMonthlyEligibility D
	inner join (
		select 'RESIDUAL' as refEventType
		union 
		select 'PREPAID RESIDUAL' as refEventType
		) R	on 1=1	
	left join cfgICSCompPayeeAssignments P on P.EventType = R.refEventType
		and P.IsActive = 'Y'
		and cast(D.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.HighLevelChannel = 'ALL'
		and P.AgreementTypeName = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.Contract = 'ALL'
		and P.SalesCode = 'ALL'

--select * from #ResidualAssigneWT1 where ContractID = '0-C-1' order by CurrentMonth



update RA 
set RA.ID = P.ID, RA.ICSCompGroup = P.ICSCompGroup, RA.EventType = P.EventType, RA.AssignHighLevelChannel = P.HighLevelChannel
from #ResidualAssigneWT1 RA
	inner join cfgICSCompPayeeAssignments P on P.EventType =refEventType
		and P.IsActive = 'Y'
		and cast(RA.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and P.HighLevelChannel = RA.ContractHolderChannel 
		and P.AgreementTypeName = 'ALL'
		and P.MasterDealerCode = 'ALL'
		and P.Contract = 'ALL'
		and P.SalesCode = 'ALL'
		
--select * from #ResidualAssigneWT1 where ContractID = '0-C-1' order by CurrentMonth

update RA 
set RA.ID = P.ID, RA.ICSCompGroup = P.ICSCompGroup, RA.EventType = P.EventType,RA.AssignHighLevelChannel = P.HighLevelChannel, RA.AssignAgreementTypeName = P.AgreementTypeName
from #ResidualAssigneWT1 RA
	inner join cfgICSCompPayeeAssignments P on P.EventType =refEventType
		and P.IsActive = 'Y'
		and cast(RA.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and (P.HighLevelChannel = RA.ContractHolderChannel or P.HighLevelChannel = 'ALL')
		and P.AgreementTypeName = RA.AgreementType
		and P.MasterDealerCode = 'ALL'
		and P.Contract = 'ALL'
		and P.SalesCode = 'ALL'
		
update RA 
set RA.ID = P.ID, RA.ICSCompGroup = P.ICSCompGroup, RA.EventType = P.EventType,RA.AssignHighLevelChannel = P.HighLevelChannel, RA.AssignAgreementTypeName = P.AgreementTypeName, RA.AssignMasterDealerCode = P.MasterDealerCode
from #ResidualAssigneWT1 RA
	inner join cfgICSCompPayeeAssignments P on P.EventType =refEventType
		and P.IsActive = 'Y'
		and cast(RA.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and (P.HighLevelChannel = RA.ContractHolderChannel or P.HighLevelChannel = 'ALL')
		and (P.AgreementTypeName = RA.AgreementType or P.AgreementTypeName = 'ALL')
		and P.MasterDealerCode = RA.MasterDealerCode
		and P.Contract = 'ALL'
		and P.SalesCode = 'ALL'
		
update RA 
set RA.ID = P.ID, RA.ICSCompGroup = P.ICSCompGroup, RA.EventType = P.EventType,RA.AssignHighLevelChannel = P.HighLevelChannel, RA.AssignAgreementTypeName = P.AgreementTypeName, RA.AssignMasterDealerCode = P.MasterDealerCode
	, RA.AssignContract = P.Contract
from #ResidualAssigneWT1 RA
	inner join cfgICSCompPayeeAssignments P on P.EventType =refEventType
		and P.IsActive = 'Y'
		and cast(RA.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and (P.HighLevelChannel = RA.ContractHolderChannel or P.HighLevelChannel = 'ALL')
		and (P.AgreementTypeName = RA.AgreementType or P.AgreementTypeName = 'ALL')
		and (P.MasterDealerCode = RA.MasterDealerCode or P.MasterDealerCode = 'ALL')
		and P.Contract = RA.ContractID
		and P.SalesCode = 'ALL'


update RA 
set RA.ID = P.ID, RA.ICSCompGroup = P.ICSCompGroup,RA.EventType = P.EventType, RA.AssignHighLevelChannel = P.HighLevelChannel, RA.AssignAgreementTypeName = P.AgreementTypeName, RA.AssignMasterDealerCode = P.MasterDealerCode
	, RA.AssignContract = P.Contract, RA.AssignSalesCode = P.SalesCode
from #ResidualAssigneWT1 RA
	inner join cfgICSCompPayeeAssignments P on P.EventType =refEventType
		and P.IsActive = 'Y'
		and cast(RA.MonthEndDate as date) between cast(P.StartDate as date) and cast(P.EndDate as date)
		and (P.HighLevelChannel = RA.ContractHolderChannel or P.HighLevelChannel = 'ALL')
		and (P.AgreementTypeName = RA.AgreementType or P.AgreementTypeName = 'ALL')
		and (P.MasterDealerCode = RA.MasterDealerCode or P.MasterDealerCode = 'ALL')
		and (P.Contract = RA.ContractID or P.Contract = 'ALL')
		and P.SalesCode = RA.SalesCode

--select * from #ResidualAssigneWT1 where ContractID = '0-C-1'
--select Distinct * from #ResidualAssigneWT1

IF OBJECT_ID('tempdb..#ResidualAssign') is not Null
drop table #ResidualAssign

select R.*, G.ID as CompGroupID,G.ProductIDCode,G.Level as ProductLevel, G.LevelNumber,G.BillingSubSystemID, G.ResidualCompTableCode
	,G.StartDate as CompGroupStartDate,	G.EndDate as CompGroupEndDate,D.ID as CompDefinitionID,	D.ResidualCompTable, D.TierAttain
	,D.StartDate as CompDefinitionStartDate, D.EndDate as CompDefinitionEndDate, D.MinTenure,D.MaxTenure, D.Payout, D.OrigActStartDate, D.OrigActEndDate
into #ResidualAssign
from #ResidualAssigneWT1 R
	left join cfgICSResidualCompGroup G on R.ICSCompGroup = G.ResidualCompGroup
		and cast(R.MonthEndDate as date) between cast(G.StartDate as date) and cast(G.EndDate as date)
		and G.IsActive = 'Y'
	left join cfgICSResidualCompDefinition D on G.ResidualCompTableCode = D.ResidualCompTable
		and cast(R.MonthEndDate as date) between cast(D.StartDate as date) and cast(D.EndDate as date)
		and G.IsActive = 'Y'


-------------------Result ------------------------

--DEH0005	Hierarchy SalesCode Attributes without Residual	
select * from #ResidualAssign 
where ID is null or CompGroupID is null or CompDefinitionID is null
order by ContractID, EventType, CurrentMonth

--DEH0006	Hierarchy SalesCode Attributes with Residual
select * from #ResidualAssign 
where CompDefinitionID is not null
	and ContractID = '1-AP1-1214'
order by ContractID, EventType, CurrentMonth


select * from #ResidualAssign 
where 1=1
	--and CompDefinitionID is not null
	and ContractID = '0-C-1'
order by CurrentMonth,ContractID, EventType 


/************** Didn't finish yet *****************
Logic in Varicent:
1. Map to  #DealerMonthlyEligibility.ContractHolderChannel = cfgICSCompPayeeAssignments.HighLevelChannel
2. For each contract, pull out top 1 ICSCompGroup order by cfgICSCompPayeeAssignments.StartDate desc
3. Map to cfgICSResidualCompGroup.ResidualComGroup, pull out ResidualCompTable and MaxTenure
**************************************************/




--DEH0050N	Hierarchy Market NO UDF and Contract		
--		Preconditions	
--			Market present in refICSNpanxx
--			Market NOT present in cfgICSNpanxxUDF
--			Market NOT present in cfgICSContractMarket
			
--		Expected	Market Code from refICSNpanxx NOT present in List of Valid Market Codes for Contracts 

select * from refICSNpanxx R
where R.NPANXX not in (
	select NPANXX from cfgICSNpanxxUDF
	)
	and R.MARKET not in (
	select SamsonMktName from cfgICSContractMarket
	) 



--DEH0051N	Hierarchy Market UDF Market Level NO Contract		
--		Preconditions	
--			Market present in refICSNpanxx
--			Market present in cfgICSNpanxxUDF
--			Market NOT present in cfgICSContractMarket
			
--		Expected	Market Code from cfgICSNpanxxUDF NOT present in List of Valid Market Codes for Contracts 

select * from refICSNpanxx R
where R.NPANXX in (
	select NPANXX from cfgICSNpanxxUDF
	)
	and R.MARKET not in (
	select SamsonMktName from cfgICSContractMarket
	)