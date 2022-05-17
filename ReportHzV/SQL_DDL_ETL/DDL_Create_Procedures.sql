USE [AbrBV_Reporting_DEV]
GO

-- ===========================================================
-- Author:		Antje Buksch
-- Create date: 2022-01-13
-- Description:	Abzug der verfügbaren Kassen für HZV-Report
-- ===========================================================
CREATE PROCEDURE [HZV].[SP_Kassen]
AS
BEGIN

SET XACT_ABORT ON
BEGIN TRAN
	DELETE FROM [HZV].[Kassen]

	INSERT INTO [HZV].[Kassen]
	SELECT        0 AS Id, '000000000' AS HauptKassenIK, 'alle Kassen' AS KasseName
	UNION
	SELECT
		RANK() OVER (ORDER BY K.KasseName) AS Id, 
		K.*
	FROM
		(
		SELECT DISTINCT
			V.HauptKassenIK,
			TRIM(V.KasseName) AS KasseName
		FROM [HZV].[Vertraege] V
		WHERE V.DienstleistungEnde >= (SELECT MIN(Quartal_kurz) FROM [HZV].[Quartale]) OR V.DienstleistungEnde IS NULL
		) K
COMMIT TRAN

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-26
-- Description:	Zusammenstellen aller relevanten Daten zur Berechnung der durchschnittlichen Kosten
-- =============================================
CREATE PROCEDURE [HZV].[SP_Kosten]
AS
BEGIN

SET XACT_ABORT ON
BEGIN TRAN
	--Tabelle leeren
	DELETE FROM [HZV].[Kosten]

	--Daten importieren
	INSERT INTO [HZV].[Kosten]
	SELECT 
		V.Quartal,
		CONCAT(LEFT(V.Quartal,4),RIGHT(V.Quartal,1)) AS Quartal_kurz,
		V.VertragsKV,
		V.H2IK,
		COUNT(V.sVP) AS AnzTNM,
		CASE WHEN A.BtrABR IS NULL THEN 0 ELSE A.BtrABR END AS BtrABR,
		CASE WHEN B.BtrBER IS NULL THEN 0 ELSE B.BtrBER END AS BtrBER,
		CASE WHEN N.BtrNVI IS NULL THEN 0 ELSE N.BtrNVI END AS BtrNVI
	FROM [HZV].[Teilnehmer_Versicherte] V
	LEFT JOIN
		(
		SELECT
			S_ABRECHNUNGSQUARTAL,
			KV,
			H2IK,
			SUM(BTR) AS BtrABR
		FROM
			(
			SELECT 
				S_ABRECHNUNGSQUARTAL,
				KV,
				H2IK,
				SUM(NETTOBETRAG_GONR) * CASE WHEN VERARBEITUNGS_KNZ = '10' THEN 1 ELSE -1 END AS BTR
			FROM [HZV].[Abrechnung_Einzelfall]
			WHERE LEFT(S_ABRECHNUNGSQUARTAL,4) >= '2020'
			AND S_ABRECHNUNGSQUARTAL <= (SELECT Q_Dashboard_lang FROM [HZV].[Steuerung])
			GROUP BY S_ABRECHNUNGSQUARTAL,VERARBEITUNGS_KNZ,KV,H2IK
			) T
		GROUP BY S_ABRECHNUNGSQUARTAL,KV,H2IK
		) A
		ON A.S_ABRECHNUNGSQUARTAL = V.Quartal
		AND A.KV = V.VertragsKV
		AND A.H2IK = V.H2IK
	LEFT JOIN
		(
		SELECT
			B.QUARTAL,
			Q.Quartal_lang,
			B.VERTRAGS_KV,
			B.HauptKassenIK,
			SUM(B.Gesamt_Euro) AS BtrBER
		FROM [HZV].[Bereinigung] B
		JOIN [HZV].[Quartale] Q
			ON Q.Quartal_kurz = B.QUARTAL
		WHERE LEFT(B.QUARTAL,4) >= '2020'
		AND B.QUARTAL <= (SELECT Q_Dashboard_kurz FROM [HZV].[Steuerung])
		GROUP BY B.QUARTAL,Q.Quartal_lang,B.VERTRAGS_KV,B.HauptKassenIK
		) B
		ON B.Quartal_lang = V.Quartal
		AND B.VERTRAGS_KV = V.VertragsKV
		AND B.HauptKassenIK = V.H2IK
	LEFT JOIN
		(
		SELECT
			N.Quartal,
			Q.Quartal_lang,
			N.VertragsKV,
			N.H2IK,
			SUM(N.MENGE * N.BETRAG) AS BtrNVI
		FROM [HZV].[NVI] N
		JOIN [HZV].[Quartale] Q
			ON Q.Quartal_kurz = N.Quartal
		WHERE LEFT(N.Quartal,4) >= '2020'
		AND N.Quartal <= (SELECT Q_Dashboard_kurz FROM [HZV].[Steuerung])
		GROUP BY N.Quartal,Q.Quartal_lang,N.VertragsKV,N.H2IK
		) N
		ON N.Quartal_lang = V.Quartal
		AND N.VertragsKV = V.VertragsKV
		AND N.H2IK = V.H2IK
	WHERE LEFT(V.Quartal,4) >= '2020'
		AND V.Quartal <= (SELECT Q_Dashboard_lang FROM [HZV].[Steuerung])
		AND V.Teilnahme_Ende IS NULL
	GROUP BY V.Quartal,B.Quartal,V.VertragsKV,V.H2IK,A.BtrABR,B.BtrBER,N.BtrNVI
	ORDER BY V.Quartal,V.VertragsKV,V.H2IK
COMMIT TRAN

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-02-04
-- Description:	Tabelle [HZV].[Berichte_Kundenportal] befüllen
-- =============================================
CREATE PROCEDURE [HZV].[SP_Berichte_Kundenportal]
AS
BEGIN

SET XACT_ABORT ON
BEGIN TRAN
	DELETE FROM [HZV].[Berichte_Kundenportal]

	----Controllingbericht HzV
	--INSERT INTO [HZV].[Berichte_Kundenportal]
	--SELECT DISTINCT
	--	K.HauptKassenIK,
	--	K.KasseName,
	--	4 AS BereichId,						--1 = Teilnehmermanagement, 2 = Bereinigung, 3 = Abrechnung, 4 = Sonstiges
	--	'Sonstiges' AS Bereich,
	--	'Controlling Hausarztzentrierte Versorgung' AS Berichtsbezeichnung,
	--	'HZV_Dashboard.rdl' AS ReportRDL
	--FROM 
	--	(
	--	SELECT
	--		RANK() OVER (ORDER BY K.KasseName) AS Id, 
	--		K.*
	--	FROM
	--		(
	--		SELECT DISTINCT
	--			V.HauptKassenIK,
	--			TRIM(V.KasseName) AS KasseName
	--		FROM [HZV].[Vertraege] V
	--		WHERE V.DienstleistungEnde >= (SELECT MIN(Quartal_kurz) FROM [HZV].[Quartale]) OR V.DienstleistungEnde IS NULL
	--		) K
	--	)K
	--JOIN [HZV].[Ansprechpartner_Kasse] P
	--	ON P.KassenIK = K.HauptKassenIK

	--Bereinigungsübersicht
	INSERT INTO [HZV].[Berichte_Kundenportal]
	SELECT DISTINCT
		K.IK,
		K.KasseName,
		2 AS BereichId,						--1 = Teilnehmermanagement, 2 = Bereinigung, 3 = Abrechnung, 4 = Sonstiges
		'Bereinigung' AS Bereich,
		'Bereinigungsübersicht',
		'Bereinigungsuebersicht.rdl'
	FROM 
		(
		SELECT
			RANK() OVER (ORDER BY K.KasseName) AS Id, 
			K.*		
		FROM
			(
			SELECT DISTINCT B.IK,TRIM(V.KasseName) AS KasseName
			FROM [AbrBV_Controlling_PROD].[HzV].[Bereinigungsuebersicht] B
			JOIN 
				(
				SELECT 
					HauptIK,
					KasseName,
					KV,
					KVBezeichnung,
					Vertragskennzeichen,
					QuartalVon,
					CASE WHEN QuartalBis IS NULL THEN '99994' ELSE QuartalBis END AS QuartalBis
				FROM [AbrBV_Controlling_PROD].[dbo].[Vertrag_Kassen] 
				WHERE Dienstleistung = 'Bereinigung'
				) V
				ON V.HauptIK = B.IK
				AND V.Vertragskennzeichen = B.VERTRAGS_ID
				AND V.KV = B.VERTRAGS_KV
				AND B.QUARTAL BETWEEN V.QuartalVon AND V.QuartalBis
			) K
		) K
	JOIN [HZV].[Ansprechpartner_Kasse] P
		ON P.KassenIK = K.IK

	--Übersicht Datenlieferungen
	INSERT INTO [HZV].[Berichte_Kundenportal]
	SELECT DISTINCT
		(K.HauptIK COLLATE Latin1_General_CI_AS) AS HauptIK,
		K.HauptIK_Name,
		3 AS BereichId,						--1 = Teilnehmermanagement, 2 = Bereinigung, 3 = Abrechnung, 4 = Sonstiges
		'Abrechnung' AS Bereich, 
		'Übersicht Datenlieferungen',
		'Uebersicht_Datenlieferungen.rdl'
	FROM 
		(
		SELECT
			RANK() OVER (ORDER BY K.HauptIK_Name) AS Id, 
			K.*		
		FROM
			(
			SELECT DISTINCT
				TRIM(Z.KURZBEZEICHNUNG) AS HauptIK_Name,
				Z.KASSEN_IK AS HauptIK
			FROM
				(
				SELECT DISTINCT
					Z.KURZBEZEICHNUNG,
					CASE WHEN Z.VERKNUEPFUNGS_IK = '?' OR Z.VERKNUEPFUNGS_IK IS NULL THEN Z.KASSEN_IK ELSE Z.VERKNUEPFUNGS_IK END AS KassenIK
				FROM
					(
					SELECT DISTINCT
						K.KURZBEZEICHNUNG,
						CASE WHEN K.VERKNUEPFUNGS_IK = '?' OR K.VERKNUEPFUNGS_IK IS NULL THEN P.KassenIK ELSE K.VERKNUEPFUNGS_IK END AS KassenIK
					FROM [AbrBV_Edifact_PROD].[dbo].[Protokolltabelle] P
					LEFT JOIN [AbrBV_Edifact_PROD].[dbo].[Kassenliste_short] K
						ON K.KASSEN_IK = P.KassenIK
					WHERE P.Status = 3
					) K
				JOIN [AbrBV_Edifact_PROD].[dbo].[Kassenliste_short] Z
					ON Z.KASSEN_IK = K.KassenIK
				) K
			JOIN [AbrBV_Edifact_PROD].[dbo].[Kassenliste_short] Z
				ON Z.KASSEN_IK = K.KassenIK
			) K
		) K
	JOIN [HZV].[Ansprechpartner_Kasse] P
		ON P.KassenIK = (K.HauptIK COLLATE Latin1_General_CI_AS)
COMMIT TRAN

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-02-04
-- Description:	Ausgabe der Portal-Reports entsprechend des ausführenden Users
-- =============================================
CREATE PROCEDURE [HZV].[SP_Steuerung_Berichte_Kundenportal](@User varchar(100))
AS
BEGIN

	--SET @User = 'spectrumk\antje.ockert'
	--SET @User = 'ina.stellmacher@bkk-vbu.de'
	--SET @User = 'busch.claudia@bkk-salzgitter.de'


	DECLARE @AtPos int = CHARINDEX('@',@User,0)
	DECLARE @RestLaenge int = LEN(@User) - @AtPos
	DECLARE @Suffix varchar(50) = LOWER(RIGHT(@User,@RestLaenge))
	

	IF(CHARINDEX('spectrum',@Suffix) = 0)
	BEGIN	
		SELECT 
			R.*
		FROM
			(
			SELECT *
			FROM [HZV].[Berichte_Kundenportal]
			) R
		JOIN [HZV].[Ansprechpartner_Kasse] P 
			ON P.KassenIK = R.KassenIK
		WHERE P.Email = @User
	END

	IF(CHARINDEX('spectrum',@Suffix) > 0)
	BEGIN
		SELECT *
		FROM [HZV].[Berichte_Kundenportal]
	END

END

-- =============================================
-- Author:		Jan Neubert, Antje Buksch
-- Create date: 2022-01-12
-- Description:	Befüllung der Steuerungs- und Quartalstabelle
-- =============================================
CREATE PROCEDURE [HZV].[SP_Steuerung_Quartale]
AS
BEGIN

SET XACT_ABORT ON
BEGIN TRAN
	--Steuertabelle befüllen
	update HZV.Steuerung
	set 
	 Q_Dashboard_kurz=  (select max(quartal) from [HZV].[NVI]) 
	,Q_Dashboard_lang=	concat( left((select max(quartal) from [HZV].[NVI]),4),'0',right((select max(quartal) from [HZV].[NVI]),1))
	,LastUpdate=getdate()

	--Quartalstabelle auf Basis aller vorhandenen Quartale befüllen
	DELETE FROM [HZV].[Quartale]

	INSERT INTO [HZV].[Quartale]
	SELECT DISTINCT
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
		UNION 
		SELECT DISTINCT S_ABRECHNUNGSQUARTAL FROM [HZV].[Abrechnung_Einzelfall]
		UNION
		SELECT DISTINCT Quartal FROM [HZV].[Teilnehmer_Versicherte]
		) Q
COMMIT TRAN

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-26
-- Description:	Dataset für Entgeltdaten
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_Abrechnung_Entgelt] (@Kasse char(9), @Quartal char(6), @KV char(2))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT
			ENT.S_ABRECHNUNGSQUARTAL,
			ENT.KV,
			ENT.ABRECHNUNGSQUARTAL AS LEISTUNGSQUARTAL,
			Quartal_Text_kurz =
				CASE 
					WHEN RIGHT(ENT.ABRECHNUNGSQUARTAL,1) = 1 THEN CONCAT('Q1/',LEFT(ENT.ABRECHNUNGSQUARTAL,4))
					WHEN RIGHT(ENT.ABRECHNUNGSQUARTAL,1) = 2 THEN CONCAT('Q2/',LEFT(ENT.ABRECHNUNGSQUARTAL,4))
					WHEN RIGHT(ENT.ABRECHNUNGSQUARTAL,1) = 3 THEN CONCAT('Q3/',LEFT(ENT.ABRECHNUNGSQUARTAL,4))
					WHEN RIGHT(ENT.ABRECHNUNGSQUARTAL,1) = 4 THEN CONCAT('Q4/',LEFT(ENT.ABRECHNUNGSQUARTAL,4))
				END,
			ENT.VERARBEITUNGS_KNZ,
			ENT.GO_NR,
			LP.Leistung_Text,
			SUM(ENT.ANZ_GONR) * CASE WHEN ENT.VERARBEITUNGS_KNZ = '10' THEN 1 ELSE -1 END AS ANZ_GONR,
			SUM(ENT.ANZ_GONR * ENT.WERT_GONR) * CASE WHEN ENT.VERARBEITUNGS_KNZ = '10' THEN 1 ELSE -1 END AS BETRAG
		FROM [HZV].[Abrechnung_Entgelt] ENT
		LEFT JOIN [HZV].[Vertraege] VER
			ON VER.VertragsID = ENT.VERTRAGS_ID
			AND VER.VertragsKV = ENT.KV
			AND VER.HauptKassenIK = ENT.H2IK
			AND VER.Dienstleistung = 'Abrechnung'
		LEFT JOIN [HZV].[LeistungsPositionen] LP
			ON LP.Leistung = ENT.GO_NR
			AND ENT.LEISTUNGS_DATUM BETWEEN LP.GueltigVon AND LP.GueltigBis
			AND LP.VertragID = VER.ID
		WHERE ENT.S_ABRECHNUNGSQUARTAL = @Quartal
			AND ENT.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
			AND ENT.KV = @KV
			AND ENT.GO_NR != '999999999999'
		GROUP BY ENT.S_ABRECHNUNGSQUARTAL,ENT.ABRECHNUNGSQUARTAL,ENT.KV,ENT.VERARBEITUNGS_KNZ,ENT.GO_NR,LP.Leistung_Text
		ORDER BY ENT.KV,ENT.ABRECHNUNGSQUARTAL,ENT.VERARBEITUNGS_KNZ,ENT.GO_NR
	END
	ELSE BEGIN
		SELECT
			ENT.S_ABRECHNUNGSQUARTAL,
			ENT.KV,
			ENT.ABRECHNUNGSQUARTAL AS LEISTUNGSQUARTAL,
			Quartal_Text_kurz =
				CASE 
					WHEN RIGHT(ENT.ABRECHNUNGSQUARTAL,1) = 1 THEN CONCAT('Q1/',LEFT(ENT.ABRECHNUNGSQUARTAL,4))
					WHEN RIGHT(ENT.ABRECHNUNGSQUARTAL,1) = 2 THEN CONCAT('Q2/',LEFT(ENT.ABRECHNUNGSQUARTAL,4))
					WHEN RIGHT(ENT.ABRECHNUNGSQUARTAL,1) = 3 THEN CONCAT('Q3/',LEFT(ENT.ABRECHNUNGSQUARTAL,4))
					WHEN RIGHT(ENT.ABRECHNUNGSQUARTAL,1) = 4 THEN CONCAT('Q4/',LEFT(ENT.ABRECHNUNGSQUARTAL,4))
				END,
			ENT.VERARBEITUNGS_KNZ,
			ENT.GO_NR,
			LP.Leistung_Text,
			SUM(ENT.ANZ_GONR) * CASE WHEN ENT.VERARBEITUNGS_KNZ = '10' THEN 1 ELSE -1 END AS ANZ_GONR,
			SUM(ENT.ANZ_GONR * ENT.WERT_GONR) * CASE WHEN ENT.VERARBEITUNGS_KNZ = '10' THEN 1 ELSE -1 END AS BETRAG
		FROM [HZV].[Abrechnung_Entgelt] ENT
		JOIN [HZV].[Vertraege] VER
			ON VER.VertragsID = ENT.VERTRAGS_ID
			AND VER.VertragsKV = ENT.KV
			AND VER.HauptKassenIK = ENT.H2IK
			AND VER.Dienstleistung = 'Abrechnung'
		LEFT JOIN [HZV].[LeistungsPositionen] LP
			ON LP.Leistung = ENT.GO_NR
			AND ENT.LEISTUNGS_DATUM BETWEEN LP.GueltigVon AND LP.GueltigBis
			AND LP.VertragID = VER.ID
		WHERE ENT.S_ABRECHNUNGSQUARTAL = @Quartal
			AND ENT.h2ik = @Kasse
			AND ENT.KV = @KV
			AND ENT.GO_NR != '999999999999'
		GROUP BY ENT.S_ABRECHNUNGSQUARTAL,ENT.ABRECHNUNGSQUARTAL,ENT.KV,ENT.VERARBEITUNGS_KNZ,ENT.GO_NR,LP.Leistung_Text
		ORDER BY ENT.KV,ENT.ABRECHNUNGSQUARTAL,ENT.VERARBEITUNGS_KNZ,ENT.GO_NR
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-26
-- Description:	Dataset für verfügbare KV-Regionen auf Basis der Abrechnungsdaten
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_Abrechnung_KVRegionen] (@Kasse char(9), @Quartal char(6))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT DISTINCT T.KV,KV.KV_kurz,KV.KV_lang,KV.Kuerzel_kurz,KV.Kuerzel_lang
		FROM [HZV].[Abrechnung_Einzelfall] T
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = T.KV
		WHERE T.S_ABRECHNUNGSQUARTAL = @Quartal
		AND T.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
	END
	ELSE BEGIN
		SELECT DISTINCT T.KV,KV.KV_kurz,KV.KV_lang,KV.Kuerzel_kurz,KV.Kuerzel_lang
		FROM [HZV].[Abrechnung_Einzelfall] T
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = T.KV
		WHERE T.H2IK = @Kasse
		AND T.S_ABRECHNUNGSQUARTAL = @Quartal
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-26
-- Description:	Dataset für verfügbare Quartale auf Basis der Abrechnungsdaten
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_Abrechnung_Quartale] (@Kasse char(9))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT DISTINCT T.S_ABRECHNUNGSQUARTAL,Q.Quartal_Text_kurz,Q.Quartal_Text_lang
		FROM [HZV].[Abrechnung_Einzelfall] T
		JOIN [HZV].[Quartale] Q
			ON Q.Quartal_lang = T.S_ABRECHNUNGSQUARTAL
		WHERE T.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
	END
	ELSE BEGIN
		SELECT DISTINCT T.S_ABRECHNUNGSQUARTAL,Q.Quartal_Text_kurz,Q.Quartal_Text_lang
		FROM [HZV].[Abrechnung_Einzelfall] T
		JOIN [HZV].[Quartale] Q
			ON Q.Quartal_lang = T.S_ABRECHNUNGSQUARTAL
		WHERE H2IK = @Kasse
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-04-06
-- Description:	Dataset für Verhältnis abgerechnete Teilnehmer zu eingeschriebenen Teilnehmern
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_Abrechnung_Quote] (@Kasse char(9), @Quartal char(6), @KV char(2))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT  
			ENT.S_ABRECHNUNGSQUARTAL,
			ENT.ABRECHNUNGSQUARTAL,
			Q.Quartal_Text_kurz,
			COUNT(DISTINCT ENT.SVP) AS AnzAbr,
			TV.AnzTNM,
			CAST(CAST(COUNT(DISTINCT ENT.SVP) AS float)/CAST(TV.AnzTNM AS float) AS decimal(6,5)) AS QuoteAbr
		FROM [HZV].[Abrechnung_Entgelt] ENT
		JOIN 
			(
			SELECT
				Quartal,
				VertragsKV,
				COUNT(DISTINCT sVP) AS AnzTNM
			FROM [HZV].[Teilnehmer_Versicherte]
			WHERE H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
				AND VertragsKV = @KV
				AND Teilnahme_Ende IS NULL
			GROUP BY Quartal,VertragsKV
			) TV
			ON TV.Quartal = ENT.ABRECHNUNGSQUARTAL
			AND TV.VertragsKV = ENT.KV
		JOIN [HZV].[Quartale] Q
			ON Q.Quartal_lang = ENT.ABRECHNUNGSQUARTAL
		WHERE ENT.GO_NR = 'H0000'
		AND ENT.S_ABRECHNUNGSQUARTAL = @Quartal
		AND ENT.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
		AND ENT.KV = @KV
		GROUP BY ENT.S_ABRECHNUNGSQUARTAL,ENT.ABRECHNUNGSQUARTAL,Q.Quartal_Text_kurz,TV.AnzTNM
	END
	ELSE BEGIN
		SELECT  
			ENT.S_ABRECHNUNGSQUARTAL,
			ENT.ABRECHNUNGSQUARTAL,
			Q.Quartal_Text_kurz,
			COUNT(DISTINCT ENT.SVP) AS AnzAbr,
			TV.AnzTNM,
			CAST(CAST(COUNT(DISTINCT ENT.SVP) AS float)/CAST(TV.AnzTNM AS float) AS decimal(6,5)) AS QuoteAbr
		FROM [HZV].[Abrechnung_Entgelt] ENT
		JOIN 
			(
			SELECT
				Quartal,
				H2IK,
				VertragsKV,
				COUNT(DISTINCT sVP) AS AnzTNM
			FROM [HZV].[Teilnehmer_Versicherte]
			WHERE H2IK = @Kasse					
				AND VertragsKV = @KV
				AND Teilnahme_Ende IS NULL
			GROUP BY Quartal,H2IK,VertragsKV
			) TV
			ON TV.Quartal = ENT.ABRECHNUNGSQUARTAL
			AND TV.H2IK = ENT.H2IK
			AND TV.VertragsKV = ENT.KV
		JOIN [HZV].[Quartale] Q
			ON Q.Quartal_lang = ENT.ABRECHNUNGSQUARTAL
		WHERE ENT.GO_NR = 'H0000'
		AND ENT.S_ABRECHNUNGSQUARTAL = @Quartal
		AND ENT.H2IK = @Kasse					
		AND ENT.KV = @KV
		GROUP BY ENT.S_ABRECHNUNGSQUARTAL,ENT.ABRECHNUNGSQUARTAL,Q.Quartal_Text_kurz,TV.AnzTNM
	END

END
GO

-- =============================================
-- Author:		Jan Neubert
-- Create date: 2022-01-26
-- Description:	Dataset für Ärzte inkl. Anzahl Versicherter
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_Aerzte] (@Kasse char(9), @Quartal char(6), @KV char(2))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		select 
			t3.Quartal_lang,
			t4.VertragsID,
			t4.HauptKassenIK, 
			t4.VertragsKV,
			t1.LANR7,
			t1.LANR_FG,
			t1.Vorname,
			t1.Nachname,
			t1.StrasseHausNr,
			t1.PLZ,
			t1.Ort,
			cast(t1.TeilnahmeBeginn as date) as TeilnahmeBeginn,
			cast(t1.TeilnahmeEnde as date) as  TeilnahmeEnde,
			count (t2.svp)	as Anzahl_Versicherte
			--			select*
		from [HZV].[Teilnehmer_Aerzte] t1
		inner join [HZV].[Vertraege] t4
			on t1.VertragsID=t4.VertragsID
			and t1.VertragsKV=t4.VertragsKV
			and t4.Dienstleistung='Teilnehmermanagement'
		inner join [HZV].[Quartale] t3
			on  concat ( Datepart(year,t1.TeilnahmeBeginn), datepart(quarter,t1.TeilnahmeBeginn)) <= t3.Quartal_kurz
			and concat ( Datepart(year,t1.TeilnahmeEnde), datepart(quarter,t1.TeilnahmeEnde)) >= t3.Quartal_kurz
		left join [HZV].[Teilnehmer_Versicherte] t2
			on t1.LANR7=t2.L_ARZT_NR
			and t1.VertragsID= t2.Vertrags_ID
			and t1.VertragsKV=t2.VertragsKV
			and t2.H2IK=t4.HauptKassenIK
			and t2.Teilnahme_Ende is null
			and t2.Quartal=t3.Quartal_lang
		where 
			t3.Quartal_lang=@Quartal
		and t1.VertragsKV=@KV
		and t4.HauptKassenIK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
		group by 
		t3.Quartal_lang,
		t4.VertragsID,
		t4.HauptKassenIK, 
		t4.VertragsKV,
		t1.LANR7,
		t1.LANR_FG,
		t1.Vorname,
		t1.Nachname,
		t1.StrasseHausNr,
		t1.PLZ,
		t1.Ort,
		t1.TeilnahmeBeginn,
		t1.TeilnahmeEnde

	END
	ELSE BEGIN
		select 
			t3.Quartal_lang,
			t4.VertragsID,
			t4.HauptKassenIK, 
			t4.VertragsKV,
			t1.LANR7,
			t1.LANR_FG,
			t1.Vorname,
			t1.Nachname,
			t1.StrasseHausNr,
			t1.PLZ,
			t1.Ort,
			cast(t1.TeilnahmeBeginn as date) as TeilnahmeBeginn,
			cast(t1.TeilnahmeEnde as date) as  TeilnahmeEnde,
			count (t2.svp)	as Anzahl_Versicherte
			--			select*
		from [HZV].[Teilnehmer_Aerzte] t1
		inner join [HZV].[Vertraege] t4
			on t1.VertragsID=t4.VertragsID
			and t1.VertragsKV=t4.VertragsKV
			and t4.Dienstleistung='Teilnehmermanagement'
		inner join [HZV].[Quartale] t3
			on  concat ( Datepart(year,t1.TeilnahmeBeginn), datepart(quarter,t1.TeilnahmeBeginn)) <= t3.Quartal_kurz
			and concat ( Datepart(year,t1.TeilnahmeEnde), datepart(quarter,t1.TeilnahmeEnde)) >= t3.Quartal_kurz
		left join [HZV].[Teilnehmer_Versicherte] t2
			on t1.LANR7=t2.L_ARZT_NR
			and t1.VertragsID= t2.Vertrags_ID
			and t1.VertragsKV=t2.VertragsKV
			and t2.H2IK=t4.HauptKassenIK
			and t2.Teilnahme_Ende is null
			and t2.Quartal=t3.Quartal_lang
		where 
			t3.Quartal_lang=@Quartal
		and t1.VertragsKV=@KV
		and t4.HauptKassenIK=@Kasse
		group by 
		t3.Quartal_lang,
		t4.VertragsID,
		t4.HauptKassenIK, 
		t4.VertragsKV,
		t1.LANR7,
		t1.LANR_FG,
		t1.Vorname,
		t1.Nachname,
		t1.StrasseHausNr,
		t1.PLZ,
		t1.Ort,
		t1.TeilnahmeBeginn,
		t1.TeilnahmeEnde

	END

END
GO

-- =============================================
-- Author:		Jan Neubert
-- Create date: 2022-02-04
-- Description:	Dataset für verfügbare KV-Regionen auf Basis der Arztdaten
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_Aerzte_KVRegionen] (@Kasse char(9), @Quartal char(6))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT DISTINCT T1.VertragsKV,KV.KV_kurz,KV.KV_lang,KV.Kuerzel_kurz,KV.Kuerzel_lang
		FROM [HZV].[Teilnehmer_Aerzte] t1
		inner join [HZV].[Vertraege] t4
			on t1.VertragsID=t4.VertragsID
			and t1.VertragsKV=t4.VertragsKV
			and t4.Dienstleistung='Teilnehmermanagement'
		inner join [HZV].[Quartale] t3
			on  concat ( Datepart(year,t1.TeilnahmeBeginn), datepart(quarter,t1.TeilnahmeBeginn)) <= t3.Quartal_kurz
			and concat ( Datepart(year,t1.TeilnahmeEnde), datepart(quarter,t1.TeilnahmeEnde)) >= t3.Quartal_kurz
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = T1.VertragsKV
		WHERE T3.Quartal_lang = @Quartal
		AND T4.HauptKassenIK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
	END
	ELSE BEGIN
		SELECT DISTINCT T1.VertragsKV,KV.KV_kurz,KV.KV_lang,KV.Kuerzel_kurz,KV.Kuerzel_lang
		FROM [HZV].[Teilnehmer_Aerzte] t1
		inner join [HZV].[Vertraege] t4
			on t1.VertragsID=t4.VertragsID
			and t1.VertragsKV=t4.VertragsKV
			and t4.Dienstleistung='Teilnehmermanagement'
		inner join [HZV].[Quartale] t3
			on  concat ( Datepart(year,t1.TeilnahmeBeginn), datepart(quarter,t1.TeilnahmeBeginn)) <= t3.Quartal_kurz
			and concat ( Datepart(year,t1.TeilnahmeEnde), datepart(quarter,t1.TeilnahmeEnde)) >= t3.Quartal_kurz
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = T1.VertragsKV
		WHERE T3.Quartal_lang = @Quartal
		AND T4.HauptKassenIK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
		AND T4.HauptKassenIK = @Kasse
	END

END
GO

-- =============================================
-- Author:		Jan Neubert
-- Create date: 2022-02-03
-- Description:	Dataset für verfügbare Quartale auf Basis der Ärztedaten
-- =============================================
CREATE  PROCEDURE [HZV].[SP_Dataset_Aerzte_Quartale] (@Kasse char(9))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		select 
			t3.Quartal_lang,
			t3.Quartal_Text_kurz,
			t3.Quartal_Text_lang		
		from [HZV].[Teilnehmer_Aerzte] t1
		inner join [HZV].[Vertraege] t4
			on t1.VertragsID=t4.VertragsID
			and t1.VertragsKV=t4.VertragsKV
			and t4.Dienstleistung='Teilnehmermanagement'
		inner join [HZV].[Quartale] t3
			on  concat ( Datepart(year,t1.TeilnahmeBeginn), datepart(quarter,t1.TeilnahmeBeginn)) <= t3.Quartal_kurz
			and concat ( Datepart(year,t1.TeilnahmeEnde), datepart(quarter,t1.TeilnahmeEnde)) >= t3.Quartal_kurz
		where t4.HauptKassenIK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
		group by 
		t3.Quartal_lang,
		t3.Quartal_Text_kurz,
		t3.Quartal_Text_lang
	END
	ELSE BEGIN
		select 
			q.Quartal_lang,
			q.Quartal_Text_kurz,
			q.Quartal_Text_lang
		from
			(
			select 
				t3.Quartal_lang,
				t3.Quartal_kurz,
				t3.Quartal_Text_kurz,
				t3.Quartal_Text_lang,
				t4.HauptKassenIK
			from [HZV].[Teilnehmer_Aerzte] t1
			inner join [HZV].[Vertraege] t4
				on t1.VertragsID=t4.VertragsID
				and t1.VertragsKV=t4.VertragsKV
				and t4.Dienstleistung='Teilnehmermanagement'
			inner join [HZV].[Quartale] t3
				on  concat ( Datepart(year,t1.TeilnahmeBeginn), datepart(quarter,t1.TeilnahmeBeginn)) <= t3.Quartal_kurz
				and concat ( Datepart(year,t1.TeilnahmeEnde), datepart(quarter,t1.TeilnahmeEnde)) >= t3.Quartal_kurz
			where t4.HauptKassenIK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
			and t4.HauptKassenIK = @Kasse
			group by 
			t3.Quartal_lang,
			t3.Quartal_kurz,
			t3.Quartal_Text_kurz,
			t3.Quartal_Text_lang,
			t4.HauptKassenIK
			) q
		join 
			(select
				HauptKassenIK,
				MIN(DienstleistungBeginn) as DLBeginn,
				case when MAX(DienstleistungEnde) is null then '99994' else MAX(DienstleistungEnde) end as DLEnde
			from [HZV].[Vertraege] 
			WHERE HauptKassenIK = @Kasse
			AND Dienstleistung = 'Teilnehmermanagement'
			GROUP BY HauptKassenIK
			) v
			on v.HauptKassenIK = q.HauptKassenIK
			and q.Quartal_kurz between v.DLBeginn and v.DLEnde
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-26
-- Description:	Dataset für Bereinigungsübersicht
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_Bereinigung] (@Kasse char(9), @Quartal char(6), @KV char(2))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		IF @KV = '00'
		BEGIN
			SELECT
				B.QUARTAL,
				B.VERTRAGS_KV,
				CONCAT(B.VERTRAGS_KV,' - ',KV.KV_lang) AS VertragsKV_Text,
				B.WOHNORT_KV,
				CONCAT(B.WOHNORT_KV,' - ',KVW.KV_lang) AS WohnortKV_Text,
				'' AS Vertrags_ID,
				'' AS HauptKassenIK,
				'' AS VKNR,
				SUM(B.Anzahl_Versicherte) AS Anzahl_Versicherte,
				SUM(B.Anzahl_Neueinschreiber) AS Anzahl_Neueinschreiber,
				SUM(B.Diff_kons_Punkte) AS Diff_kons_Punkte,
				SUM(B.Diff_kons_Euro) AS Diff_kons_Euro,
				SUM(B.Gesamt_fortentw_Punkte) AS Gesamt_fortentw_Punkte,
				SUM(B.Gesamt_fortentw_Euro) AS Gesamt_fortentw_Euro,
				SUM(B.Gesamt_Punkte) AS Gesamt_Punkte,
				SUM(B.Gesamt_Euro) AS Gesamt_Euro
			FROM [HZV].[Bereinigung] B
			LEFT JOIN [KONST].[KVRegionen] KV
				ON KV.KVId = B.VERTRAGS_KV
			LEFT JOIN [KONST].[KVRegionen] KVW
				ON KVW.KVId = B.WOHNORT_KV
			WHERE B.HauptKassenIK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
				AND B.QUARTAL = @Quartal
			GROUP BY B.QUARTAL,B.VERTRAGS_KV,B.WOHNORT_KV,KV.KV_lang,KVW.KV_lang
			ORDER BY B.VERTRAGS_KV,B.WOHNORT_KV
		END
		ELSE BEGIN
			SELECT
				B.QUARTAL,
				B.VERTRAGS_KV,
				CONCAT(B.VERTRAGS_KV,' - ',KV.KV_lang) AS VertragsKV_Text,
				B.WOHNORT_KV,
				CONCAT(B.WOHNORT_KV,' - ',KVW.KV_lang) AS WohnortKV_Text,
				'' AS Vertrags_ID,
				'' AS HauptKassenIK,
				'' AS VKNR,
				SUM(B.Anzahl_Versicherte) AS Anzahl_Versicherte,
				SUM(B.Anzahl_Neueinschreiber) AS Anzahl_Neueinschreiber,
				SUM(B.Diff_kons_Punkte) AS Diff_kons_Punkte,
				SUM(B.Diff_kons_Euro) AS Diff_kons_Euro,
				SUM(B.Gesamt_fortentw_Punkte) AS Gesamt_fortentw_Punkte,
				SUM(B.Gesamt_fortentw_Euro) AS Gesamt_fortentw_Euro,
				SUM(B.Gesamt_Punkte) AS Gesamt_Punkte,
				SUM(B.Gesamt_Euro) AS Gesamt_Euro
			FROM [HZV].[Bereinigung] B
			LEFT JOIN [KONST].[KVRegionen] KV
				ON KV.KVId = B.VERTRAGS_KV
			LEFT JOIN [KONST].[KVRegionen] KVW
				ON KVW.KVId = B.WOHNORT_KV
			WHERE B.HauptKassenIK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
				AND B.QUARTAL = @Quartal
				AND B.VERTRAGS_KV = @KV
			GROUP BY B.QUARTAL,B.VERTRAGS_KV,B.WOHNORT_KV,KV.KV_lang,KVW.KV_lang
			ORDER BY B.VERTRAGS_KV,B.WOHNORT_KV
		END
	END
	ELSE BEGIN
		IF @KV = '00'
		BEGIN
			SELECT
				B.QUARTAL,
				B.VERTRAGS_KV,
				CONCAT(B.VERTRAGS_KV,' - ',KV.KV_lang) AS VertragsKV_Text,
				B.WOHNORT_KV,
				CONCAT(B.WOHNORT_KV,' - ',KVW.KV_lang) AS WohnortKV_Text,
				B.VERTRAGS_ID,
				B.HauptKassenIK,
				B.VKNR,
				B.Anzahl_Versicherte,
				B.Anzahl_Neueinschreiber,
				B.Diff_kons_Punkte,
				B.Diff_kons_Euro,
				B.Gesamt_fortentw_Punkte,
				B.Gesamt_fortentw_Euro,
				B.Gesamt_Punkte,
				B.Gesamt_Euro
			FROM [HZV].[Bereinigung] B
			LEFT JOIN [KONST].[KVRegionen] KV
				ON KV.KVId = B.VERTRAGS_KV
			LEFT JOIN [KONST].[KVRegionen] KVW
				ON KVW.KVId = B.WOHNORT_KV
			WHERE B.HauptKassenIK = @Kasse
				AND B.QUARTAL = @Quartal
			ORDER BY B.VERTRAGS_KV,B.WOHNORT_KV
		END
		ELSE BEGIN
			SELECT
				B.QUARTAL,
				B.VERTRAGS_KV,
				CONCAT(B.VERTRAGS_KV,' - ',KV.KV_lang) AS VertragsKV_Text,
				B.WOHNORT_KV,
				CONCAT(B.WOHNORT_KV,' - ',KVW.KV_lang) AS WohnortKV_Text,
				B.VERTRAGS_ID,
				B.HauptKassenIK,
				B.VKNR,
				B.Anzahl_Versicherte,
				B.Anzahl_Neueinschreiber,
				B.Diff_kons_Punkte,
				B.Diff_kons_Euro,
				B.Gesamt_fortentw_Punkte,
				B.Gesamt_fortentw_Euro,
				B.Gesamt_Punkte,
				B.Gesamt_Euro
			FROM [HZV].[Bereinigung] B
			LEFT JOIN [KONST].[KVRegionen] KV
				ON KV.KVId = B.VERTRAGS_KV
			LEFT JOIN [KONST].[KVRegionen] KVW
				ON KVW.KVId = B.WOHNORT_KV
			WHERE B.HauptKassenIK = @Kasse
				AND B.QUARTAL = @Quartal
				AND B.VERTRAGS_KV = @KV
			ORDER BY B.VERTRAGS_KV,B.WOHNORT_KV
		END
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-26
-- Description:	Dataset für verfügbare KV-Regionen auf Basis der Bereinigungsdaten
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_Bereinigung_KVRegionen] (@Kasse char(9), @Quartal char(6))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT '00' AS Vertrags_KV,'alle' AS KV_kurz,'alle KV-Regionen' AS KV_lang,'' AS Kuerzel_kurz,'' AS Kuerzel_lang

		UNION

		SELECT DISTINCT B.VERTRAGS_KV,KV.KV_kurz,KV.KV_lang,KV.Kuerzel_kurz,KV.Kuerzel_lang
		FROM [HZV].[Bereinigung] B
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = B.VERTRAGS_KV
		WHERE B.QUARTAL = @Quartal
		AND B.HauptKassenIK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
	END
	ELSE BEGIN
		SELECT '00' AS Vertrags_KV,'alle' AS KV_kurz,'alle KV-Regionen' AS KV_lang,'' AS Kuerzel_kurz,'' AS Kuerzel_lang

		UNION

		SELECT DISTINCT B.VERTRAGS_KV,KV.KV_kurz,KV.KV_lang,KV.Kuerzel_kurz,KV.Kuerzel_lang
		FROM [HZV].[Bereinigung] B
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = B.VERTRAGS_KV
		WHERE B.QUARTAL = @Quartal
		AND B.HauptKassenIK = @Kasse
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-27
-- Description:	Dataset für verfügbare Quartale auf Basis der Bereinigungsdaten
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_Bereinigung_Quartale] (@Kasse char(9))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT DISTINCT B.QUARTAL,Q.Quartal_Text_kurz,Q.Quartal_Text_lang
		FROM [HZV].[Bereinigung] B
		JOIN [HZV].[Quartale] Q
			ON Q.Quartal_kurz = B.QUARTAL
		WHERE B.HauptKassenIK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
	END
	ELSE BEGIN
		SELECT DISTINCT B.QUARTAL,Q.Quartal_Text_kurz,Q.Quartal_Text_lang
		FROM [HZV].[Bereinigung] B
		JOIN [HZV].[Quartale] Q
			ON Q.Quartal_kurz = B.QUARTAL
		WHERE B.HauptKassenIK = @Kasse
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-26
-- Description:	Dataset für Entwicklung der durchschn. Kosten
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_DurchschnittKosten_Entwicklung] (@Kasse char(9), @Quartal char(6))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT 
			K.Quartal_kurz,
			K.Quartal_lang,
			Q.Quartal_Text_kurz,
			Q.Quartal_Text_lang,
			K.VertragsKV,
			KV.KV_lang,
			KV.Kuerzel_kurz,
			KV.Kuerzel_lang,
			(SUM(K.BtrABR - K.BtrBER + K.BtrNVI))/SUM(AnzTNM) AS DurchschnittKosten
		FROM [HZV].[Kosten] K
		JOIN [HZV].[Quartale] Q
			ON Q.Quartal_kurz = K.Quartal_kurz
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = K.VertragsKV
		WHERE K.Quartal_kurz <= @Quartal
		AND K.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
		GROUP BY K.Quartal_kurz,K.Quartal_lang,Q.Quartal_Text_kurz,Q.Quartal_Text_lang,K.VertragsKV,KV.KV_lang,KV.Kuerzel_kurz,KV.Kuerzel_lang
	END
	ELSE BEGIN
		SELECT 
			K.Quartal_kurz,
			K.Quartal_lang,
			Q.Quartal_Text_kurz,
			Q.Quartal_Text_lang,
			K.VertragsKV,
			KV.KV_lang,
			KV.Kuerzel_kurz,
			KV.Kuerzel_lang,
			(SUM(K.BtrABR - K.BtrBER + K.BtrNVI))/SUM(AnzTNM) AS DurchschnittKosten
		FROM [HZV].[Kosten] K
		JOIN [HZV].[Quartale] Q
			ON Q.Quartal_kurz = K.Quartal_kurz
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = K.VertragsKV
		WHERE K.Quartal_kurz <= @Quartal
		AND K.H2IK = @Kasse
		GROUP BY K.Quartal_kurz,K.Quartal_lang,Q.Quartal_Text_kurz,Q.Quartal_Text_lang,K.VertragsKV,KV.KV_lang,KV.Kuerzel_kurz,KV.Kuerzel_lang
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-26
-- Description:	Dataset für verfügbare Quartale auf Basis der Kostendaten
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_DurchschnittKosten_Quartale] (@Kasse char(9))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT DISTINCT K.Quartal_kurz,K.Quartal_lang,Q.Quartal_Text_kurz,Q.Quartal_Text_lang
		FROM [HZV].[Kosten] K
		JOIN [HZV].[Quartale] Q
			ON Q.Quartal_lang = K.Quartal_lang
		WHERE H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
	END
	ELSE BEGIN
		SELECT DISTINCT K.Quartal_kurz,K.Quartal_lang,Q.Quartal_Text_kurz,Q.Quartal_Text_lang
		FROM [HZV].[Kosten] K
		JOIN [HZV].[Quartale] Q
			ON Q.Quartal_lang = K.Quartal_lang
		WHERE H2IK = @Kasse
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-26
-- Description:	Dataset für Durchschnittliche Kosten je KV-Region
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_DurchschnittKosten_StandKV] (@Kasse char(9), @Quartal char(5))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT
			K.VertragsKV,
			KV.Kuerzel_lang,
			KV.KV_lang,
			SUM(K.AnzTNM) AS AnzTNM,
			SUM(K.BtrABR) AS BtrABR,
			SUM(K.BtrBER) AS BtrBER,
			SUM(K.BtrNVI) AS BtrNVI,
			SUM(K.BtrABR)/SUM(K.AnzTNM) AS DurchschnittABR,
			SUM(K.BtrBER)/SUM(K.AnzTNM) AS DurchschnittBER,
			SUM(K.BtrNVI)/SUM(K.AnzTNM) AS DurchschnittNVI,
			SUM(K.BtrABR - K.BtrBER + K.BtrNVI)/SUM(K.AnzTNM) AS DurchschnittKosten
		FROM [HZV].[Kosten] K
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = K.VertragsKV
		WHERE K.Quartal_kurz = @Quartal
		AND K.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
		GROUP BY K.VertragsKV,KV.Kuerzel_lang,KV.KV_lang
	END
	ELSE BEGIN
		SELECT
			K.VertragsKV,
			KV.Kuerzel_lang,
			KV.KV_lang,
			SUM(K.AnzTNM) AS AnzTNM,
			SUM(K.BtrABR) AS BtrABR,
			SUM(K.BtrBER) AS BtrBER,
			SUM(K.BtrNVI) AS BtrNVI,
			SUM(K.BtrABR)/SUM(K.AnzTNM) AS DurchschnittABR,
			SUM(K.BtrBER)/SUM(K.AnzTNM) AS DurchschnittBER,
			SUM(K.BtrNVI)/SUM(K.AnzTNM) AS DurchschnittNVI,
			SUM(K.BtrABR - K.BtrBER + K.BtrNVI)/SUM(K.AnzTNM) AS DurchschnittKosten
		FROM [HZV].[Kosten] K
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = K.VertragsKV
		WHERE K.Quartal_kurz = @Quartal
		AND K.H2IK = @Kasse
		GROUP BY K.VertragsKV,KV.Kuerzel_lang,KV.KV_lang
	END

END
GO

-- ===========================================================
-- Author:		Antje Buksch
-- Create date: 2022-02-04
-- Description:	Dataset für Anzeige der vorhandenen Kassen auf Basis des angemeldeten Users
-- ===========================================================
CREATE PROCEDURE [HZV].[SP_Dataset_Kassen](@User varchar(100))
AS
BEGIN

	--SET @User = 'spectrumk\antje.ockert'
	--SET @User = 'max.mustermann@bkk-vbu.de'
	--SET @User = 'maxi.mustermann@pronovabkk.de'


	DECLARE @AtPos int = CHARINDEX('@',@User,0)
	DECLARE @RestLaenge int = LEN(@User) - @AtPos
	DECLARE @Suffix varchar(50) = LOWER(RIGHT(@User,@RestLaenge))
	

	IF(CHARINDEX('spectrum',@Suffix) = 0)
	BEGIN	
		SELECT 
			K.Id,
			K.HauptKassenIK,
			P.KasseName
		FROM
			(
			SELECT
				RANK() OVER (ORDER BY K.KasseName) AS Id, 
				K.*
			FROM
				(
				SELECT DISTINCT
					V.HauptKassenIK,
					TRIM(V.KasseName) AS KasseName
				FROM [HZV].[Vertraege] V
				WHERE V.DienstleistungEnde >= (SELECT MIN(Quartal_kurz) FROM [HZV].[Quartale]) OR V.DienstleistungEnde IS NULL
				) K
			) K
		JOIN [AbrBV_Reporting_DEV].[HZV].[Portaluser] P 
			ON P.KassenIK = K.HauptKassenIK
		WHERE P.Email = @User
	END

	IF(CHARINDEX('spectrum',@Suffix) > 0)
	BEGIN
		SELECT        0 AS Id, '000000000' AS HauptKassenIK, 'alle Kassen' AS KasseName
		UNION
		SELECT
			RANK() OVER (ORDER BY K.KasseName) AS Id, 
			K.*
		FROM
			(
			SELECT DISTINCT
				V.HauptKassenIK,
				TRIM(V.KasseName) AS KasseName
			FROM [HZV].[Vertraege] V
			WHERE V.DienstleistungEnde >= (SELECT MIN(Quartal_kurz) FROM [HZV].[Quartale]) OR V.DienstleistungEnde IS NULL
			) K
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-02-04
-- Description:	Dataset für verfügbare KV-Regionen auf Basis der NVI-Daten
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_NVI_KVRegionen] (@Kasse char(9), @Quartal char(6))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT DISTINCT N.VertragsKV,KV.KV_kurz,KV.KV_lang,KV.Kuerzel_kurz,KV.Kuerzel_lang
		FROM [HZV].[NVI] N
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = N.VertragsKV
		WHERE N.Quartal = @Quartal
		AND N.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
	END
	ELSE BEGIN
		SELECT DISTINCT N.VertragsKV,KV.KV_kurz,KV.KV_lang,KV.Kuerzel_kurz,KV.Kuerzel_lang
		FROM [HZV].[NVI] N
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = N.VertragsKV
		WHERE N.H2IK = @Kasse
		AND N.Quartal = @Quartal
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-02-04
-- Description:	Dataset für verfügbare Quartale auf Basis der NVI-Daten
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_NVI_Quartale] (@Kasse char(9))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT DISTINCT N.Quartal,Q.Quartal_Text_kurz,Q.Quartal_Text_lang
		FROM [HZV].[NVI] N
		JOIN [HZV].[Quartale] Q
			ON Q.Quartal_kurz = N.Quartal
		WHERE H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
	END
	ELSE BEGIN
		SELECT DISTINCT N.Quartal,Q.Quartal_Text_kurz,Q.Quartal_Text_lang
		FROM [HZV].[NVI] N
		JOIN [HZV].[Quartale] Q
			ON Q.Quartal_kurz = N.Quartal
		WHERE H2IK = @Kasse
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-20
-- Description:	Dataset für Teilnehmer-Alterspyramide
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_Teilnehmer_Altersgruppen] (@Kasse char(9), @Quartal char(6), @KV char(2))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT 
			T.Quartal,
			T.VertragsKV,
			T.Geschlecht,
			T.Altersgruppe,
			AG.AG_Id,
			AG.AG_lang,
			COUNT(DISTINCT T.sVP) * CASE WHEN T.Geschlecht = 'm' THEN (-1) ELSE 1 END AS Anzahl
		FROM [HZV].[Teilnehmer_Versicherte] T
		JOIN [KONST].[Altersgruppen] AG
			ON AG.AG_kurz = T.Altersgruppe
		WHERE T.Quartal = @Quartal
			AND T.Teilnahme_Ende IS NULL
			AND T.VertragsKV = @KV
			AND T.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
		GROUP BY T.Quartal,T.VertragsKV,T.Geschlecht,T.Altersgruppe,AG.AG_Id,AG.AG_lang
	END
	ELSE BEGIN
		SELECT 
			T.Quartal,
			T.VertragsKV,
			T.Geschlecht,
			T.Altersgruppe,
			AG.AG_Id,
			AG.AG_lang,
			COUNT(DISTINCT T.sVP) * CASE WHEN T.Geschlecht = 'm' THEN (-1) ELSE 1 END AS Anzahl
		FROM [HZV].[Teilnehmer_Versicherte] T
		JOIN [KONST].[Altersgruppen] AG
			ON AG.AG_kurz = T.Altersgruppe
		WHERE T.Quartal = @Quartal
			AND T.Teilnahme_Ende IS NULL
			AND T.H2IK = @Kasse
			AND T.VertragsKV = @KV
		GROUP BY T.Quartal,T.VertragsKV,T.Geschlecht,T.Altersgruppe,AG.AG_Id,AG.AG_lang
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-20
-- Description:	Dataset für Teilnehmer-Entwicklung
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_Teilnehmer_Entwicklung] (@Kasse char(9), @Quartal char(6), @KV char(2))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT 
			T.VertragsKV,
			T.Quartal,
			N.Quartal_Text_kurz,
			COUNT(DISTINCT T.SVP) AS AnzTNM,
			CASE WHEN N.AnzNeu IS NULL THEN 0 ELSE N.AnzNeu END AS AnzNeu
		FROM [HZV].[Teilnehmer_Versicherte] T
		LEFT JOIN
			(
			SELECT
				VertragsKV,
				Quartal,
				Quartal_Text_kurz,
				SUM(T.AnzNeu) AS AnzNeu
			FROM
				(
				SELECT
					T.VertragsKV,
					T.Quartal,
					Q.Quartal_Text_kurz,
					T.H2IK,
					COUNT(DISTINCT T.SVP) AS AnzNeu
				FROM [HZV].[Teilnehmer_Versicherte] T
				JOIN [HZV].[Quartale] Q
					ON Q.Quartal_lang = T.Quartal
				WHERE T.Quartal <= @Quartal
					AND T.Teilnahme_Beginn = Q.Quartal_Beginn
					AND T.Teilnahme_Ende IS NULL
					AND T.VertragsKV = @KV
					AND T.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
				GROUP BY T.VertragsKV,T.Quartal,T.H2IK,Q.Quartal_Text_kurz
				) T
			GROUP BY VertragsKV,Quartal,Quartal_Text_kurz
			) N
			ON N.VertragsKV = T.VertragsKV
			AND N.Quartal = T.Quartal
		WHERE T.Quartal <= @Quartal
			AND T.Teilnahme_Ende IS NULL
			AND T.VertragsKV = @KV
			AND T.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
		GROUP BY T.VertragsKV,T.Quartal,N.AnzNeu,N.Quartal_Text_kurz
		ORDER BY T.VertragsKV,T.Quartal
	END
	ELSE BEGIN
		SELECT 
			T.VertragsKV,
			T.Quartal,
			N.Quartal_Text_kurz,
			COUNT(DISTINCT T.SVP) AS AnzTNM,
			CASE WHEN N.AnzNeu IS NULL THEN 0 ELSE N.AnzNeu END AS AnzNeu
		FROM [HZV].[Teilnehmer_Versicherte] T
		LEFT JOIN
			(
			SELECT
				VertragsKV,
				Quartal,
				Quartal_Text_kurz,
				SUM(T.AnzNeu) AS AnzNeu
			FROM
				(
				SELECT
					T.VertragsKV,
					T.Quartal,
					Q.Quartal_Text_kurz,
					T.H2IK,
					COUNT(DISTINCT T.SVP) AS AnzNeu
				FROM [HZV].[Teilnehmer_Versicherte] T
				JOIN [HZV].[Quartale] Q
					ON Q.Quartal_lang = T.Quartal
				WHERE T.Quartal <= @Quartal
					AND T.Teilnahme_Beginn = Q.Quartal_Beginn
					AND T.Teilnahme_Ende IS NULL
					AND T.H2IK = @Kasse
					AND T.VertragsKV = @KV
				GROUP BY T.VertragsKV,T.Quartal,T.H2IK,Q.Quartal_Text_kurz
				) T
			GROUP BY VertragsKV,Quartal,Quartal_Text_kurz
			) N
			ON N.VertragsKV = T.VertragsKV
			AND N.Quartal = T.Quartal
		WHERE T.Quartal <= @Quartal
			AND T.Teilnahme_Ende IS NULL
			AND T.H2IK = @Kasse
			AND T.VertragsKV = @KV
		GROUP BY T.VertragsKV,T.Quartal,N.AnzNeu,N.Quartal_Text_kurz
		ORDER BY T.VertragsKV,T.Quartal
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-25
-- Description:	Dataset für verfügbare KV-Regionen auf Basis der Teilnehmerdaten
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_Teilnehmer_KVRegionen] (@Kasse char(9), @Quartal char(6))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT DISTINCT T.VertragsKV,KV.KV_kurz,KV.KV_lang,KV.Kuerzel_kurz,KV.Kuerzel_lang
		FROM [HZV].[Teilnehmer_Versicherte] T
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = T.VertragsKV
		WHERE T.Quartal = @Quartal
		AND T.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
	END
	ELSE BEGIN
		SELECT DISTINCT T.VertragsKV,KV.KV_kurz,KV.KV_lang,KV.Kuerzel_kurz,KV.Kuerzel_lang
		FROM [HZV].[Teilnehmer_Versicherte] T
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = T.VertragsKV
		WHERE T.H2IK = @Kasse
		AND T.Quartal = @Quartal
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-25
-- Description:	Dataset für verfügbare Quartale auf Basis der Teilnehmerdaten
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_Teilnehmer_Quartale] (@Kasse char(9))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT DISTINCT T.Quartal,Q.Quartal_Text_kurz,Q.Quartal_Text_lang
		FROM [HZV].[Teilnehmer_Versicherte] T
		JOIN [HZV].[Quartale] Q
			ON Q.Quartal_lang = T.Quartal
		WHERE H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
	END
	ELSE BEGIN
		SELECT DISTINCT T.Quartal,Q.Quartal_Text_kurz,Q.Quartal_Text_lang
		FROM [HZV].[Teilnehmer_Versicherte] T
		JOIN [HZV].[Quartale] Q
			ON Q.Quartal_lang = T.Quartal
		WHERE H2IK = @Kasse
	END

END
GO

-- =============================================
-- Author:		Jan Neubert
-- Create date: 2022-02-02
-- Description:	Dataset für Top NVI Ärzte
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_TOP_NVI_AI] (@Kasse char(9), @Quartal char(5), @KV char(2), @TOP int)
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		IF @KV = '00'
		BEGIN
			/*** TOP Arzt-NVI ***/
			--aktuelles Quartal
			SELECT TOP (@TOP)
				NVI.Quartal,
				NVI.H2IK,
				NVI.Betreu_LANR7,
				SUM(NVI.MENGE * NVI.BETRAG) AS NVI,
				COUNT(DISTINCT NVI.SVP) AS AnzVers,
				RANK() OVER (ORDER BY SUM(NVI.MENGE * NVI.BETRAG) DESC) AS Rang_Quartal,
				NVI_1.RANG AS Rang_Quartal_L1,
				NVI_2.RANG AS Rang_Quartal_L2,
				NVI_3.RANG AS Rang_Quartal_L3
			FROM [HZV].[NVI] NVI
			LEFT JOIN
				--1 Quartal davor
				(
				SELECT --TOP (@TOP)
					Quartal,
					H2IK,
					Betreu_LANR7,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT SVP) AS AnzVers,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'AI'
					AND SMA IN ('0','N')
			--		AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4),1)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4),2)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),3)
									END 
			--		AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,Betreu_LANR7
				) NVI_1
				ON NVI_1.H2IK = NVI.H2IK
				AND NVI_1.Betreu_LANR7 = NVI.Betreu_LANR7
			LEFT JOIN
				--2 Quartale davor
				(
				SELECT --TOP (@TOP)
					Quartal,
					H2IK,
					Betreu_LANR7,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT SVP) AS AnzVers,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'AI'
					AND SMA IN ('0','N')
			--		AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,3)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4),1)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),2)
									END  
			--		AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,Betreu_LANR7
				) NVI_2
				ON NVI_2.H2IK = NVI.H2IK
				AND NVI_2.Betreu_LANR7 = NVI.Betreu_LANR7
			LEFT JOIN
				--2 Quartale davor
				(
				SELECT --TOP (@TOP)
					Quartal,
					H2IK,
					Betreu_LANR7,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT SVP) AS AnzVers,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'AI'
					AND SMA IN ('0','N')
			--		AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,2)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4) - 1,3)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),1)
									END
			--		AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,Betreu_LANR7
				) NVI_3
				ON NVI_3.H2IK = NVI.H2IK
				AND NVI_3.Betreu_LANR7 = NVI.Betreu_LANR7
			WHERE NVI.NVI_KNZ = 'AI'
				AND NVI.SMA IN ('0','N')
			--	AND NVI.H2IK = @Kasse
				AND NVI.Quartal = @Quartal
			--	AND NVI.VertragsKV = @KV
			GROUP BY NVI.Quartal,NVI.H2IK,NVI.Betreu_LANR7,NVI_1.RANG,NVI_2.RANG,NVI_3.RANG
			ORDER BY SUM(NVI.MENGE * NVI.BETRAG) DESC
		END
		ELSE BEGIN
			/*** TOP Arzt-NVI ***/
			--aktuelles Quartal
			SELECT TOP (@TOP)
				NVI.Quartal,
				NVI.H2IK,
				NVI.Betreu_LANR7,
				SUM(NVI.MENGE * NVI.BETRAG) AS NVI,
				COUNT(DISTINCT NVI.SVP) AS AnzVers,
				RANK() OVER (ORDER BY SUM(NVI.MENGE * NVI.BETRAG) DESC) AS Rang_Quartal,
				NVI_1.RANG AS Rang_Quartal_L1,
				NVI_2.RANG AS Rang_Quartal_L2,
				NVI_3.RANG AS Rang_Quartal_L3
			FROM [HZV].[NVI] NVI
			LEFT JOIN
				--1 Quartal davor
				(
				SELECT --TOP (@TOP)
					Quartal,
					H2IK,
					Betreu_LANR7,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT SVP) AS AnzVers,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'AI'
					AND SMA IN ('0','N')
			--		AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4),1)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4),2)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),3)
									END 
					AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,Betreu_LANR7
				) NVI_1
				ON NVI_1.H2IK = NVI.H2IK
				AND NVI_1.Betreu_LANR7 = NVI.Betreu_LANR7
			LEFT JOIN
				--2 Quartale davor
				(
				SELECT --TOP (@TOP)
					Quartal,
					H2IK,
					Betreu_LANR7,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT SVP) AS AnzVers,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'AI'
					AND SMA IN ('0','N')
			--		AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,3)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4),1)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),2)
									END  
					AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,Betreu_LANR7
				) NVI_2
				ON NVI_2.H2IK = NVI.H2IK
				AND NVI_2.Betreu_LANR7 = NVI.Betreu_LANR7
			LEFT JOIN
				--2 Quartale davor
				(
				SELECT --TOP (@TOP)
					Quartal,
					H2IK,
					Betreu_LANR7,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT SVP) AS AnzVers,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'AI'
					AND SMA IN ('0','N')
			--		AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,2)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4) - 1,3)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),1)
									END
					AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,Betreu_LANR7
				) NVI_3
				ON NVI_3.H2IK = NVI.H2IK
				AND NVI_3.Betreu_LANR7 = NVI.Betreu_LANR7
			WHERE NVI.NVI_KNZ = 'AI'
				AND NVI.SMA IN ('0','N')
			--	AND NVI.H2IK = @Kasse
				AND NVI.Quartal = @Quartal
				AND NVI.VertragsKV = @KV
			GROUP BY NVI.Quartal,NVI.H2IK,NVI.Betreu_LANR7,NVI_1.RANG,NVI_2.RANG,NVI_3.RANG
			ORDER BY SUM(NVI.MENGE * NVI.BETRAG) DESC
		END
	END
	ELSE BEGIN
		IF @KV = '00'
		BEGIN
			/*** TOP Arzt-NVI ***/
			--aktuelles Quartal
			SELECT TOP (@TOP)
				NVI.Quartal,
				NVI.H2IK,
				NVI.Betreu_LANR7,
				SUM(NVI.MENGE * NVI.BETRAG) AS NVI,
				COUNT(DISTINCT NVI.SVP) AS AnzVers,
				RANK() OVER (ORDER BY SUM(NVI.MENGE * NVI.BETRAG) DESC) AS Rang_Quartal,
				NVI_1.RANG AS Rang_Quartal_L1,
				NVI_2.RANG AS Rang_Quartal_L2,
				NVI_3.RANG AS Rang_Quartal_L3
			FROM [HZV].[NVI] NVI
			LEFT JOIN
				--1 Quartal davor
				(
				SELECT --TOP (@TOP)
					Quartal,
					H2IK,
					Betreu_LANR7,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT SVP) AS AnzVers,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'AI'
					AND SMA IN ('0','N')
					AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4),1)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4),2)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),3)
									END 
			--		AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,Betreu_LANR7
				) NVI_1
				ON NVI_1.H2IK = NVI.H2IK
				AND NVI_1.Betreu_LANR7 = NVI.Betreu_LANR7
			LEFT JOIN
				--2 Quartale davor
				(
				SELECT --TOP (@TOP)
					Quartal,
					H2IK,
					Betreu_LANR7,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT SVP) AS AnzVers,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'AI'
					AND SMA IN ('0','N')
					AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,3)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4),1)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),2)
									END  
			--		AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,Betreu_LANR7
				) NVI_2
				ON NVI_2.H2IK = NVI.H2IK
				AND NVI_2.Betreu_LANR7 = NVI.Betreu_LANR7
			LEFT JOIN
				--2 Quartale davor
				(
				SELECT --TOP (@TOP)
					Quartal,
					H2IK,
					Betreu_LANR7,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT SVP) AS AnzVers,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'AI'
					AND SMA IN ('0','N')
					AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,2)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4) - 1,3)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),1)
									END
			--		AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,Betreu_LANR7
				) NVI_3
				ON NVI_3.H2IK = NVI.H2IK
				AND NVI_3.Betreu_LANR7 = NVI.Betreu_LANR7
			WHERE NVI.NVI_KNZ = 'AI'
				AND NVI.SMA IN ('0','N')
				AND NVI.H2IK = @Kasse
				AND NVI.Quartal = @Quartal
			--	AND NVI.VertragsKV = @KV
			GROUP BY NVI.Quartal,NVI.H2IK,NVI.Betreu_LANR7,NVI_1.RANG,NVI_2.RANG,NVI_3.RANG
			ORDER BY SUM(NVI.MENGE * NVI.BETRAG) DESC
		END
		ELSE BEGIN
			/*** TOP Arzt-NVI ***/
			--aktuelles Quartal
			SELECT TOP (@TOP)
				NVI.Quartal,
				NVI.H2IK,
				NVI.Betreu_LANR7,
				SUM(NVI.MENGE * NVI.BETRAG) AS NVI,
				COUNT(DISTINCT NVI.SVP) AS AnzVers,
				RANK() OVER (ORDER BY SUM(NVI.MENGE * NVI.BETRAG) DESC) AS Rang_Quartal,
				NVI_1.RANG AS Rang_Quartal_L1,
				NVI_2.RANG AS Rang_Quartal_L2,
				NVI_3.RANG AS Rang_Quartal_L3
			FROM [HZV].[NVI] NVI
			LEFT JOIN
				--1 Quartal davor
				(
				SELECT --TOP (@TOP)
					Quartal,
					H2IK,
					Betreu_LANR7,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT SVP) AS AnzVers,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'AI'
					AND SMA IN ('0','N')
					AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4),1)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4),2)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),3)
									END 
					AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,Betreu_LANR7
				) NVI_1
				ON NVI_1.H2IK = NVI.H2IK
				AND NVI_1.Betreu_LANR7 = NVI.Betreu_LANR7
			LEFT JOIN
				--2 Quartale davor
				(
				SELECT --TOP (@TOP)
					Quartal,
					H2IK,
					Betreu_LANR7,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT SVP) AS AnzVers,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'AI'
					AND SMA IN ('0','N')
					AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,3)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4),1)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),2)
									END  
					AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,Betreu_LANR7
				) NVI_2
				ON NVI_2.H2IK = NVI.H2IK
				AND NVI_2.Betreu_LANR7 = NVI.Betreu_LANR7
			LEFT JOIN
				--2 Quartale davor
				(
				SELECT --TOP (@TOP)
					Quartal,
					H2IK,
					Betreu_LANR7,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT SVP) AS AnzVers,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'AI'
					AND SMA IN ('0','N')
					AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,2)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4) - 1,3)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),1)
									END
					AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,Betreu_LANR7
				) NVI_3
				ON NVI_3.H2IK = NVI.H2IK
				AND NVI_3.Betreu_LANR7 = NVI.Betreu_LANR7
			WHERE NVI.NVI_KNZ = 'AI'
				AND NVI.SMA IN ('0','N')
				AND NVI.H2IK = @Kasse
				AND NVI.Quartal = @Quartal
				AND NVI.VertragsKV = @KV
			GROUP BY NVI.Quartal,NVI.H2IK,NVI.Betreu_LANR7,NVI_1.RANG,NVI_2.RANG,NVI_3.RANG
			ORDER BY SUM(NVI.MENGE * NVI.BETRAG) DESC
		END
	END

END
GO

-- =============================================
-- Author:		Jan Neubert
-- Create date: 2022-02-02
-- Description:	Dataset für Top NVI Versicherte
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_TOP_NVI_VI] (@Kasse char(9), @Quartal char(5), @KV char(2), @TOP int)
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		IF @KV = '00'
		BEGIN
			/*** TOP Versicherten-NVI ***/
			--aktuelles Quartal
			SELECT TOP (@TOP)
				NVI.Quartal,
				NVI.H2IK,
				NVI.SVP,
				SUM(NVI.MENGE * NVI.BETRAG) AS NVI,
				COUNT(DISTINCT NVI.Abrechner_LANR7) AS AnzArzt,
				RANK() OVER (ORDER BY SUM(NVI.MENGE * NVI.BETRAG) DESC) AS Rang_Quartal,
				NVI_1.RANG AS Rang_Quartal_L1,
				NVI_2.RANG AS Rang_Quartal_L2,
				NVI_3.RANG AS Rang_Quartal_L3
			FROM [HZV].[NVI] NVI
			LEFT JOIN
				--1 Quartal davor
				(
				SELECT TOP (@TOP)	
					Quartal,
					H2IK,
					SVP,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT Abrechner_LANR7) AS AnzArzt,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'VI'
					AND SMA IN ('0','N')
			--		AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4),1)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4),2)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),3)
									END 
			--		AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,SVP
				) NVI_1
				ON NVI_1.H2IK = NVI.H2IK
				AND NVI_1.SVP = NVI.SVP
			LEFT JOIN
				--2 Quartale davor
				(
				SELECT TOP (@TOP)
					Quartal,
					H2IK,
					SVP,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT Abrechner_LANR7) AS AnzArzt,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'VI'
					AND SMA IN ('0','N')
			--		AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,3)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4),1)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),2)
									END 
			--		AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,SVP
				) NVI_2
				ON NVI_2.H2IK = NVI.H2IK
				AND NVI_2.SVP = NVI.SVP
			LEFT JOIN
				--3 Quartale davor
				(
				SELECT TOP (@TOP)
					Quartal,
					H2IK,
					SVP,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT Abrechner_LANR7) AS AnzArzt,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'VI'
					AND SMA IN ('0','N')
			--		AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,2)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4) - 1,3)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),1)
									END 
			--		AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,SVP
				) NVI_3
				ON NVI_3.H2IK = NVI.H2IK
				AND NVI_3.SVP = NVI.SVP
			WHERE NVI.NVI_KNZ = 'VI'
				AND NVI.SMA IN ('0','N')
			--	AND NVI.H2IK = @Kasse
				AND NVI.Quartal = @Quartal
			--	AND NVI.VertragsKV = @KV
			GROUP BY NVI.Quartal,NVI.H2IK,NVI.SVP,NVI_1.RANG,NVI_2.RANG,NVI_3.RANG
			ORDER BY SUM(NVI.MENGE * NVI.BETRAG) DESC
		END
		ELSE BEGIN
			/*** TOP Versicherten-NVI ***/
			--aktuelles Quartal
			SELECT TOP (@TOP)
				NVI.Quartal,
				NVI.H2IK,
				NVI.SVP,
				SUM(NVI.MENGE * NVI.BETRAG) AS NVI,
				COUNT(DISTINCT NVI.Abrechner_LANR7) AS AnzArzt,
				RANK() OVER (ORDER BY SUM(NVI.MENGE * NVI.BETRAG) DESC) AS Rang_Quartal,
				NVI_1.RANG AS Rang_Quartal_L1,
				NVI_2.RANG AS Rang_Quartal_L2,
				NVI_3.RANG AS Rang_Quartal_L3
			FROM [HZV].[NVI] NVI
			LEFT JOIN
				--1 Quartal davor
				(
				SELECT TOP (@TOP)	
					Quartal,
					H2IK,
					SVP,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT Abrechner_LANR7) AS AnzArzt,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'VI'
					AND SMA IN ('0','N')
			--		AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4),1)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4),2)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),3)
									END 
					AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,SVP
				) NVI_1
				ON NVI_1.H2IK = NVI.H2IK
				AND NVI_1.SVP = NVI.SVP
			LEFT JOIN
				--2 Quartale davor
				(
				SELECT TOP (@TOP)
					Quartal,
					H2IK,
					SVP,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT Abrechner_LANR7) AS AnzArzt,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'VI'
					AND SMA IN ('0','N')
			--		AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,3)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4),1)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),2)
									END 
					AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,SVP
				) NVI_2
				ON NVI_2.H2IK = NVI.H2IK
				AND NVI_2.SVP = NVI.SVP
			LEFT JOIN
				--3 Quartale davor
				(
				SELECT TOP (@TOP)
					Quartal,
					H2IK,
					SVP,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT Abrechner_LANR7) AS AnzArzt,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'VI'
					AND SMA IN ('0','N')
			--		AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,2)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4) - 1,3)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),1)
									END 
					AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,SVP
				) NVI_3
				ON NVI_3.H2IK = NVI.H2IK
				AND NVI_3.SVP = NVI.SVP
			WHERE NVI.NVI_KNZ = 'VI'
				AND NVI.SMA IN ('0','N')
			--	AND NVI.H2IK = @Kasse
				AND NVI.Quartal = @Quartal
				AND NVI.VertragsKV = @KV
			GROUP BY NVI.Quartal,NVI.H2IK,NVI.SVP,NVI_1.RANG,NVI_2.RANG,NVI_3.RANG
			ORDER BY SUM(NVI.MENGE * NVI.BETRAG) DESC
		END
	END
	ELSE BEGIN
		IF @KV = '00'
		BEGIN	
			/*** TOP Versicherten-NVI ***/
			--aktuelles Quartal
			SELECT TOP (@TOP)
				NVI.Quartal,
				NVI.H2IK,
				NVI.SVP,
				SUM(NVI.MENGE * NVI.BETRAG) AS NVI,
				COUNT(DISTINCT NVI.Abrechner_LANR7) AS AnzArzt,
				RANK() OVER (ORDER BY SUM(NVI.MENGE * NVI.BETRAG) DESC) AS Rang_Quartal,
				NVI_1.RANG AS Rang_Quartal_L1,
				NVI_2.RANG AS Rang_Quartal_L2,
				NVI_3.RANG AS Rang_Quartal_L3
			FROM [HZV].[NVI] NVI
			LEFT JOIN
				--1 Quartal davor
				(
				SELECT TOP (@TOP)	
					Quartal,
					H2IK,
					SVP,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT Abrechner_LANR7) AS AnzArzt,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'VI'
					AND SMA IN ('0','N')
					AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4),1)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4),2)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),3)
									END 
			--		AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,SVP
				) NVI_1
				ON NVI_1.H2IK = NVI.H2IK
				AND NVI_1.SVP = NVI.SVP
			LEFT JOIN
				--2 Quartale davor
				(
				SELECT TOP (@TOP)
					Quartal,
					H2IK,
					SVP,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT Abrechner_LANR7) AS AnzArzt,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'VI'
					AND SMA IN ('0','N')
					AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,3)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4),1)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),2)
									END 
			--		AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,SVP
				) NVI_2
				ON NVI_2.H2IK = NVI.H2IK
				AND NVI_2.SVP = NVI.SVP
			LEFT JOIN
				--3 Quartale davor
				(
				SELECT TOP (@TOP)
					Quartal,
					H2IK,
					SVP,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT Abrechner_LANR7) AS AnzArzt,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'VI'
					AND SMA IN ('0','N')
					AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,2)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4) - 1,3)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),1)
									END 
			--		AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,SVP
				) NVI_3
				ON NVI_3.H2IK = NVI.H2IK
				AND NVI_3.SVP = NVI.SVP
			WHERE NVI.NVI_KNZ = 'VI'
				AND NVI.SMA IN ('0','N')
				AND NVI.H2IK = @Kasse
				AND NVI.Quartal = @Quartal
			--	AND NVI.VertragsKV = @KV
			GROUP BY NVI.Quartal,NVI.H2IK,NVI.SVP,NVI_1.RANG,NVI_2.RANG,NVI_3.RANG
			ORDER BY SUM(NVI.MENGE * NVI.BETRAG) DESC
		END
		ELSE BEGIN
			/*** TOP Versicherten-NVI ***/
			--aktuelles Quartal
			SELECT TOP (@TOP)
				NVI.Quartal,
				NVI.H2IK,
				NVI.SVP,
				SUM(NVI.MENGE * NVI.BETRAG) AS NVI,
				COUNT(DISTINCT NVI.Abrechner_LANR7) AS AnzArzt,
				RANK() OVER (ORDER BY SUM(NVI.MENGE * NVI.BETRAG) DESC) AS Rang_Quartal,
				NVI_1.RANG AS Rang_Quartal_L1,
				NVI_2.RANG AS Rang_Quartal_L2,
				NVI_3.RANG AS Rang_Quartal_L3
			FROM [HZV].[NVI] NVI
			LEFT JOIN
				--1 Quartal davor
				(
				SELECT TOP (@TOP)	
					Quartal,
					H2IK,
					SVP,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT Abrechner_LANR7) AS AnzArzt,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'VI'
					AND SMA IN ('0','N')
					AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4),1)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4),2)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),3)
									END 
					AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,SVP
				) NVI_1
				ON NVI_1.H2IK = NVI.H2IK
				AND NVI_1.SVP = NVI.SVP
			LEFT JOIN
				--2 Quartale davor
				(
				SELECT TOP (@TOP)
					Quartal,
					H2IK,
					SVP,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT Abrechner_LANR7) AS AnzArzt,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'VI'
					AND SMA IN ('0','N')
					AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,3)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4),1)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),2)
									END 
					AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,SVP
				) NVI_2
				ON NVI_2.H2IK = NVI.H2IK
				AND NVI_2.SVP = NVI.SVP
			LEFT JOIN
				--3 Quartale davor
				(
				SELECT TOP (@TOP)
					Quartal,
					H2IK,
					SVP,
					SUM(MENGE * BETRAG) AS NVI,
					COUNT(DISTINCT Abrechner_LANR7) AS AnzArzt,
					RANK() OVER (ORDER BY SUM(MENGE * BETRAG) DESC) AS RANG
				FROM [HZV].[NVI]
				WHERE NVI_KNZ = 'VI'
					AND SMA IN ('0','N')
					AND H2IK = @Kasse
					AND Quartal =	CASE 
										WHEN RIGHT(@Quartal,1) = 1 THEN CONCAT(LEFT(@Quartal,4) - 1,2)
										WHEN RIGHT(@Quartal,1) = 2 THEN CONCAT(LEFT(@Quartal,4) - 1,3)
										WHEN RIGHT(@Quartal,1) = 3 THEN CONCAT(LEFT(@Quartal,4) - 1,4)
										WHEN RIGHT(@Quartal,1) = 4 THEN CONCAT(LEFT(@Quartal,4),1)
									END 
					AND VertragsKV = @KV
				GROUP BY Quartal,H2IK,SVP
				) NVI_3
				ON NVI_3.H2IK = NVI.H2IK
				AND NVI_3.SVP = NVI.SVP
			WHERE NVI.NVI_KNZ = 'VI'
				AND NVI.SMA IN ('0','N')
				AND NVI.H2IK = @Kasse
				AND NVI.Quartal = @Quartal
				AND NVI.VertragsKV = @KV
			GROUP BY NVI.Quartal,NVI.H2IK,NVI.SVP,NVI_1.RANG,NVI_2.RANG,NVI_3.RANG
			ORDER BY SUM(NVI.MENGE * NVI.BETRAG) DESC
		END
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-27
-- Description:	Dataset für Übersicht der teilnehmenden Versicherten
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_Versicherte] (@Kasse char(9), @Quartal char(6), @KV char(2), @TNStatus varchar(10), @Arzt char(7), @EGK char(10))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		IF @TNStatus = 'alle'
		BEGIN
			IF @Arzt = '0000000'
			BEGIN
				IF @EGK = ''
				BEGIN
					SELECT *,'alle' AS TNStatus
					FROM [HZV].[Teilnehmer_Versicherte]
					WHERE H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
					AND Quartal = @Quartal
					AND VertragsKV = @KV
					AND sMA = '0'
				END
				ELSE BEGIN
					SELECT *,'alle' AS TNStatus
					FROM [HZV].[Teilnehmer_Versicherte]
					WHERE H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
					AND Quartal = @Quartal
					AND VertragsKV = @KV
					AND sMA = '0'
					AND sVP = @EGK
				END
			END
			ELSE BEGIN
				IF @EGK = ''
				BEGIN
					SELECT *,'alle' AS TNStatus
					FROM [HZV].[Teilnehmer_Versicherte]
					WHERE H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
					AND Quartal = @Quartal
					AND VertragsKV = @KV
					AND L_ARZT_NR = @Arzt
					AND sMA = '0'
				END
				ELSE BEGIN
					SELECT *,'alle' AS TNStatus
					FROM [HZV].[Teilnehmer_Versicherte]
					WHERE H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
					AND Quartal = @Quartal
					AND VertragsKV = @KV
					AND L_ARZT_NR = @Arzt
					AND sMA = '0'
					AND sVP = @EGK
				END
			END
		END
		ELSE BEGIN
			IF @Arzt = '0000000'
			BEGIN
				IF @EGK = ''
				BEGIN
					SELECT *
					FROM
						(
						SELECT 
							TV.*,
							CASE WHEN TV.Teilnahme_Ende < Q.Quartal_Beginn THEN 'beendet' ELSE 'offen' END AS TNStatus
						FROM [HZV].[Teilnehmer_Versicherte] TV
						JOIN [HZV].[Quartale] Q
							ON Q.Quartal_lang = TV.Quartal
						WHERE TV.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
						AND TV.Quartal = @Quartal
						AND TV.VertragsKV = @KV
						AND TV.sMA = '0'
						) T
					WHERE TNStatus = @TNStatus
				END
				ELSE BEGIN
					SELECT *
					FROM
						(
						SELECT 
							TV.*,
							CASE WHEN TV.Teilnahme_Ende < Q.Quartal_Beginn THEN 'beendet' ELSE 'offen' END AS TNStatus
						FROM [HZV].[Teilnehmer_Versicherte] TV
						JOIN [HZV].[Quartale] Q
							ON Q.Quartal_lang = TV.Quartal
						WHERE TV.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
						AND TV.Quartal = @Quartal
						AND TV.VertragsKV = @KV
						AND TV.sMA = '0'
						AND TV.sVP = @EGK
						) T
					WHERE TNStatus = @TNStatus
				END
			END
			ELSE BEGIN
				IF @EGK = ''
				BEGIN
					SELECT *
					FROM
						(
						SELECT 
							TV.*,
							CASE WHEN TV.Teilnahme_Ende < Q.Quartal_Beginn THEN 'beendet' ELSE 'offen' END AS TNStatus
						FROM [HZV].[Teilnehmer_Versicherte] TV
						JOIN [HZV].[Quartale] Q
							ON Q.Quartal_lang = TV.Quartal
						WHERE TV.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
						AND TV.Quartal = @Quartal
						AND TV.VertragsKV = @KV
						AND TV.L_ARZT_NR = @Arzt
						AND TV.sMA = '0'
						) T
					WHERE TNStatus = @TNStatus
				END
				ELSE BEGIN
					SELECT *
					FROM
						(
						SELECT 
							TV.*,
							CASE WHEN TV.Teilnahme_Ende < Q.Quartal_Beginn THEN 'beendet' ELSE 'offen' END AS TNStatus
						FROM [HZV].[Teilnehmer_Versicherte] TV
						JOIN [HZV].[Quartale] Q
							ON Q.Quartal_lang = TV.Quartal
						WHERE TV.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
						AND TV.Quartal = @Quartal
						AND TV.VertragsKV = @KV
						AND TV.L_ARZT_NR = @Arzt
						AND TV.sMA = '0'
						AND TV.sVP = @EGK
						) T
					WHERE TNStatus = @TNStatus
				END
			END
		END
	END
	ELSE BEGIN
		IF @TNStatus = 'alle'
		BEGIN
			IF @Arzt = '0000000'
			BEGIN
				IF @EGK = ''
				BEGIN
					SELECT *,'alle' AS TNStatus
					FROM [HZV].[Teilnehmer_Versicherte]
					WHERE H2IK = @Kasse
					AND Quartal = @Quartal
					AND VertragsKV = @KV
					AND sMA = '0'
				END
				ELSE BEGIN
					SELECT *,'alle' AS TNStatus
					FROM [HZV].[Teilnehmer_Versicherte]
					WHERE H2IK = @Kasse
					AND Quartal = @Quartal
					AND VertragsKV = @KV
					AND sMA = '0'
					AND sVP = @EGK
				END
			END
			ELSE BEGIN
				IF @EGK = ''
				BEGIN
					SELECT *,'alle' AS TNStatus
					FROM [HZV].[Teilnehmer_Versicherte]
					WHERE H2IK = @Kasse
					AND Quartal = @Quartal
					AND VertragsKV = @KV
					AND L_ARZT_NR = @Arzt
					AND sMA = '0'
				END
				ELSE BEGIN
					SELECT *,'alle' AS TNStatus
					FROM [HZV].[Teilnehmer_Versicherte]
					WHERE H2IK = @Kasse
					AND Quartal = @Quartal
					AND VertragsKV = @KV
					AND L_ARZT_NR = @Arzt
					AND sMA = '0'
					AND sVP = @EGK
				END
			END
		END
		ELSE BEGIN
			IF @Arzt = '0000000'
			BEGIN
				IF @EGK = ''
				BEGIN
					SELECT *
					FROM
						(
						SELECT 
							TV.*,
							CASE WHEN TV.Teilnahme_Ende < Q.Quartal_Beginn THEN 'beendet' ELSE 'offen' END AS TNStatus
						FROM [HZV].[Teilnehmer_Versicherte] TV
						JOIN [HZV].[Quartale] Q
							ON Q.Quartal_lang = TV.Quartal
						WHERE TV.H2IK = @Kasse
						AND TV.Quartal = @Quartal
						AND TV.VertragsKV = @KV
						AND TV.sMA = '0'
						) T
					WHERE TNStatus = @TNStatus
				END
				ELSE BEGIN
					SELECT *
					FROM
						(
						SELECT 
							TV.*,
							CASE WHEN TV.Teilnahme_Ende < Q.Quartal_Beginn THEN 'beendet' ELSE 'offen' END AS TNStatus
						FROM [HZV].[Teilnehmer_Versicherte] TV
						JOIN [HZV].[Quartale] Q
							ON Q.Quartal_lang = TV.Quartal
						WHERE TV.H2IK = @Kasse
						AND TV.Quartal = @Quartal
						AND TV.VertragsKV = @KV
						AND TV.sMA = '0'
						AND TV.sVP = @EGK
						) T
					WHERE TNStatus = @TNStatus
				END
			END
			ELSE BEGIN
				IF @EGK = ''
				BEGIN
					SELECT *
					FROM
						(
						SELECT 
							TV.*,
							CASE WHEN TV.Teilnahme_Ende < Q.Quartal_Beginn THEN 'beendet' ELSE 'offen' END AS TNStatus
						FROM [HZV].[Teilnehmer_Versicherte] TV
						JOIN [HZV].[Quartale] Q
							ON Q.Quartal_lang = TV.Quartal
						WHERE TV.H2IK = @Kasse
						AND TV.Quartal = @Quartal
						AND TV.VertragsKV = @KV
						AND TV.L_ARZT_NR = @Arzt
						AND TV.sMA = '0'
						) T
					WHERE TNStatus = @TNStatus
				END
				ELSE BEGIN
					SELECT *
					FROM
						(
						SELECT 
							TV.*,
							CASE WHEN TV.Teilnahme_Ende < Q.Quartal_Beginn THEN 'beendet' ELSE 'offen' END AS TNStatus
						FROM [HZV].[Teilnehmer_Versicherte] TV
						JOIN [HZV].[Quartale] Q
							ON Q.Quartal_lang = TV.Quartal
						WHERE TV.H2IK = @Kasse
						AND TV.Quartal = @Quartal
						AND TV.VertragsKV = @KV
						AND TV.L_ARZT_NR = @Arzt
						AND TV.sMA = '0'
						AND TV.sVP = @EGK
						) T
					WHERE TNStatus = @TNStatus
				END
			END
		END
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-27
-- Description:	Dataset für verfügbare Ärzte auf Basis der Teilnehmerdaten
-- =============================================
CREATE PROCEDURE [HZV].[SP_Dataset_Versicherte_Aerzte] (@Kasse char(9), @Quartal char(6), @KV char(2))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT '0' AS Id,'0000000' AS L_ARZT_NR,'alle HzV-Ärzte' AS ArztName

		UNION

		SELECT 
			RANK() OVER (ORDER BY A.Nachname) AS Id,
			A.L_ARZT_NR,
			A.ArztName
		FROM
			(
			SELECT DISTINCT 
				T.L_ARZT_NR,
				A.Nachname,
				CONCAT(A.Anrede,' ',A.Nachname,' (LANR: ',T.L_ARZT_NR,')') AS ArztName
			FROM [HZV].[Teilnehmer_Versicherte] T
			JOIN [HZV].[Teilnehmer_Aerzte] A
				ON A.LANR7 = T.L_ARZT_NR
				AND A.VertragsID = T.Vertrags_ID
			WHERE T.Quartal = @Quartal
			AND T.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
			AND T.VertragsKV = @KV
			) A
		ORDER BY Id
	END
	ELSE BEGIN
		SELECT '0' AS Id,'0000000' AS L_ARZT_NR,'alle HzV-Ärzte' AS ArztName

		UNION

		SELECT 
			RANK() OVER (ORDER BY A.Nachname) AS Id,
			A.L_ARZT_NR,
			A.ArztName
		FROM
			(
			SELECT DISTINCT 
				T.L_ARZT_NR,
				A.Nachname,
				CONCAT(A.Anrede,' ',A.Nachname,' (LANR: ',T.L_ARZT_NR,')') AS ArztName
			FROM [HZV].[Teilnehmer_Versicherte] T
			JOIN [HZV].[Teilnehmer_Aerzte] A
				ON A.LANR7 = T.L_ARZT_NR
				AND A.VertragsID = T.Vertrags_ID
			WHERE T.H2IK = @Kasse
			AND T.Quartal = @Quartal
			AND T.VertragsKV = @KV
			) A
		ORDER BY Id
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-18
-- Description:	Dashboard-Dataset für Abrechnung
-- =============================================
CREATE PROCEDURE [HZV].[SP_DB_Dataset_Abrechnung] (@Kasse char(9))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT
			E.S_ABRECHNUNGSQUARTAL,
			--E.ABRECHNUNGSQUARTAL,
			E.KV,
			E.VERARBEITUNGS_KNZ,
			KV.Kuerzel_kurz,
			KV.Kuerzel_lang,
			SUM(E.BETRAG) AS BETRAG
		FROM
			(
			SELECT 
				EFN.S_ABRECHNUNGSQUARTAL,
				EFN.ABRECHNUNGSQUARTAL,
				EFN.KV,
				EFN.VERARBEITUNGS_KNZ,
				SUM(EFN.NETTOBETRAG_GONR) * CASE WHEN EFN.VERARBEITUNGS_KNZ = '10' THEN 1 ELSE -1 END AS BETRAG
			FROM [HZV].[Abrechnung_Einzelfall] EFN
			WHERE EFN.S_ABRECHNUNGSQUARTAL = (SELECT Q_Dashboard_lang FROM [HZV].[Steuerung])
			AND EFN.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
			GROUP BY EFN.S_ABRECHNUNGSQUARTAL,EFN.ABRECHNUNGSQUARTAL,EFN.KV,EFN.VERARBEITUNGS_KNZ
			) E
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = E.KV
		GROUP BY E.S_ABRECHNUNGSQUARTAL,E.KV,KV.Kuerzel_kurz,KV.Kuerzel_lang,E.VERARBEITUNGS_KNZ--,E.ABRECHNUNGSQUARTAL
		ORDER BY E.S_ABRECHNUNGSQUARTAL,E.KV--,E.ABRECHNUNGSQUARTAL
	END
	ELSE BEGIN
		SELECT
			E.S_ABRECHNUNGSQUARTAL,
			--E.ABRECHNUNGSQUARTAL,
			E.KV,
			E.VERARBEITUNGS_KNZ,
			KV.Kuerzel_kurz,
			KV.Kuerzel_lang,
			SUM(E.BETRAG) AS BETRAG
		FROM
			(
			SELECT 
				EFN.S_ABRECHNUNGSQUARTAL,
				EFN.ABRECHNUNGSQUARTAL,
				EFN.KV,
				EFN.VERARBEITUNGS_KNZ,
				SUM(EFN.NETTOBETRAG_GONR) * CASE WHEN EFN.VERARBEITUNGS_KNZ = '10' THEN 1 ELSE -1 END AS BETRAG
			FROM [HZV].[Abrechnung_Einzelfall] EFN
			WHERE EFN.S_ABRECHNUNGSQUARTAL = (SELECT Q_Dashboard_lang FROM [HZV].[Steuerung])
			AND EFN.H2IK = @Kasse
			GROUP BY EFN.S_ABRECHNUNGSQUARTAL,EFN.ABRECHNUNGSQUARTAL,EFN.KV,EFN.VERARBEITUNGS_KNZ
			) E
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = E.KV
		GROUP BY E.S_ABRECHNUNGSQUARTAL,E.KV,KV.Kuerzel_kurz,KV.Kuerzel_lang,E.VERARBEITUNGS_KNZ--,E.ABRECHNUNGSQUARTAL
		ORDER BY E.S_ABRECHNUNGSQUARTAL,E.KV--,E.ABRECHNUNGSQUARTAL
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-18
-- Description:	Dashboard-Dataset für Bereinigung
-- =============================================
CREATE PROCEDURE [HZV].[SP_DB_Dataset_Bereinigung] (@Kasse char(9))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT
			'000000000' AS HauptKassenIK,
			B.VERTRAGS_KV,
			KV.Kuerzel_kurz,
			SUM(B.Diff_kons_Euro) AS Diff_Euro,
			SUM(B.Gesamt_fortentw_Euro) AS Gesamt_fortentw_Euro,
			SUM(B.Gesamt_Euro) AS Gesamt_Euro
		FROM [HZV].[Bereinigung] B
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = B.VERTRAGS_KV
		WHERE B.QUARTAL IN (SELECT Q_Dashboard_kurz FROM [HZV].[V_DB_Steuerung])
		AND HauptKassenIK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
		GROUP BY B.VERTRAGS_KV,KV.Kuerzel_kurz
		ORDER BY B.VERTRAGS_KV
	END
	ELSE BEGIN
		SELECT
			B.HauptKassenIK,
			B.VERTRAGS_KV,
			KV.Kuerzel_kurz,
			SUM(B.Diff_kons_Euro) AS Diff_Euro,
			SUM(B.Gesamt_fortentw_Euro) AS Gesamt_fortentw_Euro,
			SUM(B.Gesamt_Euro) AS Gesamt_Euro
		FROM [HZV].[Bereinigung] B
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = B.VERTRAGS_KV
		WHERE B.QUARTAL IN (SELECT Q_Dashboard_kurz FROM [HZV].[V_DB_Steuerung])
		AND HauptKassenIK = @Kasse
		GROUP BY B.HauptKassenIK,B.VERTRAGS_KV,KV.Kuerzel_kurz
		ORDER BY B.VERTRAGS_KV
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-26
-- Description:	Dashboard-Dataset für Durchschnittliche Kosten
-- =============================================
CREATE PROCEDURE [HZV].[SP_DB_Dataset_DurchschnittKosten] (@Kasse char(9))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT
			Quartal_kurz,
			Quartal_lang,
			(BtrABR - BtrBER + BtrNVI)/AnzTNM AS DurchschnittKosten
		FROM
			(
			SELECT 
				Quartal_kurz,
				Quartal_lang,
				SUM(AnzTNM) AS AnzTNM,
				SUM(BtrABR) AS BtrABR,
				SUM(BtrBER) AS BtrBER,
				SUM(BtrNVI) AS BtrNVI
			FROM [HZV].[Kosten]
			WHERE Quartal_kurz = (SELECT Q_Dashboard_kurz FROM [HZV].[Steuerung])
			AND H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
			GROUP BY Quartal_kurz,Quartal_lang
			) T
	END
	ELSE BEGIN
		SELECT
			Quartal_kurz,
			Quartal_lang,
			(BtrABR - BtrBER + BtrNVI)/AnzTNM AS DurchschnittKosten
		FROM
			(
			SELECT 
				Quartal_kurz,
				Quartal_lang,
				SUM(AnzTNM) AS AnzTNM,
				SUM(BtrABR) AS BtrABR,
				SUM(BtrBER) AS BtrBER,
				SUM(BtrNVI) AS BtrNVI
			FROM [HZV].[Kosten]
			WHERE Quartal_kurz = (SELECT Q_Dashboard_kurz FROM [HZV].[Steuerung])
				AND H2IK = @Kasse
			GROUP BY Quartal_kurz,Quartal_lang
			) T
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-18
-- Description:	Dashboard-Dataset für NVI
-- =============================================
CREATE PROCEDURE [HZV].[SP_DB_Dataset_NVI] (@Kasse char(9))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT
			N.VertragsKV,
			KV.Kuerzel_kurz,
			N.NVI_KNZ,
			SUM(N.MENGE * N.BETRAG) AS BTR
		FROM [HZV].[NVI] N
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = N.VertragsKV
		WHERE N.Quartal = (SELECT Q_Dashboard_kurz FROM [HZV].[Steuerung])
		AND H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
		GROUP BY N.VertragsKV,N.NVI_KNZ,KV.Kuerzel_kurz
	END
	ELSE BEGIN
		SELECT
			N.VertragsKV,
			KV.Kuerzel_kurz,
			N.NVI_KNZ,
			SUM(N.MENGE * N.BETRAG) AS BTR
		FROM [HZV].[NVI] N
		JOIN [KONST].[KVRegionen] KV
			ON KV.KVId = N.VertragsKV
		WHERE N.Quartal = (SELECT Q_Dashboard_kurz FROM [HZV].[Steuerung])
		AND H2IK = @Kasse
		GROUP BY N.VertragsKV,N.NVI_KNZ,KV.Kuerzel_kurz
	END

END
GO

-- =============================================
-- Author:		Antje Buksch
-- Create date: 2022-01-17
-- Description:	Dashboard-Dataset für Teilnehmer
-- =============================================
CREATE PROCEDURE [HZV].[SP_DB_Dataset_Teilnehmer] (@Kasse char(9))
AS
BEGIN

	IF @Kasse = '000000000'
	BEGIN
		SELECT
			KV.KVId,
			KV.Kuerzel_lang,
			KV.Kuerzel_kurz,
			KV.Geometrie,
			TNM.AnzTV,
			TNM.AnzVers,
			TNM.QuoteTV,
			TNM.AnzTA
		FROM [KONST].[KVRegionen] KV
		LEFT JOIN
			(
			SELECT
				TV.VertragsKV,
				TV.VertragsID,
				TV.AnzTV,
				V.AnzVers,
				--CAST(ROUND(CAST(TV.AnzTV AS decimal(15,5))/CAST(V.AnzVers AS decimal(15,5)) * 100,2) AS decimal(5,2)) AS QuoteTV,
				CAST(TV.AnzTV AS decimal(15,5))/CAST(V.AnzVers AS decimal(15,5)) AS QuoteTV,
				TA.AnzTA
			FROM
				(
				SELECT
					TV.VertragsKV,
					'00000000000' AS VertragsID,
					COUNT(DISTINCT sVP) AS AnzTV
				FROM [HZV].[Teilnehmer_Versicherte] TV
				--JOIN [HZV].[Steuerung] S
				--	ON S.Q_Dashboard_lang = TV.Quartal
				WHERE TV.Quartal = (SELECT Q_Dashboard_lang FROM [HZV].[Steuerung])
				AND TV.Teilnahme_Ende IS NULL
				AND TV.H2IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
				GROUP BY TV.VertragsKV
				) TV
			JOIN
				(
				SELECT 
					KV,
					--SKunde,
					SUM(Anzahl) AS AnzVers
				FROM [HZV].[KM6] KM6
				WHERE Quartal = (SELECT Q_Dashboard_kurz FROM [HZV].[Steuerung])
				AND Kassen_IK IN (SELECT DISTINCT HauptKassenIK FROM [HZV].[Kassen])
				GROUP BY KV--,SKunde
				) V
			ON V.KV = TV.VertragsKV
			JOIN
				(
				SELECT 
					TA.VertragsKV,
					'00000000000' AS VertragsID,
					COUNT(DISTINCT TA.LANR7) AS AnzTA
				FROM [HZV].[Teilnehmer_Aerzte] TA
				WHERE TA.TeilnahmeEnde >= (SELECT Quartal_Beginn FROM [HZV].[V_DB_Steuerung])
				AND TA.TeilnahmeBeginn <= (SELECT Quartal_Ende FROM [HZV].[V_DB_Steuerung])
				GROUP BY TA.VertragsKV
				) TA
			ON TA.VertragsKV = TV.VertragsKV
			AND TA.VertragsID = TV.VertragsID
			) TNM
		ON TNM.VertragsKV = KV.KVId
		ORDER BY KV.KVId
	END
	ELSE BEGIN
		SELECT
			KV.KVId,
			KV.Kuerzel_lang,
			KV.Kuerzel_kurz,
			KV.Geometrie,
			TNM.AnzTV,
			TNM.AnzVers,
			TNM.QuoteTV,
			TNM.AnzTA
		FROM [KONST].[KVRegionen] KV
		LEFT JOIN
			(
			SELECT
				TV.VertragsKV,
				TV.Vertrags_ID,
				TV.AnzTV,
				V.AnzVers,
				--CAST(ROUND(CAST(TV.AnzTV AS decimal(15,5))/CAST(V.AnzVers AS decimal(15,5)) * 100,2) AS decimal(5,2)) AS QuoteTV,
				CAST(TV.AnzTV AS decimal(15,5))/CAST(V.AnzVers AS decimal(15,5)) AS QuoteTV,
				TA.AnzTA
			FROM
				(
				SELECT
					TV.VertragsKV,
					TV.Vertrags_ID,
					TV.H2IK,
					COUNT(DISTINCT sVP) AS AnzTV
				FROM [HZV].[Teilnehmer_Versicherte] TV
				--JOIN [HZV].[Steuerung] S
				--	ON S.Q_Dashboard_lang = TV.Quartal
				WHERE TV.Quartal = (SELECT Q_Dashboard_lang FROM [HZV].[Steuerung])
					AND TV.Teilnahme_Ende IS NULL
					AND TV.H2IK = @Kasse
				GROUP BY TV.VertragsKV,TV.Vertrags_ID,TV.H2IK
				) TV
			JOIN
				(
				SELECT 
					KV,
					Kassen_IK,
					SUM(Anzahl) AS AnzVers
				FROM [HZV].[KM6] KM6
				WHERE Quartal = (SELECT Q_Dashboard_kurz FROM [HZV].[Steuerung])
				GROUP BY KV,Kassen_IK
				) V
			ON V.KV = TV.VertragsKV
			AND V.Kassen_IK = TV.H2IK
			JOIN
				(
				SELECT 
					TA.VertragsKV,
					TA.VertragsID,
					COUNT(DISTINCT TA.LANR7) AS AnzTA
				FROM [HZV].[Teilnehmer_Aerzte] TA
				WHERE TA.TeilnahmeEnde >= (SELECT Quartal_Beginn FROM [HZV].[V_DB_Steuerung])
				AND TA.TeilnahmeBeginn <= (SELECT Quartal_Ende FROM [HZV].[V_DB_Steuerung])
				GROUP BY TA.VertragsKV,TA.VertragsID
				) TA
			ON TA.VertragsKV = TV.VertragsKV
			AND TA.VertragsID= TV.Vertrags_ID
			) TNM
		ON TNM.VertragsKV = KV.KVId
		ORDER BY KV.KVId
	END

END
GO

-- =============================================
-- Author:		Jan Neubert
-- Create date: 2022-01-11
-- Stand:		2022-01-28
-- Description:	Abzug der Bereinigungsdaten für den HZV Report inkl. Löschen upzudatender und veralteter DS
-- =============================================
CREATE PROCEDURE [HZV].[SP_Import_Bereinigung]
	-- Add the parameters for the stored procedure here
AS
BEGIN

SET XACT_ABORT ON
BEGIN TRAN
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


	-- Löschen der Datensätze deren Vertrag noch nicht gestartet oder beendet ist
	delete t1	--		select *
	from [HZV].[Bereinigung] t1
	left join  [HZV].[Vertraege] t2
	on t1.Vertrags_ID=t2.VertragsID
	and t1.VERTRAGS_KV=t2.VertragsKV
	and t1.HauptKassenIK =t2.HauptKassenIK
	where concat (left(t1.Quartal,4),right(t1.Quartal,1)) not between t2.DienstleistungBeginn and t2.DienstleistungEnde
	and t2.Dienstleistung='Teilnehmermanagement'

	-- Löschen der Datensätze die keinen Vertrag haben
	delete t1	--		select *
	from [HZV].[Bereinigung] t1
	left join  [HZV].[Vertraege] t2
	on --t1.Vertrags_ID=t2.VertragsID and			--entfernt, da mit VertragsID Fusionskassen gelöscht werden würden
	t1.VERTRAGS_KV=t2.VertragsKV
	and t1.HauptKassenIK =t2.HauptKassenIK
	and t2.Dienstleistung='Teilnehmermanagement'
	where t2.HauptKassenIK is null
COMMIT TRAN

END
GO

-- =============================================
-- Author:		Jan Neubert
-- Create date: 2022-01-12
-- Stand:		2022-01-28
-- Description:	Abzug der NVI-Daten für den HZV Report inkl. Löschen veralteter DS
-- =============================================
CREATE PROCEDURE [HZV].[SP_Import_NVI]
	-- Add the parameters for the stored procedure here
AS
BEGIN

SET XACT_ABORT ON
BEGIN TRAN
	--Import regelmäßig
	insert into [HZV].[NVI]
	SELECT 
		  [VERTRAGSNUMMER] 
		  ,[KV]
		  ,[KV_WOHNORT]	 	  
		  ,t1.[QUARTAL]
		  , SKUNDE
		  ,H2IK
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
		  ,BEHANDLUNGSDATUM
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


	-- Löschen der Datensätze deren Vertrag noch nicht gestartet oder beendet ist
	delete t1	--		select *
	from [HZV].NVI t1
	left join  [HZV].[Vertraege] t2
	on t1.VertragsID=t2.VertragsID
	and t1.VertragsKV=t2.VertragsKV
	and t1.H2IK =t2.HauptKassenIK
	where concat (left(t1.Quartal,4),right(t1.Quartal,1)) not between t2.DienstleistungBeginn and t2.DienstleistungEnde
	and t2.Dienstleistung='Teilnehmermanagement'


	-- Löschen der Datensätze die keinen Vertrag haben
	delete t1	--		select *
	from [HZV].NVI t1
	left join  [HZV].[Vertraege] t2
	on --t1.Vertrags_ID=t2.VertragsID and			--entfernt, da mit VertragsID Fusionskassen gelöscht werden würden
	t1.VertragsKV=t2.VertragsKV
	and t1.H2IK =t2.HauptKassenIK
	and t2.Dienstleistung='Teilnehmermanagement'
	where t2.HauptKassenIK is null
COMMIT TRAN

END
GO

-- ===========================================================
-- Author:		Antje Buksch
-- Create date: 2022-01-13
-- Description:	Abzug der Vertragsdaten für den HzV-Report
-- ===========================================================
CREATE PROCEDURE [HZV].[SP_Import_Vertraege]
AS
BEGIN

SET XACT_ABORT ON
BEGIN TRAN
	DELETE FROM [HZV].[Vertraege]

	INSERT INTO [HZV].[Vertraege]
	SELECT    
		V.Name AS VertragName, 
		V.VertragID,
		KVR.Vertragskennzeichen, 
		R.KV,
		VR.GueltigVon, 
		VR.GueltigBis, 
		K.HauptIK, 
		K.Name AS KasseName, 
		KVR.Beitrittsquartal, 
		D.Name AS Dienstleistung, 
		KVRD.QuartalVon, 
		KVRD.QuartalBis
	FROM AbrBV_Vertragsmanagement_PROD.dbo.Kasse AS K 
	INNER JOIN AbrBV_Vertragsmanagement_PROD.dbo.KasseVertragRegionen AS KVR
		ON KVR.KasseID = K.KasseID 
	INNER JOIN AbrBV_Vertragsmanagement_PROD.dbo.KasseVertragRegionDienstleistungen AS KVRD 
		ON KVRD.KVRID = KVR.KVRID 
	INNER JOIN AbrBV_Vertragsmanagement_PROD.dbo.Vertrag AS V 
		ON V.VertragID = KVR.VertragID 
	INNER JOIN AbrBV_Vertragsmanagement_PROD.dbo.Region AS R 
		ON R.RegionID = KVR.RegionID 
	INNER JOIN AbrBV_Vertragsmanagement_PROD.dbo.VertragRegionen AS VR 
		ON VR.VertragID = V.VertragID AND VR.RegionID = R.RegionID 
	INNER JOIN AbrBV_Vertragsmanagement_PROD.dbo.Dienstleistung AS D 
		ON D.DLID = KVRD.DLID 
	INNER JOIN AbrBV_Vertragsmanagement_PROD.dbo.Vertragsart AS VA 
		ON VA.VertragsartID = V.VertragsartID
	WHERE (KVRD.Del = '0')
		AND V.Name LIKE 'HzV%'
		AND VR.GueltigBis > DATEADD(year,-4,CAST(CONCAT(YEAR(GETDATE()) - 1,'-12-31') AS date))
		AND (KVRD.QuartalBis > CONCAT(YEAR(GETDATE()) - 5,'4') OR KVRD.QuartalBis IS NULL)

	-- Doppelte DS der VBU, KV 71 TNM aufgrund DL-Wechsel zwischen Convema und spectrumK vereinheitlichen bzw löschen
	update t1
	set DienstleistungBeginn = 20121		--		DL-Beginn der Convema
	from [HZV].[Vertraege] t1
	WHERE HauptKassenIK = '109723913'
		AND VertragsKV = '71'
		AND Dienstleistung = 'Teilnehmermanagement'
		AND DienstleistungEnde IS NULL

	DELETE --SELECT *
	FROM [HZV].[Vertraege]
	WHERE HauptKassenIK = '109723913'
		AND VertragsKV = '71'
		AND Dienstleistung = 'Teilnehmermanagement'
		AND DienstleistungEnde IS NOT NULL
COMMIT TRAN

END
GO
