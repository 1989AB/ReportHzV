USE [AbrBV_Reporting_DEV]
GO

--Konstanten-Tabellen
CREATE TABLE [KONST].[KVRegionen](
	[KVId] [char](2) NOT NULL,
	[KV_kurz] [varchar](50) NOT NULL,
	[KV_lang] [varchar](50) NOT NULL,
	[Kuerzel_kurz] [varchar](10) NULL,
	[Kuerzel_lang] [varchar](10) NULL,
	[Geometrie] [geometry] NULL
) 
GO

CREATE TABLE [KONST].[Altersgruppen](
	[Age] [int] NOT NULL,
	[AG_kurz] [varchar](5) NOT NULL,
	[AG_lang] [varchar](20) NOT NULL
) 
GO

--Produkt-Tabellen anlegen
CREATE TABLE [HZV].[Steuerung](
	[Q_Dashboard_kurz] [nvarchar](5) NULL,
	[Q_Dashboard_lang] [nvarchar](6) NULL,
	[LastUpdate] [datetime2](7) NULL
) 
GO

CREATE TABLE [HZV].[Quartale](
	[Quartal_kurz] [char](5) NOT NULL,
	[Quartal_lang] [char](6) NOT NULL,
	[Quartal_Beginn] [date] NOT NULL,
	[Quartal_Ende] [date] NOT NULL,
	[Quartal_Text_kurz] [varchar](10) NOT NULL,
	[Quartal_Text_lang] [varchar](20) NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [HZV].[Bereinigung](
	[VERTRAGS_ID] [nvarchar](25) NOT NULL,
	[VERTRAGS_KV] [nvarchar](2) NOT NULL,
	[WOHNORT_KV] [nvarchar](2) NOT NULL,
	[QUARTAL] [nvarchar](5) NOT NULL,
	[HauptKassenIK] [nvarchar](9) NOT NULL,
	[VKNR] [nvarchar](5) NOT NULL,
	[Anzahl_Versicherte] [int] NOT NULL,
	[Anzahl_Neueinschreiber] [int] NULL,
	[Diff_kons_Punkte] [decimal](12, 1) NULL,
	[Diff_kons_Euro] [decimal](13, 2) NULL,
	[Gesamt_fortentw_Punkte] [decimal](12, 1) NULL,
	[Gesamt_fortentw_Euro] [decimal](13, 2) NULL,
	[Gesamt_Punkte] [decimal](12, 1) NULL,
	[Gesamt_Euro] [decimal](13, 2) NULL
) 
GO

CREATE TABLE [HZV].[NVI](
	[VertragsID] [nvarchar](11) NULL,
	[VertragsKV] [nvarchar](2) NULL,
	[WohnortKV] [nvarchar](2) NULL,
	[Quartal] [nchar](5) NULL,
	[SKUNDE] [nvarchar](9) NULL,
	[VKNR] [nvarchar](5) NULL,
	[SVP] [nvarchar](10) NULL,
	[SMA] [nvarchar](2) NULL,
	[ERSATZVERFAHREN] [nvarchar](1) NULL,
	[NACHNAME] [nvarchar](45) NULL,
	[VORNAME] [nvarchar](45) NULL,
	[GEBDATUM] [date] NULL,
	[Betreu_LANR7] [nvarchar](7) NULL,
	[Betreu_BSNR7] [nvarchar](7) NULL,
	[Abrechner_LANR7] [nvarchar](7) NULL,
	[Abrechner_BSNR7] [nvarchar](7) NULL,
	[GONR] [nvarchar](7) NULL,
	[MENGE] [int] NULL,
	[BETRAG] [numeric](18, 2) NULL,
	[NVI_KNZ] [varchar](max) NOT NULL
) 
GO
