USE [AbrBV_Reporting_DEV]
GO

-- ===============================================================
-- Author:		Jan Neubert, Antje Buksch
-- Create date: 2022-01-12
-- Description:	Befüllung der Steuerungs- und Quartalstabelle
-- ===============================================================
CREATE PROCEDURE [HZV].[SP_Steuerung_Quartale]
AS
BEGIN
	--Steuertabelle befüllen
	  update HZV.Steuerung
	  set 
		 Q_Dashboard_kurz=  (select max(quartal) from [HZV].[NVI]) 
		,Q_Dashboard_lang=	concat( left((select max(quartal) from [HZV].[NVI]),4),'0',right((select max(quartal) from [HZV].[NVI]),1))
		,LastUpdate=getdate()


	--Quartalstabelle auf Basis aller vorhandenen Quartale befüllen
	DELETE FROM [HZV].[Quartale]

	INSERT INTO [HZV].[Quartale]
	SELECT
		Quartal_kurz = CASE WHEN LEN(Quartal) = 5 THEN Quartal ELSE CONCAT(LEFT(Quartal,4),RIGHT(Quartal,1)) END,
		Quartal_lang = CASE WHEN LEN(Quartal) = 6 THEN Quartal ELSE CONCAT(LEFT(Quartal,4),0,RIGHT(Quartal,1)) END,
		Quartal_Beginn = 
			CASE 
				WHEN RIGHT(Quartal,1) = 1 THEN CAST(CONCAT(LEFT(Quartal,4),'-01-01') AS date)
				WHEN RIGHT(Quartal,1) = 2 THEN CAST(CONCAT(LEFT(Quartal,4),'-04-01') AS date)
				WHEN RIGHT(Quartal,1) = 3 THEN CAST(CONCAT(LEFT(Quartal,4),'-07-01') AS date)
				WHEN RIGHT(Quartal,1) = 4 THEN CAST(CONCAT(LEFT(Quartal,4),'-10-01') AS date)
			END,
		Quartal_Ende =
			CASE 
				WHEN RIGHT(Quartal,1) = 1 THEN CAST(CONCAT(LEFT(Quartal,4),'-03-31') AS date)
				WHEN RIGHT(Quartal,1) = 2 THEN CAST(CONCAT(LEFT(Quartal,4),'-06-30') AS date)
				WHEN RIGHT(Quartal,1) = 3 THEN CAST(CONCAT(LEFT(Quartal,4),'-09-30') AS date)
				WHEN RIGHT(Quartal,1) = 4 THEN CAST(CONCAT(LEFT(Quartal,4),'-12-31') AS date)
			END,
		Quartal_Text_kurz =
			CASE 
				WHEN RIGHT(Quartal,1) = 1 THEN CONCAT('Q1/',LEFT(Quartal,4))
				WHEN RIGHT(Quartal,1) = 2 THEN CONCAT('Q2/',LEFT(Quartal,4))
				WHEN RIGHT(Quartal,1) = 3 THEN CONCAT('Q3/',LEFT(Quartal,4))
				WHEN RIGHT(Quartal,1) = 4 THEN CONCAT('Q4/',LEFT(Quartal,4))
			END,
		Quartal_Text_lang =
			CASE 
				WHEN RIGHT(Quartal,1) = 1 THEN CONCAT('1. Quartal ',LEFT(Quartal,4))
				WHEN RIGHT(Quartal,1) = 2 THEN CONCAT('2. Quartal ',LEFT(Quartal,4))
				WHEN RIGHT(Quartal,1) = 3 THEN CONCAT('3. Quartal ',LEFT(Quartal,4))
				WHEN RIGHT(Quartal,1) = 4 THEN CONCAT('4. Quartal ',LEFT(Quartal,4))
			END
	FROM
		(
		SELECT DISTINCT Quartal FROM [HZV].[Bereinigung]
		UNION 
		SELECT DISTINCT Quartal FROM [HZV].[NVI]
		) Q
END
GO

-- =========================================================================================================
-- Author:		Jan Neubert
-- Create date: 2022-01-11
-- Description:	Abzug der Bereinigungsdaten für den HZV Report inkl. Löschen upzudatender und veralteter DS
-- =========================================================================================================
CREATE PROCEDURE [HZV].[SP_Bereinigung]
AS
BEGIN
	--Löschen von DS die in der Controlling aktualisiert wurden
	delete t1	--select t1.*
	from   [HZV].[Bereinigung] t1
	inner join
	 ( select [VERTRAGS_ID]
		  ,[VERTRAGS_KV]
		  ,[WOHNORT_KV]
		  ,[QUARTAL]
		  ,[IK]
	  FROM [AbrBV_Controlling_PROD].[HzV].[Bereinigungsuebersicht]
	  where LastUpdate> (select LastUpdate from HZV.Steuerung )
	  ) t2
	on t1.[VERTRAGS_ID]=t2.[VERTRAGS_ID]
	and t1.[VERTRAGS_KV]=t2.[VERTRAGS_KV]
	and t1.[WOHNORT_KV]=t2.[WOHNORT_KV]
	and t1.[QUARTAL]=t2.[QUARTAL]
	and t1.HauptKassenIK=t2.[IK]

	--Befüllen der Bereinigungsübersicht nach Reporting für DS die seit dem letzten Update in der Controlling aktualisiert wurden
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
	  where LastUpdate> (select LastUpdate from HZV.Steuerung )


	--Löschen der Datensätze, die älter als 5 Jahre sind
	delete		--select*
	from [HZV].[Bereinigung]
	where left(quartal,4) < year(getdate())-4
END
GO

-- =================================================================================
-- Author:		Jan Neubert
-- Create date: 2022-01-12
-- Description:	Abzug der NVI-Daten für den HZV Report inkl. Löschen veralteter DS
-- =================================================================================
CREATE PROCEDURE [HZV].[SP_NVI]
AS
BEGIN
	--Import regelmäßig
	insert into [HZV].[NVI]
	SELECT 
		  [VERTRAGSNUMMER] 
		  ,[KV]
		  ,[KV_WOHNORT]	 	  
		  ,t1.[QUARTAL]
		  , SKUNDE
		  ,[VKNR]
		  ,SVP
		  ,SMA
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
		  ,NVI_VI_AI as [NVI_KNZ]			--		select *
	  FROM AbrBV_Controlling_PROD.[HzV].NVI_PRUEF t1
	  left join ( select distinct QUARTAL from [HZV].[NVI]) t2  
	  on t1.QUARTAL=t2.Quartal
	  where t2.Quartal is null			--zieht nur Quartale, die bislang nicht auf der Reporting DB vorliegen

	--Löschen der Datensätze, die älter als 5 Jahre sind
	delete		--select*
	from [HZV].[NVI]
	where left(quartal,4) < year(getdate())-4
END
GO