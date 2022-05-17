USE [AbrBV_Reporting_DEV]
GO

CREATE TABLE [KONST].[Altersgruppen](
	[Age] [int] NOT NULL,
	[AG_kurz] [varchar](5) NOT NULL,
	[AG_lang] [varchar](20) NOT NULL,
	[AG_Id] [int] NULL
) ON [PRIMARY]
GO

CREATE TABLE [KONST].[KVRegionen](
	[KVId] [char](2) NOT NULL,
	[KV_kurz] [varchar](50) NOT NULL,
	[KV_lang] [varchar](50) NOT NULL,
	[Kuerzel_kurz] [varchar](10) NULL,
	[Kuerzel_lang] [varchar](10) NULL,
	[Geometrie] [geometry] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [KONST].[SKUNDE_MATCH](
	[SKUNDE] [char](9) NULL,
	[SKUNDE_Name] [varchar](150) NULL,
	[H2IK] [char](9) NULL,
	[H2IK_Name] [varchar](150) NULL,
	[KassenIK] [char](9) NULL,
	[KassenIK_Name] [varchar](150) NULL,
	[GueltigVon] [date] NULL,
	[GueltigBis] [date] NULL
) ON [PRIMARY]
GO

CREATE TABLE [HZV].[Abrechnung_Diagnosen](
	[SKUNDE] [varchar](9) NULL,
	[Jahr] [int] NULL,
	[SVP] [varchar](35) NULL,
	[SMA] [varchar](2) NULL,
	[ABRECHNUNGSQUARTAL] [varchar](6) NULL,
	[L_ARZT_NR] [varchar](7) NULL,
	[L_ARZT_NR_FG] [varchar](2) NULL,
	[L_ARZT_NR_GUELTIG] [varchar](1) NULL,
	[KV_NUMMER_MA] [varchar](12) NULL,
	[BS_NR] [varchar](7) NULL,
	[BSN_KV_ERW] [varchar](2) NULL,
	[DIA_LFD_NR] [int] NULL,
	[DIAGNOSESICHERHEIT] [varchar](1) NULL,
	[DIA_DATUM] [date] NULL,
	[EDI_ICD_CODE] [varchar](12) NULL,
	[EFN_LFD_NR] [int] NULL,
	[EGK_NR] [varchar](10) NULL,
	[EGK_NR_GUELTIG] [varchar](1) NULL,
	[ERBRINGER_IK] [varchar](9) NULL,
	[EGK_NR_MA] [varchar](10) NULL,
	[ERSATZVERFAHREN] [varchar](1) NULL,
	[GEB_DATUM_DATE] [date] NULL,
	[GESCHLECHT] [varchar](1) NULL,
	[H2IK] [varchar](9) NULL,
	[HAUPTKASSEN_IK] [varchar](9) NULL,
	[ICD_CODE] [varchar](5) NULL,
	[ICD_CODE_ERG] [varchar](7) NULL,
	[JOINDATUM_ZEITRAUM] [date] NULL,
	[KASSEN_IK] [varchar](9) NULL,
	[KV] [varchar](2) NULL,
	[KV_KARTEN_HKIK] [varchar](9) NULL,
	[KV_KARTEN_IK] [varchar](9) NULL,
	[NACHRICHTENTYP] [varchar](6) NULL,
	[NAME] [varchar](45) NULL,
	[KV_NUMMER] [varchar](12) NULL,
	[PRUEF_KZ] [varchar](1) NULL,
	[QUELL_REF] [int] NULL,
	[RECHTSKREIS] [varchar](1) NULL,
	[SEITENLOKALISATION] [varchar](1) NULL,
	[STORNO_KNZ] [varchar](1) NULL,
	[VERARBEITUNGS_KNZ] [varchar](2) NULL,
	[VERSICHERTEN_STATUS] [varchar](1) NULL,
	[VERTRAGS_ID] [varchar](25) NULL,
	[VERTRAGSBEREICH] [varchar](2) NULL,
	[VORNAME] [varchar](45) NULL,
	[ZEITRAUM] [varchar](6) NULL,
	[ZEITRAUMTYP] [varchar](1) NULL,
	[BESONDERE_PERS_GRP] [varchar](2) NULL,
	[DMP_KNZ] [varchar](2) NULL,
	[RECHNUNGS_DATUM] [varchar](8) NULL,
	[S_ABRECHNUNGSQUARTAL] [varchar](6) NULL
) ON [PRIMARY]
GO

CREATE TABLE [HZV].[Abrechnung_Einzelfall](
	[SKUNDE] [varchar](9) NULL,
	[Jahr] [int] NULL,
	[SVP] [varchar](35) NULL,
	[SMA] [varchar](2) NULL,
	[ABRECHNUNGSQUARTAL] [varchar](6) NULL,
	[ABSENDER_IK] [varchar](9) NULL,
	[L_ARZT_NR] [varchar](7) NULL,
	[L_ARZT_NR_FG] [varchar](2) NULL,
	[L_ARZT_NR_GUELTIG] [varchar](1) NULL,
	[L_ARZT_NR_UE] [varchar](7) NULL,
	[L_ARZT_NR_UE_FG] [varchar](2) NULL,
	[BEGINN_ABR_DATUM] [varchar](8) NULL,
	[BRUTTO_DSK_OHNE_ZUZ] [money] NULL,
	[BRUTTO_GONR_OHNE_ZUZ] [money] NULL,
	[BRUTTO_SACHK_OHNE_ZUZ] [money] NULL,
	[BS_NR] [varchar](7) NULL,
	[BS_NR_UE] [varchar](7) NULL,
	[BSN_KV_ERW] [varchar](2) NULL,
	[BSN_KV_ERW_UE] [varchar](2) NULL,
	[EFN_LFD_NR] [int] NULL,
	[EGK_NR] [varchar](10) NULL,
	[EGK_NR_GUELTIG] [varchar](1) NULL,
	[EGK_NR_MA] [varchar](10) NULL,
	[EMPFAENGER_IK] [varchar](9) NULL,
	[ENDE_ABR_DATUM] [varchar](8) NULL,
	[ERBRINGER_IK] [varchar](9) NULL,
	[ERSATZVERFAHREN] [varchar](1) NULL,
	[FHL_KZ] [varchar](1) NULL,
	[GEB_DATUM_DATE] [date] NULL,
	[GESAMT_GESETZ_ZUZ] [money] NULL,
	[GESAMT_MND] [money] NULL,
	[GESAMT_VERTRAG_ZUZ] [money] NULL,
	[GESCHAEFTSVORFALL] [varchar](2) NULL,
	[GESCHLECHT] [varchar](1) NULL,
	[GUELTIGKEIT_VERS_KARTE] [varchar](4) NULL,
	[H2IK] [varchar](9) NULL,
	[HAUPTKASSEN_IK] [varchar](9) NULL,
	[INANSPRUCHN_ART] [varchar](1) NULL,
	[JOINDATUM_ZEITRAUM] [date] NULL,
	[KASSEN_IK] [varchar](9) NULL,
	[KORR_ZAEHLER] [varchar](3) NULL,
	[KV] [varchar](2) NULL,
	[KV_KARTEN_HKIK] [varchar](9) NULL,
	[KV_KARTEN_IK] [varchar](9) NULL,
	[KV_NUMMER] [varchar](12) NULL,
	[KV_NUMMER_MA] [varchar](12) NULL,
	[KV_UE] [varchar](2) NULL,
	[ERSTELLUNGSDATUM] [date] NULL,
	[LADEDATUM] [date] NULL,
	[LAENDER_KNZ] [varchar](3) NULL,
	[NACHRICHTENART] [varchar](1) NULL,
	[NACHRICHTENTYP] [varchar](6) NULL,
	[NAME] [varchar](45) NULL,
	[NETTOBETRAG_GONR] [money] NULL,
	[PLZ] [varchar](5) NULL,
	[PRUEF_KZ] [varchar](1) NULL,
	[QUELL_REF] [int] NULL,
	[RECHNUNGS_DATUM] [varchar](8) NULL,
	[RECHNUNGS_IK] [varchar](9) NULL,
	[RECHNUNGS_NR] [varchar](20) NULL,
	[RECHNUNGSART] [varchar](1) NULL,
	[RECHTSKREIS] [varchar](1) NULL,
	[RSA_STATUS] [varchar](3) NULL,
	[SAMMELRECHNUNGS_ID] [varchar](14) NULL,
	[STORNO_KNZ] [varchar](1) NULL,
	[TEILNEHMER_ID] [varchar](15) NULL,
	[UEBERWEISER_IK] [varchar](9) NULL,
	[UNFALL_KNZ] [varchar](1) NULL,
	[VERARBEITUNGS_KNZ] [varchar](2) NULL,
	[VERSICHERTEN_STATUS] [varchar](1) NULL,
	[VERTRAGS_ID] [varchar](25) NULL,
	[VERTRAGSBEREICH] [varchar](2) NULL,
	[VORNAME] [varchar](45) NULL,
	[ZAHLUNGSEMPF_IK] [varchar](9) NULL,
	[ZEITRAUM] [varchar](6) NULL,
	[ZEITRAUMTYP] [varchar](1) NULL,
	[ZUZAHLUNGSSTATUS] [varchar](1) NULL,
	[K_MENSCH_ID] [int] NULL,
	[BESONDERE_PERS_GRP] [varchar](2) NULL,
	[DMP_KNZ] [varchar](2) NULL,
	[ZAHNARZT_NR] [varchar](6) NULL,
	[ZA_VERTRAGSBEREICH] [varchar](2) NULL,
	[S_ABRECHNUNGSQUARTAL] [varchar](6) NULL
) ON [PRIMARY]
GO

CREATE TABLE [HZV].[Abrechnung_Entgelt](
	[SKUNDE] [varchar](9) NULL,
	[Jahr] [int] NULL,
	[SVP] [varchar](35) NULL,
	[SMA] [varchar](2) NULL,
	[ABRECHNUNGSQUARTAL] [varchar](6) NULL,
	[ABR_LFD_NR] [int] NULL,
	[ABRECH_GRUND] [nvarchar](70) NULL,
	[ANZ_GONR] [int] NULL,
	[L_ARZT_NR] [varchar](7) NULL,
	[L_ARZT_NR_FG] [varchar](2) NULL,
	[L_ARZT_NR_GUELTIG] [varchar](1) NULL,
	[L_ARZT_NR_UE] [varchar](7) NULL,
	[L_ARZT_NR_UE_FG] [varchar](2) NULL,
	[L_ARZT_NR_UE_GUELTIG] [varchar](1) NULL,
	[BS_NR] [varchar](7) NULL,
	[BS_NR_UE] [varchar](7) NULL,
	[BSN_KV_ERW] [varchar](2) NULL,
	[BSN_KV_ERW_UE] [varchar](2) NULL,
	[DATUM_MINDERUNG] [varchar](8) NULL,
	[DIALYSESACHKOSTEN] [money] NULL,
	[DRG_INFO] [varchar](4) NULL,
	[EFN_LFD_NR] [int] NULL,
	[EGK_NR] [varchar](10) NULL,
	[EGK_NR_GUELTIG] [varchar](1) NULL,
	[ERBRINGER_IK] [varchar](9) NULL,
	[EGK_NR_MA] [varchar](10) NULL,
	[ERSATZVERFAHREN] [varchar](1) NULL,
	[GEB_DATUM_DATE] [date] NULL,
	[GESCHLECHT] [varchar](1) NULL,
	[GO_NR] [varchar](12) NULL,
	[GO_NR_ID] [varchar](30) NULL,
	[H2IK] [varchar](9) NULL,
	[HAUPTKASSEN_IK] [varchar](9) NULL,
	[JOINDATUM_ZEITRAUM] [date] NULL,
	[JOINDATUM_LEISTUNG] [date] NULL,
	[KASSEN_IK] [varchar](9) NULL,
	[KV] [varchar](2) NULL,
	[KV_KARTEN_HKIK] [varchar](9) NULL,
	[KV_KARTEN_IK] [varchar](9) NULL,
	[KV_NUMMER] [varchar](12) NULL,
	[KV_NUMMER_MA] [nvarchar](12) NULL,
	[LEISTUNGS_DATUM] [date] NULL,
	[LEISTUNGS_UHRZEIT] [varchar](4) NULL,
	[LETZTER_TAG] [date] NULL,
	[MINDERUNGSART] [varchar](2) NULL,
	[MINDERUNGSBETRAG] [money] NULL,
	[NACHRICHTENTYP] [varchar](6) NULL,
	[NAME] [varchar](45) NULL,
	[PRUEF_KZ] [varchar](1) NULL,
	[PUNKTZAHL_GONR] [money] NULL,
	[QUELL_REF] [int] NULL,
	[RECHTSKREIS] [varchar](1) NULL,
	[SACHKOSTEN] [money] NULL,
	[SACHKOSTEN_BEZ] [varchar](70) NULL,
	[STORNO_KNZ] [varchar](1) NULL,
	[UEBERWEISER_IK] [varchar](9) NULL,
	[VERARBEITUNGS_KNZ] [varchar](2) NULL,
	[VERSICHERTEN_STATUS] [varchar](1) NULL,
	[VERTRAGS_ID] [varchar](25) NULL,
	[VERTRAGSBEREICH] [varchar](2) NULL,
	[VORNAME] [varchar](45) NULL,
	[WERT_GONR] [money] NULL,
	[ZEITRAUM] [varchar](6) NULL,
	[ZEITRAUMTYP] [varchar](1) NULL,
	[K_MENSCH_ID] [int] NULL,
	[BESONDERE_PERS_GRP] [varchar](2) NULL,
	[DMP_KNZ] [varchar](2) NULL,
	[RECHNUNGS_NR] [varchar](20) NULL,
	[RECHNUNGS_DATUM] [varchar](8) NULL,
	[S_ABRECHNUNGSQUARTAL] [varchar](6) NULL
) ON [PRIMARY]
GO

CREATE TABLE [HZV].[Ansprechpartner_Kasse](
	[KassenIK] [varchar](9) NULL,
	[Vorname] [nvarchar](50) NULL,
	[Nachname] [nvarchar](50) NULL,
	[Anrede] [nvarchar](100) NULL,
	[Email] [nvarchar](100) NULL,
	[Personalkasse] [varchar](1) NULL,
	[Produkt] [varchar](100) NULL
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
) ON [PRIMARY]
GO

CREATE TABLE [HZV].[Berichte_Kundenportal](
	[KassenIK] [char](9) NULL,
	[KasseName] [varchar](100) NULL,
	[BereichId] [int] NULL,
	[Bereich] [varchar](50) NULL,
	[Berichtsbezeichnung] [varchar](100) NULL,
	[ReportRDL] [varchar](50) NULL
) ON [PRIMARY]
GO

CREATE TABLE [HZV].[Kassen](
	[Id] [int] NULL,
	[HauptKassenIK] [char](9) NULL,
	[KasseName] [varchar](100) NULL
) ON [PRIMARY]
GO

CREATE TABLE [HZV].[KM6](
	[Quartal] [varchar](5) NULL,
	[Kassen_IK] [varchar](9) NULL,
	[Kasse] [varchar](255) NULL,
	[KV] [varchar](2) NULL,
	[Geschlecht] [varchar](8) NULL,
	[Anzahl] [int] NULL
) ON [PRIMARY]
GO

CREATE TABLE [HZV].[Kosten](
	[Quartal_lang] [char](6) NOT NULL,
	[Quartal_kurz] [char](5) NOT NULL,
	[VertragsKV] [char](2) NOT NULL,
	[H2IK] [char](9) NOT NULL,
	[AnzTNM] [int] NOT NULL,
	[BtrABR] [decimal](12, 2) NOT NULL,
	[BtrBER] [decimal](12, 2) NOT NULL,
	[BtrNVI] [decimal](12, 2) NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [HZV].[LeistungsPositionen](
	[Leistung] [varchar](25) NOT NULL,
	[Leistung_Text] [varchar](250) NOT NULL,
	[VertragID] [int] NOT NULL,
	[GueltigVon] [date] NOT NULL,
	[GueltigBis] [date] NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [HZV].[NVI](
	[VertragsID] [nvarchar](11) NULL,
	[VertragsKV] [nvarchar](2) NULL,
	[WohnortKV] [nvarchar](2) NULL,
	[Quartal] [nchar](5) NULL,
	[SKUNDE] [nvarchar](9) NULL,
	[H2IK] [nvarchar](9) NULL,
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
	[BEHANDLUNGSDATUM] [date] NULL,
	[MENGE] [int] NULL,
	[BETRAG] [numeric](18, 2) NULL,
	[NVI_KNZ] [varchar](max) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
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

CREATE TABLE [HZV].[Steuerung](
	[Q_Dashboard_kurz] [nvarchar](5) NULL,
	[Q_Dashboard_lang] [nvarchar](6) NULL,
	[LastUpdate] [datetime2](7) NULL
) ON [PRIMARY]
GO

CREATE TABLE [HZV].[Teilnehmer_Aerzte](
	[VertragsID] [varchar](11) NULL,
	[VertragsKV] [varchar](2) NULL,
	[LANR7] [varchar](7) NULL,
	[LANR_FG] [varchar](2) NULL,
	[BSNR9] [varchar](9) NULL,
	[BSNR_GueltigVon] [date] NULL,
	[BSNR_GueltigBis] [date] NULL,
	[Anrede] [varchar](20) NULL,
	[Vorname] [varchar](35) NULL,
	[Nachname] [varchar](50) NULL,
	[StrasseHausNr] [varchar](70) NULL,
	[PLZ] [varchar](10) NULL,
	[Ort] [varchar](34) NULL,
	[TeilnahmeBeginn] [date] NULL,
	[TeilnahmeEnde] [date] NOT NULL,
	[Endegrund] [varchar](2) NULL,
	[EndeGrund_Text] [varchar](500) NULL,
	[AnzahlVersicherte] [int] NULL
) ON [PRIMARY]
GO

CREATE TABLE [HZV].[Teilnehmer_Map](
	[Quartal] [nvarchar](5) NOT NULL,
	[Vertrag] [nvarchar](25) NOT NULL,
	[AnzTNM] [int] NULL,
	[KV] [varchar](2) NULL,
	[HauptIK] [varchar](9) NOT NULL,
	[AnzVers] [int] NULL,
	[AnteilVers] [decimal](6, 3) NULL
) ON [PRIMARY]
GO

CREATE TABLE [HZV].[Teilnehmer_Pyramid](
	[Quartal] [nvarchar](5) NOT NULL,
	[Vertrag] [nvarchar](25) NOT NULL,
	[Geschlecht] [char](1) NULL,
	[AgeGroup] [varchar](5) NULL,
	[AgeGroupID] [int] NULL,
	[AnzTNM] [int] NULL,
	[KV] [varchar](2) NULL,
	[HauptIK] [varchar](9) NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [HZV].[Teilnehmer_Versicherte](
	[Vertrags_ID] [varchar](11) NULL,
	[VertragsKV] [varchar](2) NULL,
	[Quartal] [varchar](6) NULL,
	[sKunde] [varchar](9) NOT NULL,
	[H2IK] [varchar](9) NULL,
	[Kassen_IK] [varchar](9) NULL,
	[sVP] [varchar](22) NULL,
	[sMA] [varchar](2) NULL,
	[EGK_NR] [varchar](10) NULL,
	[KV_NUMMER] [varchar](12) NULL,
	[Vorname] [varchar](35) NULL,
	[Nachname] [varchar](50) NULL,
	[Geschlecht] [varchar](1) NULL,
	[Geburts_Datum] [date] NULL,
	[Altersgruppe] [varchar](5) NULL,
	[Teilnahme_Beginn] [date] NULL,
	[Teilnahme_Ende] [date] NULL,
	[Endegrund] [int] NULL,
	[Endegrund_Text] [varchar](400) NULL,
	[L_ARZT_NR] [varchar](7) NULL,
	[WohnortKV] [varchar](2) NULL
) ON [PRIMARY]
GO

CREATE TABLE [HZV].[Vertraege](
	[VertragsName] [varchar](255) NULL,
	[ID] [int] NOT NULL,
	[VertragsID] [varchar](25) NOT NULL,
	[VertragsKV] [char](2) NULL,
	[VertragBeginn] [date] NULL,
	[VertragEnde] [date] NULL,
	[HauptKassenIK] [char](9) NOT NULL,
	[KasseName] [varchar](255) NOT NULL,
	[Beitrittsquartal] [varchar](5) NOT NULL,
	[Dienstleistung] [varchar](70) NULL,
	[DienstleistungBeginn] [varchar](5) NOT NULL,
	[DienstleistungEnde] [varchar](5) NULL
) ON [PRIMARY]
GO