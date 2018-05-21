/*************************************************************
*                  Dealer Eligibility                        *
**************************************************************/

IF OBJECT_ID(N'dbo.ufn_DealerMonthlyEligibility', N'TF') is not null
drop function dbo.ufn_DealerMonthlyEligibility;
GO
Create Function dbo.ufn_DealerMonthlyEligibility(@StartDate date, @EndDate date)
Returns @DealerMonthlyEligibility table
(
	SalesCode varchar(50),
	DealerName varchar(300),
	SubDealerID varchar(300),
	ContractHolderID varchar(100),
	ContractID varchar(100),
	MasterDealerCode varchar(50),
	ContractChannel varchar(300),
	ContractHolderChannel varchar(300),
	ChannelType varchar(300),
	AgreementType varchar(300),
	MonthStartDate date,
	MonthEndDate date,
	CurrentMonth varchar(100)

)
AS
BEGIN

WITH 
[Month] (CurrentMonth, StartDate,EndDate) AS
(
select CurrentMonth,MIN(CAST(Date as date)) as StartDate, MAX(CAST(Date as date)) as EndDate
from cfgDateString
group by CurrentMonth
),

-----Contract Monthly Eligibility------
ContractEligibility  AS 
(
select *
from (
select M.CurrentMonth,M.StartDate as MonthStartDate,M.EndDate as MonthEndDate,S.Eligibility,C.* 
	,ROW_NUMBER() Over(Partition by C.ContractID,C.ContractHolderID,M.CurrentMonth 
			order by cast(C.CompEffEndDate as date)desc, cast(C.CompEffStartDate as date) desc ) as Seq
from cfgICSContract C
	inner join Month M on (
		CAST(C.CompEffStartDate as date) <= CAST(M.EndDate as date)
		and CAST(C.CompEffEndDate as date) >= CAST(M.EndDate as date)
		OR
		CAST(C.CompEffStartDate as date) >= CAST(M.StartDate as date)
		and CAST(C.CompEffEndDate as date) <= CAST(M.EndDate as date)
		)
	inner join cfgICSTCMStatus S on C.StatusCode = S.StatusCode
		and CAST(S.EndDate as date) >= CAST(M.EndDate as date)
		and CAST(M.EndDate as date) >= CAST(S.StartDate as date)
		and S.Eligibility = '1.00' 
where 1=1
	and cast(M.StartDate as date) >= @StartDate and CAST(M.EndDate as date) <= @EndDate
	) X 
where X.seq=1
),

-----Contract Holder Monthly Eligibility------
ContractHolderEligibility  AS
(
select * 
from (
select M.CurrentMonth,M.StartDate as MonthStartDate,M.EndDate as MonthEndDate,S.Eligibility,H.* 
	,ROW_NUMBER() Over(Partition by H.ContractHolderID,M.CurrentMonth 
			order by cast(H.CompEffEndDate as date)desc, cast(H.CompEffStartDate as date) desc ) as Seq
from cfgICSContractHolder H
	inner join Month M on (
		CAST(H.CompEffStartDate as date) <= CAST(M.EndDate as date)
		and CAST(H.CompEffEndDate as date) >= CAST(M.EndDate as date)
		OR
		CAST(H.CompEffStartDate as date) >= CAST(M.StartDate as date)
		and CAST(H.CompEffEndDate as date) <= CAST(M.EndDate as date)
		)
	inner join cfgICSTCMStatus S on H.StatusCode = S.StatusCode
		and CAST(S.EndDate as date) >= CAST(M.EndDate as date)
		and CAST(M.EndDate as date) >= CAST(S.StartDate as date)
		and S.Eligibility = '1.00' 
where 1=1
	and cast(M.StartDate as date) >= @StartDate and CAST(M.EndDate as date) <= @EndDate
	) X
where X.Seq = 1
),

-----Sales Codes Monthly Eligibility------
SalesCodesEligibility  AS
(
select * 
from (
	select M.CurrentMonth,M.StartDate as MonthStartDate,M.EndDate as MonthEndDate,S.Eligibility,SC.*
		, ROW_NUMBER() Over(Partition by SC.SalesCode,SC.ContractHolderID,M.CurrentMonth 
			order by cast(SC.CompEffEndDate as date)desc, cast(SC.CompEffStartDate as date) desc ) as Seq
	from cfgICSSalesCode SC
		inner join Month M on (
			CAST(SC.CompEffStartDate as date) <= CAST(M.EndDate as date)
			and CAST(SC.CompEffEndDate as date) >= CAST(M.EndDate as date)
			OR
			CAST(SC.CompEffStartDate as date) >= CAST(M.StartDate as date)
			and CAST(SC.CompEffEndDate as date) <= CAST(M.EndDate as date)
			)
		inner join cfgICSTCMStatus S on SC.StatusCode = S.StatusCode
			and CAST(S.EndDate as date) >= CAST(M.EndDate as date)
			and CAST(M.EndDate as date) >= CAST(S.StartDate as date)
			and S.Eligibility = '1.00' 
	where 1=1
		and cast(M.StartDate as date) >= @StartDate and CAST(M.EndDate as date) <= @EndDate
		--and SalesCode = '3229331'
		--and CurrentMonth = '2013, Month 06'
		) X 
where X.Seq = 1
)

-----Dealer Monthly Eligibility------

Insert into @DealerMonthlyEligibility
select distinct SC.SalesCode,sc.DealerName,sc.SubDealerID,sc.ContractHolderID,S.ContractID,H.MasterDealerCode,S.Channel as ContractChannel,H.Channel as ContractHolderChannel,H.ChannelType,S.AgreementType
	,cast(S.MonthStartDate as date) as MonthStartDate,cast(S.MonthEndDate as date) as MonthEndDate,S.CurrentMonth
from SalesCodesEligibility SC
	inner join ContractHolderEligibility H on SC.ContractHolderID = H.ContractHolderID and SC.CurrentMonth = H.CurrentMonth
	inner join ContractEligibility S on S.ContractID = SC.ContractID and S.ContractHolderID = SC.ContractHolderID and S.CurrentMonth = SC.CurrentMonth
	
RETURN
	
END;
GO
	

/***********************************************************
*                  Market Eligibility                      *
************************************************************/
IF OBJECT_ID(N'dbo.ufn_MarketEligibility') is not null
drop function dbo.ufn_MarketEligibility;
GO

Create function dbo.ufn_MarketEligibility()
returns table
AS
RETURN
(
select M.ContractHolderID,M.ContractID,M.SamsonMktName,X.NPANXX
	,case 
		when X.MARKETCODE is null then M.SamsonMktName
		when X.MARKETCODE is not null then X.MARKETCODE 
		else X.MARKET 
	end as MarketCode
	,case 
		when X.STARTDATE is null then cast(M.StartDate as date)
		when (CAST(M.StartDate as DATE)>= CAST(X.StartDate as DATE)) then cast(M.StartDate as DATE) 
		else cast(X.STARTDATE as date) 
	end as StartDate
	,case 
		when X.ENDDATE is null then CAST(M.EndDate as date)
		when (CAST(M.EndDate as DATE)>= CAST(X.ENDDATE as DATE)) then cast(X.ENDDATE as date) 
		else cast(M.EndDate as date) 
	end as EndDate
from cfgICSContractMarket M
	left join (	  
		select U.NPANXX,R.MARKET,U.MARKETCODE
			,case 
				when cast(R.StartDate as date) >= cast(U.STARTDATE as date) then R.STARTDATE
				else U.STARTDATE end as STARTDATE
			,case
				when CAST(R.EndDate as date) <= CAST(U.ENDDATE as date) then R.ENDDATE
				else U.ENDDATE end as ENDDATE 
		from refICSNpanxx R
			inner join cfgICSNpanxxUDF U on R.NPANXX = U.NPANXX
				and CAST(U.ENDDATE as date) >= CAST(R.STARTDATE as date) and CAST(U.STARTDATE as date) <= CAST(R.ENDDATE as date)
		--where U.NPANXX = '318850'
		Union all
		select Distinct U.NPANXX,R.MARKET,U.MARKETCODE,Min(cast(R.STARTDATE as date)) as STARTDATE ,Max(cast(R.ENDDATE as DATE)) as ENDDATE 
		from refICSNpanxx R
			left join cfgICSNpanxxUDF U on R.NPANXX = U.NPANXX
		where U.MARKETCODE is  null
		group by U.NPANXX,R.MARKET,U.MARKETCODE) X on M.SamsonMktName = X.MARKET
where X.STARTDATE is null
	or (X.STARTDATE is not null 
		and CAST(X.EndDate as date) >= CAST(M.StartDate as date)
		and CAST(X.STARTDATE as date) <= CAST(M.EndDate as date))
)	
GO

/***************************************************
*             Product Eligibility                  *
****************************************************/

IF OBJECT_ID(N'dbo.ufn_ProductEligibility', N'TF') is not null
drop function dbo.ufn_ProductEligibility;
GO

Create Function dbo.ufn_ProductEligibility(@StartDate date, @EndDate date)
Returns @ProductEligibility table
(
	BillingSubsystemID varchar(10),
	ProductIDCode varchar(300),
	IsCommissionable varchar(300),
	CurrentMonth varchar(50),
	StartDate date,
	EndDate date
)
AS
BEGIN

WITH 
[Month] (CurrentMonth, StartDate,EndDate) AS
(
select CurrentMonth,MIN(CAST(Date as date)) as StartDate, MAX(CAST(Date as date)) as EndDate
from cfgDateString
group by CurrentMonth
)

Insert into @ProductEligibility
select distinct P.BillingSubsystemID, P.ProductIDCode, P.IsCommissionable, M.CurrentMonth, cast(M.StartDate as date) as StartDate, cast(M.EndDate as date) as EndDate
from cfgICSProductCategory P
	inner join Month M on CAST(P.StartDate as date) <= CAST(M.EndDate as date)
		and CAST(P.EndDate as date) >= CAST(M.EndDate as date)
where 1=1
	and IsCommissionable like '%YES%'
	and cast(M.StartDate as date) >= @StartDate and CAST(M.EndDate as date) <= @EndDate

RETURN
	
END;
GO


--select * from dbo.ufn_DealerMonthlyEligibility('2012-11-01', '2013-12-31')
--select * from dbo.ufn_ProductEligibility('2012-11-01', '2013-12-31')
--select * from dbo.ufn_MarketEligibility()

