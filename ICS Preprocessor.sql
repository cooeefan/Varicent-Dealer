-----Initialize Calc month first-----
IF OBJECT_ID('tempdb..#CalcMonth') is not Null
drop table #CalcMonth

select CurrentMonth,MIN(CAST(Date as date)) as StartDate, MAX(CAST(Date as date)) as EndDate
into #CalcMonth  
from cfgDateString
where cast(EndDate as date) between '2012-01-31' and '2014-03-31'	-----Calc date period, need to change according testing time
group by CurrentMonth

--select * from #CalcMonth

--DEP0000	Preprocessor ProductCategory IsCommissionable Current Month		
--		Preconditions	
--			Product IsCommissionable = 0 in cfgICSProductCategory table
--			Product with dates between the start and end of the month
			
--		Expected	Rows tagged = 1 and IsCommissionable = Y in the list of commissionable and non-commissionable product codes
--		Calc: ICS Preprocessor PREP1030 ProductCategory Tag Dates


select Y.*  
from (	
	select *, ROW_NUMBER() over(partition by X.BillingSubsystemID,X.ProductIDCode, X.StartDate order by cast(X.EndDate as date) desc) as Seq	
	from (	
		select distinct BillingSubsystemID,ProductIDCode,IsCommissionable
			, case when cast(StartDate as date)<'2012-01-01' then '2012-01-01' 
				else Convert(varchar(7),cast(StartDate as date),121)+'-01' end as StartDate
			,Convert(varchar(11),cast(EndDate as date),121) as EndDate
		from cfgICSProductCategory
		--where ProductIDCode = '1000A12M'
		) X
	) Y
	inner join #CalcMonth M on CAST(Y.EndDate as date) > cast(M.StartDate as date) 
		and  CAST(Y.EndDate as date) < cast(M.EndDate as date)
where Y.Seq = 1
	and Y.IsCommissionable = 'NO'

--DEP0001	Preprocessor ProductCategory IsCommissionable OutSide Calendar Year		
--		Preconditions	
--			Product IsCommissionable = 0 in cfgICSProductCategory table
--			Product with dates outside the calendar years
			
--		Expected	Rows tagged = 3 and IsCommissionable = Y in the list of commissionable and non-commissionable product codes
--		Calc: ICS Preprocessor PREP1030 ProductCategory Tag Dates

select Y.*  
from (	
	select *, ROW_NUMBER() over(partition by X.BillingSubsystemID,X.ProductIDCode, X.StartDate order by cast(X.EndDate as date) desc) as Seq	
	from (	
		select distinct BillingSubsystemID,ProductIDCode,IsCommissionable
			, case when cast(StartDate as date)<='2012-01-01' then '2012-01-01' 
				else Convert(varchar(7),cast(StartDate as date),121)+'-01' end as StartDate
			,Convert(varchar(11),cast(EndDate as date),121) as EndDate
		from cfgICSProductCategory
		--where ProductIDCode = '1000A12M'
		) X
	) Y
	left join #CalcMonth M on CAST(Y.EndDate as date) >= cast(M.StartDate as date) 
		and  CAST(Y.EndDate as date) <= cast(M.EndDate as date)
where Y.Seq = 1
	and M.CurrentMonth is null
	and Y.IsCommissionable = 'NO'
	--and Y.StartDate = '2012-06-01'
	

--DEP0002	Preprocessor ProductCategory IsCommissionable end date matches the end date of a month in the calendar		
--		Preconditions	
--			Product IsCommissionable = 0 in cfgICSProductCategory table
--			Product with end date matches the end date of a month in the calendar
			
--		Expected	Rows tagged = 5 and IsCommissionable = Y in the list of commissionable and non-commissionable product codes
--		Calc: ICS Preprocessor PREP1030 ProductCategory Tag Dates

select Y.*  
from (	
	select *, ROW_NUMBER() over(partition by X.BillingSubsystemID,X.ProductIDCode, X.StartDate order by cast(X.EndDate as date) desc) as Seq	
	from (	
		select distinct BillingSubsystemID,ProductIDCode,IsCommissionable
			, case when cast(StartDate as date)<='2012-01-01' then '2012-01-01' 
				else Convert(varchar(7),cast(StartDate as date),121)+'-01' end as StartDate
			,Convert(varchar(11),cast(EndDate as date),121) as EndDate
		from cfgICSProductCategory
		--where ProductIDCode = '1000A12M'
		) X
	) Y
	inner join #CalcMonth M on CAST(Y.EndDate as date) = cast(M.EndDate as date)
where Y.Seq = 1
	and Y.IsCommissionable = 'NO'
	--and Y.StartDate = '2012-06-01'
	

--DEP0003	Preprocessor ProductCategory NonCommissionable Current Month		
--		Preconditions	
--			Product IsCommissionable = 1 in cfgICSProductCategory table
--			Product with dates between the start and end of the month
			
--		Expected	Rows tagged = 1 and IsCommissionable = N in the list of commissionable and non-commissionable product codes
--		Calc: ICS Preprocessor PREP1030 ProductCategory Tag Dates

select *  
from (	
	select *, ROW_NUMBER() over(partition by X.BillingSubsystemID,X.ProductIDCode, X.StartDate order by cast(X.EndDate as date) desc) as Seq	
	from (	
		select distinct BillingSubsystemID,ProductIDCode,IsCommissionable
			, case when cast(StartDate as date)<'2012-01-01' then '2012-01-01' 
				else Convert(varchar(7),cast(StartDate as date),121)+'-01' end as StartDate
			,Convert(varchar(11),cast(EndDate as date),121) as EndDate
		from cfgICSProductCategory
		--where ProductIDCode = '1000A12M'
		) X
	) Y
	inner join #CalcMonth M on CAST(Y.EndDate as date) > cast(M.StartDate as date) 
		and  CAST(Y.EndDate as date) < cast(M.EndDate as date)
where Y.Seq = 1
	and Y.IsCommissionable = 'YES'


--DEP0004	Preprocessor ProductCategory NonCommissionable OutSide Calendar Year		
--		Preconditions	
--			Product IsCommissionable = 1 in cfgICSProductCategory table
--			Product with dates outside the calendar years
			
--		Expected	Rows tagged = 3 and IsCommissionable = N in the list of commissionable and non-commissionable product codes
--		Calc: ICS Preprocessor PREP1030 ProductCategory Tag Dates

select Y.*  
from (	
	select *, ROW_NUMBER() over(partition by X.BillingSubsystemID,X.ProductIDCode, X.StartDate order by cast(X.EndDate as date) desc) as Seq	
	from (	
		select distinct BillingSubsystemID,ProductIDCode,IsCommissionable
			, case when cast(StartDate as date)<='2012-01-01' then '2012-01-01' 
				else Convert(varchar(7),cast(StartDate as date),121)+'-01' end as StartDate
			,Convert(varchar(11),cast(EndDate as date),121) as EndDate
		from cfgICSProductCategory
		--where ProductIDCode = '1000A12M'
		) X
	) Y
	left join #CalcMonth M on CAST(Y.EndDate as date) >= cast(M.StartDate as date) 
		and  CAST(Y.EndDate as date) <= cast(M.EndDate as date)
where Y.Seq = 1
	and M.CurrentMonth is null
	and Y.IsCommissionable = 'YES'
	--and Y.StartDate = '2012-06-01'
	

--DEP0005	Preprocessor ProductCategory NonCommissionable end date matches the end date of a month in the calendar		
--		Preconditions	
--			Product IsCommissionable = 1 in cfgICSProductCategory table
--			Product with end date matches the end date of a month in the calendar
			
--		Expected	Rows tagged = 5 and IsCommissionable = N in the list of commissionable and non-commissionable product codes
--		Calc: ICS Preprocessor PREP1030 ProductCategory Tag Dates


select Y.*  
from (	
	select *, ROW_NUMBER() over(partition by X.BillingSubsystemID,X.ProductIDCode, X.StartDate order by cast(X.EndDate as date) desc) as Seq	
	from (	
		select distinct BillingSubsystemID,ProductIDCode,IsCommissionable
			, case when cast(StartDate as date)<='2012-01-01' then '2012-01-01' 
				else Convert(varchar(7),cast(StartDate as date),121)+'-01' end as StartDate
			,Convert(varchar(11),cast(EndDate as date),121) as EndDate
		from cfgICSProductCategory
		--where ProductIDCode = '1000A12M'
		) X
	) Y
	inner join #CalcMonth M on CAST(Y.EndDate as date) = cast(M.EndDate as date)
where Y.Seq = 1
	and Y.IsCommissionable = 'YES'
	--and Y.StartDate = '2012-06-01'