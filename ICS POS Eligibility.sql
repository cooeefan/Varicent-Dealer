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


/***************************************************
*                 POS Eligibility                  *
*      #POSEligibility has all eligible records    *
****************************************************/

IF OBJECT_ID('tempdb..#POSEligibility') is not Null
drop table #POSEligibility

select T.*,D.DealerName,D.MasterDealerCode,D.CurrentMonth,D.ContractHolderID,D.ContractID,D.ContractHolderChannel,D.ContractChannel,D.ChannelType,D.AgreementType 
into #POSEligibility
from tsdICSPOSTransaction T
	left join tsdICSManualExcludePOS E on T.TransactionID = E.TransactionID
		and T.BillingSubSystemID = E.BillingSubSystemID
		and T.POSType = E.POSType
		and T.ActivityType = E.ActivityType
		and CAST(T.EffectiveCalcDate as date) = CAST(E.EffectiveCalcDate as date)
	inner join #DealerMonthlyEligibility D on D.SalesCode = T.SalesPersonCode
		and CAST(T.EffectiveCalcDate as date) between D.MonthStartDate and D.MonthEndDate 
	inner join #ProductEligibility P on T.SKU = P.ProductIDCode
		and T.BillingSubsystemID = P.BillingSubsystemID
		and CAST(T.EffectiveCalcDate as date) between P.StartDate and P.EndDate
where E.EffectiveCalcDate is null
	and T.TransactionID not in (		----- Verify Mobile Banking eligibility
		select T1.TransactionID
		from tsdICSPOSTransaction T1
			inner join cfgICSProductCategory C on T.SKU = C.ProductIDCode 
				and T1.IsTMO = 'Y'
				and C.Level = 'ACCESSORY DBCARD'
				and CAST(T.EffectiveCalcDate as date) between CAST(C.StartDate as date) and CAST(C.EndDate as date)
				and IsCommissionable = 'YES'
			inner join archICSPaidPOSTransaction A on A.MSISDN = T1.MSISDN
				and A.SKU = T1.SKU
		where DATEDIFF(mm,A.EffectiveCalcDate,T1.EffectiveCalcDate) <= 6
		)

--select * from tsdICSPOSTransaction
--where MSISDN in (
--select MSISDN
--from #POSEligibility
--group by MSISDN
--having COUNT(TransactionID) > 1)
--order by MSISDN



/******************************************************************************
*                                                                             *
*                  Positive Scenarios Test Result                             *
*                                                                             *
******************************************************************************/

--DEL0500	POS transaction Accesory					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExcludePOS”, there were manually excluded by the business			
--			Dealer codes eligible for transactions based on sales code hierarchy			
--			Eligible commissionable SKUs for transactions			
--			Transaction in POS Feed with substring(SAPTRANSTYPECODE,1,1) = 'A'			
						
--		Expected	Transaction is Eligible			
--			Transaction available in the list of Eligible POS transactions with Commissionable SKU			

select *
from #POSEligibility
where substring(SAPTRANSTYPECODE,1,1) = 'A'

--DEL0501	POS transaction PostPaid Activation					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExcludePOS”, there were manually excluded by the business			
--			Dealer codes eligible for transactions based on sales code hierarchy			
--			Eligible commissionable SKUs for transactions			
--			Transaction in POS Feed with substring(SAPTRANSTYPECODE,1,1) = 'B'			
						
--		Expected	Transaction is Eligible			
--			Transaction available in the list of Eligible POS transactions with Commissionable SKU			

select *
from #POSEligibility
where substring(SAPTRANSTYPECODE,1,1) = 'B'

--DEL0502	POS transaction Prepaid Activation					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExcludePOS”, there were manually excluded by the business			
--			Dealer codes eligible for transactions based on sales code hierarchy			
--			Eligible commissionable SKUs for transactions			
--			Transaction in POS Feed with substring(SAPTRANSTYPECODE,1,1) = 'C'			
						
--		Expected	Transaction is Eligible			
--			Transaction available in the list of Eligible POS transactions with Commissionable SKU		

select *
from #POSEligibility
where substring(SAPTRANSTYPECODE,1,1) = 'C'

--DEL0503	POS transaction Upgrade					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExcludePOS”, there were manually excluded by the business			
--			Dealer codes eligible for transactions based on sales code hierarchy			
--			Eligible commissionable SKUs for transactions			
--			Transaction in POS Feed with substring(SAPTRANSTYPECODE,1,1) = 'F'			
						
--		Expected	Transaction is Eligible			
--			Transaction available in the list of Eligible POS transactions with Commissionable SKU			

select *
from #POSEligibility
where substring(SAPTRANSTYPECODE,1,1) = 'F'

--DEL0504	POS transaction Other					
--		Preconditions				
--			Transactions not present in table “tsdICSManualExcludePOS”, there were manually excluded by the business			
--			Dealer codes eligible for transactions based on sales code hierarchy			
--			Eligible commissionable SKUs for transactions			
--			Transaction in POS Feed with substring(SAPTRANSTYPECODE,1,1) <> 'A','B','C','F'			
						
--		Expected	Transaction is Eligible			
--			Transaction available in the list of Eligible POS transactions with Commissionable SKU			

select *
from #POSEligibility
where substring(IsNull(SAPTRANSTYPECODE,'N/A'),1,1) not in ( 'A','B','C','F')



/******************************************************************************
*                                                                             *
*                  Positive Scenarios Test Result                             *
*                                                                             *
******************************************************************************/

--DEL0550N	Transactions  have been manually excluded by the business in the table “tsdICSManualExcludePOS”					

select distinct T.* 
from tsdICSPOSTransaction T
	inner join tsdICSManualExcludePOS E on T.TransactionID = E.TransactionID
		and T.BillingSubSystemID = E.BillingSubSystemID
		and T.POSType = E.POSType
		and T.ActivityType = E.ActivityType
		and CAST(T.EffectiveCalcDate as date) = CAST(E.EffectiveCalcDate as date)
		

--DEL0551N	Non-eligible dealer codes for transactions based on sales code hierarchy	
				
select distinct T.*
from tsdICSPOSTransaction T
	left join tsdICSManualExcludePOS E on T.TransactionID = E.TransactionID
		and T.BillingSubSystemID = E.BillingSubSystemID
		and T.POSType = E.POSType
		and T.ActivityType = E.ActivityType
		and CAST(T.EffectiveCalcDate as date) = CAST(E.EffectiveCalcDate as date)
	left join #DealerMonthlyEligibility D on D.SalesCode = T.SalesPersonCode
		and CAST(T.EffectiveCalcDate as date) between D.MonthStartDate and D.MonthEndDate 
where E.TransactionID is null
	and D.SalesCode is null
	

--DEL0552N	Non-eligible commissionable valid SKU for transactions					

select distinct T.* 
from tsdICSPOSTransaction T
	left join tsdICSManualExcludePOS E on T.TransactionID = E.TransactionID
		and T.BillingSubSystemID = E.BillingSubSystemID
		and T.POSType = E.POSType
		and T.ActivityType = E.ActivityType
		and CAST(T.EffectiveCalcDate as date) = CAST(E.EffectiveCalcDate as date)
	inner join #DealerMonthlyEligibility D on D.SalesCode = T.SalesPersonCode
		and CAST(T.EffectiveCalcDate as date) between D.MonthStartDate and D.MonthEndDate 
	left join #ProductEligibility P on T.SKU = P.ProductIDCode
		and T.BillingSubsystemID = P.BillingSubsystemID
		and CAST(T.EffectiveCalcDate as date) between P.StartDate and P.EndDate
where E.EffectiveCalcDate is null
	and P.ProductIDCode is null