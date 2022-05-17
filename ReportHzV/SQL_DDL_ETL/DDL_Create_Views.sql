USE [AbrBV_Reporting_DEV]
GO

CREATE VIEW [HZV].[V_DB_Steuerung]
AS
SELECT        S.Q_Dashboard_kurz, S.Q_Dashboard_lang, S.LastUpdate, Q.Quartal_Beginn, Q.Quartal_Ende, Q.Quartal_Text_kurz, Q.Quartal_Text_lang
FROM            HZV.Steuerung AS S INNER JOIN
                         HZV.Quartale AS Q ON Q.Quartal_kurz = S.Q_Dashboard_kurz
GO


