USE [AbrBV_Reporting_DEV]

--Import initial Bereinigungsübersicht aus Controlling DB
insert into [HZV].[Bereinigung]
SELECT [VERTRAGS_ID]
      ,[VERTRAGS_KV]
      ,[WOHNORT_KV]
	  ,[QUARTAL]
      ,[IK] as HauptKassenIK
      ,[VKNR]
      ,[Anzahl_Versicherte]
      ,[Anzahl_Neueinschreiber]
      ,[Diff_kons_Punkte]
      ,[Diff_kons_Euro]
      ,[Gesamt_fortentw_Punkte]
	  ,[Gesamt_Euro]-[Diff_kons_Euro]
      ,[Gesamt_Punkte]
      ,[Gesamt_Euro]     
  FROM [AbrBV_Controlling_PROD].[HzV].[Bereinigungsuebersicht]
  where QUARTAL>=20181

--Import initial NVI aus Controlling DB
insert into [HZV].[NVI]
SELECT 
      [VERTRAGSNUMMER] 
      ,[KV]
      ,[KV_WOHNORT]	 	  
	  ,[QUARTAL]
      , case when [SKUNDE] is null then H2IK else SKUNDE end as SKunde_neu
      ,[VKNR]
      ,case when ([SVP] is null or svp='') then		
				case when (EGK_NR is null or EGK_NR='') then EGK_NR_MA else EGK_NR end else svp end as SVP_neu
      ,case when [SMA] is null and EGK_NR_MA='' then '0' 
			when [SMA] is null and EGK_NR_MA<>'' then 'MA' 
			else SMA end as SMA_neu
      ,[ERSATZVERFAHREN]
      ,[NACHNAME]
      ,[VORNAME]
      ,[GEBURTSDATUM]
      ,[LANR_Betreu]
      ,[BSNR_Betreu]
      ,[LANR]
      ,[BSNR]
      ,[GO_NR]
      ,[MENGE]
      ,[BETRAG]
      ,[NVI_KNZ]			--		select count(*)
  FROM AbrBV_Controlling_PROD.[HzV].[NVI_Archiv]
  where QUARTAL>=20181

