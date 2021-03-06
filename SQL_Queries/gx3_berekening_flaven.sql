USE [D0136_00_Flaven]
GO
/****** Object:  StoredProcedure [dbo].[usp_XG3_Berekening]    Script Date: 10/02/2020 21:33:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Niet vergeten de basistabellen (dimTijd, tblmeny_import te indexeren !

--CREATE procedure [dbo].[usp_XG3_Berekening_Models]
--DECLARE
--@Meetpunt varchar(7), 
--@MinMetingen smallint, 
--@MaxReprPeriode smallint, 
--@GHG_Range int ,
--@GLG_Range int ,
--@GVG_Range int , 
--@MetHistoGram smallint = 0,
--@IsSilent smallint = 1

--AS
--BEGIN
SET NOCOUNT ON

DECLARE @meny_import nvarchar(30) = 'tblMeny_import'; --Hier de tabelnaam ingeven
DECLARE @SQL nvarchar(max);

DECLARE @Meetpunt varchar(7) ;--= ''VRIP028'';
DECLARE @MinMetingen smallint = 20 ;
DECLARE @MaxReprPeriode smallint = 40 ;
DECLARE @GHG_Range int = 14;
DECLARE @GLG_Range int = 14;
DECLARE @GVG_Range int = 14;
DECLARE @IsSilent smallint = 0;
DECLARE @MetHistoGram smallint = 0;


DECLARE @ReprHisto TABLE 
( Meetpunt varchar(7) NOT NULL
, simulatienr smallint NOT NULL
, Jaar smallint NOT NULL
, IsHydroJaar smallint NOT NULL 
, ReprPeriode real NOT NULL
, Nbr int NOT NULL
, ReprPeriodeCheck smallint NULL
, INDEX NC_1 NONCLUSTERED ( [Meetpunt], [simulatienr], [Jaar], [IsHydroJaar])
, INDEX NC_2 NONCLUSTERED ( ReprPeriode )
);


DECLARE @tmpFactMENYPeilMetingJaar TABLE
( 	[BRPeilMetingJaarWID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED ,
	[Meetpunt] [varchar](7) NOT NULL,
	[simulatienr] [smallint] NOT NULL,
	[Jaar] [smallint] NOT NULL,
	[IsHydroJaar] [smallint] NOT NULL,
	[EerstePeilMetingWID] [decimal](10, 2) NULL,
	[ReprPeriodeEerstePeilMeting] [decimal](10, 2) NULL,
	[LaatstePeilMetingWID] [decimal](10, 2) NULL,
	[ReprPeriodeLaatstePeilMeting] [decimal](10, 2) NULL,
	[BRResultaatWID] [decimal](10, 2) NULL,
	[hg3mTAWPeilMeting1] [decimal](10, 2) NULL,
	[hg3mTAWPeilMeting2] [decimal](10, 2) NULL,
	[hg3mTAWPeilMeting3] [decimal](10, 2) NULL,
	[hg3mTAWFout] [varchar](50) NULL,
	[hg3mMaaiVeldPeilMeting1] [decimal](10, 2) NULL,
	[hg3mMaaiVeldPeilMeting2] [decimal](10, 2) NULL,
	[hg3mMaaiVeldPeilMeting3] [decimal](10, 2) NULL,
	[hg3mMaaiveldFout] [varchar](50) NULL,
	[lg3mTAWPeilMeting1] [decimal](10, 2) NULL,
	[lg3mTAWPeilMeting2] [decimal](10, 2) NULL,
	[lg3mTAWPeilMeting3] [decimal](10, 2) NULL,
	[lg3mTAWFout] [varchar](50) NULL,
	[lg3mMaaiVeldPeilMeting1] [decimal](10, 2) NULL,
	[lg3mMaaiVeldPeilMeting2] [decimal](10, 2) NULL,
	[lg3mMaaiVeldPeilMeting3] [decimal](10, 2) NULL,
	[lg3mMaaiveldFout] [varchar](50) NULL,
	[vg3mTAWPeilMeting1] [decimal](10, 2) NULL,
	[vg3mTAWPeilMeting2] [decimal](10, 2) NULL,
	[vg3mTAWPeilMeting3] [decimal](10, 2) NULL,
	[vg3mTAWFout] [varchar](50) NULL,
	[vg3mMaaiVeldPeilMeting1] [decimal](10, 2) NULL,
	[vg3mMaaiVeldPeilMeting2] [decimal](10, 2) NULL,
	[vg3mMaaiVeldPeilMeting3] [decimal](10, 2) NULL,
	[vg3mMaaiveldFout] [varchar](50) NULL,
	[gg3mTAWPeilMeting] [decimal](10, 2) NULL,
	[gg3mTAWFout] [varchar](50) NULL,
	[gg3mMaaiveldPeilMeting] [decimal](10, 2) NULL,
	[gg3mMaaiveldFout] [varchar](50) NULL,
	[MinJmTAWPeilmeting] [decimal](10, 2) NULL,
	[MaxJmTAWPeilmeting] [decimal](10, 2) NULL,
	[MinJmMaaiveldPeilmeting] [decimal](10, 2) NULL,
	[MaxJmMaaiveldPeilmeting] [decimal](10, 2) NULL,
	ParamMinAantalMetingen smallint null,
	MaxRepresentatievePeriode smallint null,
	GHG_Range int null,
	GLG_Range int null,
	GVG_Range int null,
	GG_Range int null,
	RepresentatievePeriodeHistogram xml null
	INDEX NC_1 NONCLUSTERED ( [Meetpunt], [simulatienr], [IsHydroJaar], [Jaar])
)

DECLARE @XG3 TABLE 
( [Meetpunt] [nvarchar](7) NOT NULL
, [simulatienr] [smallint] NOT NULL
, [hydrojaar] [int] NOT NULL
, [IsmTaw] [bit] NOT NULL
--, [one_PeilMetingWID] [int] NULL
, [one_Datum] [datetime] NULL
--, [one_DatumKey] [int] NULL
, [one_Waarde] [decimal](18, 5) NULL
--, [two_PeilMetingWID] [int] NULL
, [two_Datum] [datetime] NULL
--, [two_DatumKey] [int] NULL
, [two_Waarde] [decimal](18, 5) NULL
--, [tree_PeilMetingWID] [int] NULL
, [tree_Datum] [datetime] NULL
--, [tree_DatumKey] [int] NULL
, [tree_Waarde] [decimal](18, 5) NULL
)
	
DECLARE @HandTypeWID int;
DECLARE @DiverTypeWID int;

--	SELECT @HandTypeWID = dMT.MetingTypeWID FROM dbo.DimMetingType dMT WHERE dMT.MetingTypeCode = 'HAND';
--	SELECT @DiverTypeWID = dMT.MetingTypeWID FROM dbo.DimMetingType dMT WHERE dMT.MetingTypeCode = 'DIVER';
DECLARE @SpreidingFout nvarchar(50)			= 'Metingen niet voldoende gespreid';


If @IsSilent = 0
Print 'Populeer FactTabel'

insert into @tmpFactMENYPeilMetingJaar (Meetpunt, simulatienr, Jaar, IsHydroJaar, EerstePeilMetingWID, ReprPeriodeEerstePeilMeting, LaatstePeilMetingWID, ReprPeriodeLaatstePeilMeting, BRResultaatWID, hg3mTAWPeilMeting1, hg3mTAWPeilMeting2, hg3mTAWPeilMeting3, hg3mTAWFout, hg3mMaaiVeldPeilMeting1, hg3mMaaiVeldPeilMeting2, hg3mMaaiVeldPeilMeting3, hg3mMaaiveldFout, lg3mTAWPeilMeting1, lg3mTAWPeilMeting2, lg3mTAWPeilMeting3, lg3mTAWFout, lg3mMaaiVeldPeilMeting1, lg3mMaaiVeldPeilMeting2, lg3mMaaiVeldPeilMeting3, lg3mMaaiveldFout, vg3mTAWPeilMeting1, vg3mTAWPeilMeting2, vg3mTAWPeilMeting3, vg3mTAWFout, vg3mMaaiVeldPeilMeting1, vg3mMaaiVeldPeilMeting2, vg3mMaaiVeldPeilMeting3, vg3mMaaiveldFout, gg3mTAWPeilMeting, gg3mTAWFout, gg3mMaaiveldPeilMeting, gg3mMaaiveldFout, MinJmTAWPeilmeting, MaxJmTAWPeilmeting, MinJmMaaiveldPeilmeting, MaxJmMaaiveldPeilmeting, ParamMinAantalMetingen, MaxRepresentatievePeriode, GHG_Range, GLG_Range, GVG_Range)
select * from [dbo].[FactMENYPeilMetingJaar_Flaven]

drop table if exists #tmpFactMENYPeilMetingJaar

select * 
into #tmpFactMENYPeilMetingJaar
from @tmpFactMENYPeilMetingJaar

CREATE NONCLUSTERED INDEX ix_tempxg3_flaven1 ON #tmpFactMENYPeilMetingJaar ([Meetpunt],[simulatienr], [IsHydroJaar], [Jaar])
CREATE UNIQUE INDEX ix_tempxg3_flaven_uniek ON #tmpFactMENYPeilMetingJaar ([BRPeilMetingJaarWID])

set @SQL = '	MERGE #tmpFactMENYPeilMetingJaar as trg
	USING (  SELECT DISTINCT Meetpunt
						, simulatienr
						, MeetJaar as Jaar
						, CASE WHEN TypeJaar = ''Jaar'' THEN 0 ELSE 1 END AS IsHydroJaar						
					FROM ( SELECT Distinct fPM.Meetpunt
									, fPM.simulatienr
									, dT.Jaar
									, dT.HydroJaar
								FROM ' + parsename(@meny_import, 1) +' fPM 
									INNER JOIN [dbo].[DimTijd] dT ON dT.Datum = fPM.dag
								WHERE 1=1
								--AND (fPM.meting_TAW IS NOT NULL OR fPM.mMaaiveld IS NOT NULL)
								' + iif (@Meetpunt IS NULL,'', 'AND (fPm.Meetpunt = '' + @Meetpunt +'')') +'
								AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
							) pv
					UNPIVOT ( MeetJaar FOR TypeJaar IN (Jaar, HydroJaar) 
					)as upv
				) src
	ON (src.Meetpunt = trg.Meetpunt 
	AND src.Jaar = trg.Jaar
	AND src.IsHydroJaar = trg.IsHydroJaar
	AND src.simulatienr = trg.simulatienr)
	WHEN MATCHED THEN UPDATE
		SET trg.[BRResultaatWID] = NULL
			, trg.hg3mTAWPeilMeting1 = NULL
			, trg.hg3mTAWPeilMeting2 = NULL
			, trg.hg3mTAWPeilMeting3 = NULL
			, trg.hg3mTAWFout = NULL
			, trg.hg3mMaaiVeldPeilMeting1 = NULL
			, trg.hg3mMaaiVeldPeilMeting2 = NULL
			, trg.hg3mMaaiVeldPeilMeting3 = NULL
			, trg.hg3mMaaiveldFout = NULL
			, trg.lg3mTAWPeilMeting1 = NULL
			, trg.lg3mTAWPeilMeting2 = NULL
			, trg.lg3mTAWPeilMeting3 = NULL
			, trg.lg3mTAWFout = NULL
			, trg.lg3mMaaiVeldPeilMeting1 = NULL
			, trg.lg3mMaaiVeldPeilMeting2 = NULL
			, trg.lg3mMaaiVeldPeilMeting3 = NULL
			, trg.lg3mMaaiveldFout = NULL
			, trg.vg3mTAWPeilMeting1 = NULL
			, trg.vg3mTAWPeilMeting2 = NULL
			, trg.vg3mTAWPeilMeting3 = NULL
			, trg.vg3mTAWFout = NULL
			, trg.vg3mMaaiVeldPeilMeting1 = NULL
			, trg.vg3mMaaiVeldPeilMeting2 = NULL
			, trg.vg3mMaaiVeldPeilMeting3 = NULL
			, trg.vg3mMaaiveldFout = NULL
			, trg.gg3mTAWPeilMeting = NULL
			, trg.gg3mTAWFout = NULL
			, trg.gg3mMaaiveldPeilMeting = NULL
			, trg.gg3mMaaiveldFout = NULL
			, trg.MinJmTAWPeilmeting = NULL
			, trg.MaxJmTAWPeilmeting = NULL
			, trg.MinJmMaaiveldPeilmeting = NULL
			, trg.MaxJmMaaiveldPeilmeting = NULL
			, trg.ParamMinAantalMetingen = ' + cast(@MinMetingen as nchar(2)) +'
			, trg.MaxRepresentatievePeriode = ' + cast(@MaxReprPeriode as nchar(3)) +'
			, trg.GHG_Range = ' + cast(@GHG_Range as nchar(2)) +'
			, trg.GLG_Range = ' + cast(@GLG_Range as nchar(2)) +'
			, trg.GVG_Range = ' + cast(@GVG_Range as nchar(2)) +'
	WHEN NOT MATCHED BY TARGET THEN 
		INSERT (Meetpunt, simulatienr, Jaar, IsHydroJaar, ParamMinAantalMetingen, MaxRepresentatievePeriode, GHG_Range, GLG_Range, GVG_Range)
		VALUES (src.Meetpunt, src.simulatienr, src.Jaar, src.IsHydroJaar, ' + cast(@MinMetingen as nchar(2)) +', ' + cast(@MaxReprPeriode as nchar(3)) +', ' + cast(@GHG_Range as nchar(2)) +', ' + cast(@GLG_Range as nchar(2)) +', ' + cast(@GVG_Range as nchar(2)) +')
	WHEN NOT MATCHED BY SOURCE THEN DELETE ;'

Exec( @SQL)

	--ALTER INDEX [IN_Switch_FactBRPeilMetingJaar_Jaarinfo] ON switch.FactBRPeilMetingJaar REBUILD;
	--UPDATE STATISTICS switch.FactBRPeilMetingJaar;

	--Eerste Peilmeting van het jaar
	If @IsSilent = 0
	PRINT 'Eerste Peilmeting van het jaar'
	MERGE #tmpFactMENYPeilMetingJaar as trg
	USING (	SELECT Detail.Meetpunt
					, Detail.simulatienr
					, Detail.IsHydroJaar
					, Detail.Jaar
					, Detail.meting_TAW											as EerstePeilMetingWID
					, DATEDIFF(dd, Detail.EersteDag, Detail.Datum) + (DATEDIFF(dd, Detail.Datum, Sec.Datum)/2.0) as ReprPeriodeEerstePeilMeting 
				FROM (SELECT BR.Meetpunt
								, BR.simulatienr
								, BR.Jaar
								, BR.IsHydroJaar
								, ROW_NUMBER() OVER (PARTITION BY BR.Meetpunt, BR.simulatienr, BR.IsHydroJaar, BR.Jaar ORDER BY fPM.dag ASC) as Nbrs
								, dT.Datum as Datum
								, fPM.dag
								, fPM.meting_TAW
								, CASE WHEN BR.IsHydroJaar = 1 THEN dT.HydroJaar_Eerste_Dag  
										WHEN BR.IsHydroJaar = 0 THEN dT.Jaar_Eerste_Dag
										ELSE NULL
										END as EersteDag
							FROM [dbo].[tblMeny_import] fPM
								INNER JOIN dbo.DimTijd dT ON dT.Datum = fPM.dag
								INNER JOIN #tmpFactMENYPeilMetingJaar BR ON BR.Meetpunt = fPM.Meetpunt
																						AND (( BR.IsHydroJaar = 1 AND dT.HydroJaar = BR.Jaar) 
																								OR (BR.IsHydroJaar = 0 AND dT.Jaar = BR.Jaar))
																						AND BR.simulatienr = fPM.simulatienr
								/*INNER JOIN dbo.FactBRPeilMetingJaar BR ON BR.Meetpunt = fPM.Meetpunt
																						AND (( BR.IsHydroJaar = 1 AND dT.HydroJaar = BR.Jaar) 
																								OR (BR.IsHydroJaar = 0 AND dT.Jaar = BR.Jaar))*/
							WHERE 1=1
							AND (fPm.Meetpunt = @Meetpunt OR @Meetpunt IS NULL)
							AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
							--AND (fPM.meting_TAW IS NOT NULL OR fPM.mMaaiveld IS NOT NULL)
							--AND fPM.PeilmetingCategorie IS NULL
						) Detail 
						INNER JOIN (SELECT BR.Meetpunt
								, BR.simulatienr
								, BR.Jaar
								, BR.IsHydroJaar
								, ROW_NUMBER() OVER (PARTITION BY BR.Meetpunt, BR.simulatienr, BR.IsHydroJaar, BR.Jaar ORDER BY fPM.dag ASC) as Nbrs
								, dT.Datum as Datum
								, fPM.dag
								, fPM.meting_TAW
								, CASE WHEN BR.IsHydroJaar = 1 THEN dT.HydroJaar_Eerste_Dag  
										WHEN BR.IsHydroJaar = 0 THEN dT.Jaar_Eerste_Dag
										ELSE NULL
										END as EersteDag
							FROM dbo.tblMeny_import fPM
								INNER JOIN dbo.DimTijd dT ON dT.Datum = fPM.dag
								INNER JOIN #tmpFactMENYPeilMetingJaar BR ON BR.Meetpunt = fPM.Meetpunt
																						AND (( BR.IsHydroJaar = 1 AND dT.HydroJaar = BR.Jaar) 
																								OR (BR.IsHydroJaar = 0 AND dT.Jaar = BR.Jaar))
																						AND BR.simulatienr = fPM.simulatienr
								/*INNER JOIN dbo.FactBRPeilMetingJaar BR ON BR.Meetpunt = fPM.Meetpunt
																						AND (( BR.IsHydroJaar = 1 AND dT.HydroJaar = BR.Jaar) 
																								OR (BR.IsHydroJaar = 0 AND dT.Jaar = BR.Jaar))*/
							WHERE 1=1
							AND (fPm.Meetpunt = @Meetpunt OR @Meetpunt IS NULL)
							AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)

							--AND fPM.PeilmetingCategorie IS NULL
							) sec ON sec.Meetpunt = Detail.Meetpunt
									AND sec.simulatienr = Detail.simulatienr
									AND sec.IsHydroJaar = Detail.IsHydroJaar
									AND sec.Jaar = Detail.Jaar
									AND sec.Nbrs = 2
									AND Detail.Nbrs = 1
				WHERE Detail.Nbrs = 1
				) as src
	ON src.Meetpunt = trg.Meetpunt
	AND src.simulatienr = trg.simulatienr
	AND src.IsHydroJaar = trg.IsHydroJaar
	AND src.Jaar = trg.Jaar
	WHEN MATCHED THEN UPDATE
		SET trg.EerstePeilMetingWID = src.EerstePeilMetingWID
		, trg.ReprPeriodeEerstePeilMeting = src.ReprPeriodeEerstePeilMeting ;

	--Laatste Peilmeting van het jaar
	If @IsSilent = 0
	PRINT 'Laatste Peilmeting van het jaar'
	MERGE #tmpFactMENYPeilMetingJaar as trg
	USING (	SELECT Detail.Meetpunt
					, Detail.simulatienr
					, Detail.IsHydroJaar
					, Detail.Jaar
					, Detail.meting_TAW											as LaatstePeilMetingWID
					, DATEDIFF(dd, Detail.Datum, Detail.LaatsteDag) + (DATEDIFF(dd, Sec.Datum, Detail.Datum)/2.0) as ReprPeriodeLaatstePeilMeting 
				FROM ( -- Eeste metingen van Jaar (of hydrojaar )
							SELECT BR.Meetpunt
								, BR.simulatienr
								, BR.Jaar
								, BR.IsHydroJaar
								, ROW_NUMBER() OVER (PARTITION BY BR.Meetpunt, BR.simulatienr, BR.IsHydroJaar, BR.Jaar ORDER BY fPM.dag DESC) as Nbrs
								, dT.Datum as Datum
								, fPM.dag
								, fPM.meting_TAW
								, CASE WHEN BR.IsHydroJaar = 1 THEN dT.HydroJaar_Laatste_Dag  
										WHEN BR.IsHydroJaar = 0 THEN dT.Jaar_Laatste_Dag
										ELSE NULL
										END as LaatsteDag
							FROM dbo.tblMeny_import fPM
								INNER JOIN dbo.DimTijd dT ON dT.Datum = fPM.dag
								INNER JOIN #tmpFactMENYPeilMetingJaar BR ON BR.Meetpunt = fPM.Meetpunt
																						AND (( BR.IsHydroJaar = 1 AND dT.HydroJaar = BR.Jaar) 
																								OR (BR.IsHydroJaar = 0 AND dT.Jaar = BR.Jaar))
																						AND BR.simulatienr = fPM.simulatienr
								/*INNER JOIN dbo.FactBRPeilMetingJaar BR ON BR.Meetpunt = fPM.Meetpunt
																						AND (( BR.IsHydroJaar = 1 AND dT.HydroJaar = BR.Jaar) 
																								OR (BR.IsHydroJaar = 0 AND dT.Jaar = BR.Jaar))*/
							WHERE 1=1
							AND (fPm.Meetpunt = @Meetpunt OR @Meetpunt IS NULL)
							AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
							--AND fPM.PeilmetingCategorie IS NULL
						) Detail 
						INNER JOIN (
							--Tweede meting van jaar of hydrojaar
							SELECT BR.Meetpunt
								, BR.simulatienr
								, BR.Jaar
								, BR.IsHydroJaar
								, ROW_NUMBER() OVER (PARTITION BY BR.Meetpunt, BR.simulatienr, BR.IsHydroJaar, BR.Jaar ORDER BY fPM.dag DESC) as Nbrs
								, dT.Datum as Datum
								, fPM.dag
								, fPM.meting_TAW
								, CASE WHEN BR.IsHydroJaar = 1 THEN dT.HydroJaar_Laatste_Dag  
										WHEN BR.IsHydroJaar = 0 THEN dT.Jaar_Laatste_Dag
										ELSE NULL
										END as LaatsteDag
							FROM dbo.tblMeny_import fPM
								INNER JOIN dbo.DimTijd dT ON dT.Datum = fPM.dag
								INNER JOIN #tmpFactMENYPeilMetingJaar BR ON BR.Meetpunt = fPM.Meetpunt
																						AND (( BR.IsHydroJaar = 1 AND dT.HydroJaar = BR.Jaar) 
																								OR (BR.IsHydroJaar = 0 AND dT.Jaar = BR.Jaar))
																						AND BR.simulatienr = fPM.simulatienr
								/*INNER JOIN dbo.FactBRPeilMetingJaar BR ON BR.Meetpunt = fPM.Meetpunt
																						AND (( BR.IsHydroJaar = 1 AND dT.HydroJaar = BR.Jaar) 
																								OR (BR.IsHydroJaar = 0 AND dT.Jaar = BR.Jaar))*/
							WHERE 1=1
							AND (fPm.Meetpunt = @Meetpunt OR @Meetpunt IS NULL)
							AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
							--AND fPM.PeilmetingCategorie IS NULL
						) Sec ON Sec.Meetpunt = Detail.Meetpunt
								AND sec.simulatienr = Detail.simulatienr
								AND Sec.IsHydroJaar =  Detail.IsHydroJaar
								AND Sec.Jaar = Detail.Jaar
								AND Sec.Nbrs = 2
								AND Detail.Nbrs = 1

				WHERE Detail.Nbrs = 1
				) as src
	ON src.Meetpunt = trg.Meetpunt
	AND src.simulatienr = trg.simulatienr
	AND src.IsHydroJaar = trg.IsHydroJaar
	AND src.Jaar = trg.Jaar
	WHEN MATCHED THEN UPDATE
		SET trg.LaatstePeilMetingWID = src.LaatstePeilMetingWID
		, trg.ReprPeriodeLaatstePeilMeting = src.ReprPeriodeLaatstePeilMeting ;



	/* Alle Jaren/hydroJaren die geen 20 metingen hebben => BR = 1 */
	If @IsSilent = 0
	Print 'Start Min 20 metingen hebben'
 
	UPDATE BRJu
		SET BRJu.BRResultaatWID = 1
	FROM #tmpFactMENYPeilMetingJaar BRJu 
		INNER JOIN (	SELECT BRJ.Meetpunt
								, BRJ.simulatienr
								, BRJ.Jaar
								, BRJ.IsHydroJaar
								, Count(Distinct fPM.dag) as cntr
							FROM #tmpFactMENYPeilMetingJaar BRJ 
								INNER JOIN dbo.tblMeny_import fPM ON fPM.Meetpunt = BRJ.Meetpunt AND BRJ.simulatienr = fPM.simulatienr
								INNER JOIN dbo.DimTijd dT ON dT.Datum = fPM.dag
																	AND BRJ.Jaar = CASE WHEN BRJ.IsHydroJaar = 1 THEN dT.HydroJaar ELSE dt.Jaar END  
							WHERE (fPm.Meetpunt = @Meetpunt OR @Meetpunt IS NULL) 
							AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
							--AND fPM.PeilmetingCategorie IS NULL
							--AND (fPM.meting_TAW IS NOT NULL OR fPM.mMaaiveld IS NOT NULL)
							--AND fPm.[PeilmetingStatusCode] NOT IN ('DEL', 'INV')
							GROUP BY BRJ.Meetpunt
								, BRJ.simulatienr
								, BRJ.Jaar
								, BRJ.IsHydroJaar
							HAVING Count(Distinct fPM.dag) < @MinMetingen
							) tmp ON tmp.Meetpunt = BRJu.Meetpunt
									AND tmp.simulatienr = BRJu.simulatienr
									AND tmp.Jaar = BRJu.Jaar
									AND tmp.IsHydroJaar = BRJu.IsHydroJaar;
	If @IsSilent = 0
	Print 'Einde Min 20 metingen hebben'


	/*geen metingen in Jan/april of dec/maart => BR = 2*/
	If @IsSilent = 0
	Print 'Start jan/April of dec/maart'
	UPDATE BRJu
		SET BRJu.BRResultaatWID = 2
	FROM #tmpFactMENYPeilMetingJaar BRJu 
	LEFT OUTER  JOIN (SELECT BRJ.Meetpunt
								, BRJ.simulatienr
								, BRJ.Jaar
								, BRJ.IsHydroJaar
								,  month(MIN(dT.Datum))  as Start
								,  month(MAX(dT.Datum)) as Einde 
						FROM #tmpFactMENYPeilMetingJaar BRJ 
								INNER JOIN dbo.tblMeny_import fPM ON fPM.Meetpunt = BRJ.Meetpunt AND BRJ.simulatienr = fPM.simulatienr
								INNER JOIN dbo.DimTijd dT ON dT.Datum = fPM.dag
															AND BRJ.Jaar = CASE WHEN BRJ.IsHydroJaar = 1 THEN dT.HydroJaar ELSE dt.Jaar END  
						WHERE (fPm.Meetpunt = @Meetpunt OR @Meetpunt IS NULL)
						AND BRJ.BRResultaatWID IS NULL
						AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
						--AND (fPM.meting_TAW IS NOT NULL OR fPM.mMaaiveld IS NOT NULL)
						--AND fPm.[PeilmetingStatusCode] NOT IN ('DEL', 'INV') 
						--AND fPM.PeilmetingCategorie IS NULL
						GROUP BY BRJ.Meetpunt
								, BRJ.simulatienr
								, BRJ.Jaar
								, BRJ.IsHydroJaar
						HAVING  ( BRJ.IsHydroJaar = 0 AND month(MIN(dT.Datum)) = 1 AND month(MAX(dT.Datum)) = 12 )OR ( BRJ.IsHydroJaar = 1 AND month(MIN(dT.Datum)) = 4 AND month(MAX(dT.Datum)) = 3 )
					) tmp ON tmp.Meetpunt = BRJu.Meetpunt
									AND tmp.simulatienr = BRJu.simulatienr
									AND tmp.Jaar = BRJu.Jaar
									AND tmp.IsHydroJaar = BRJu.IsHydroJaar
	WHERE BRJu.BRResultaatWID IS NULL
	AND tmp.Meetpunt IS NULL;
	If @IsSilent = 0
	PRINT 'Einde jan/April of dec/maart'


	/* Representatieve periode groter dan x dagen => BR = 3*/
	--If @IsSilent = 0
	--Print 'Start Representatieve periode groter dan x dagen'
	--UPDATE BRJu
	--	SET BRJu.BRResultaatWID = 3
	--FROM #tmpFactMENYPeilMetingJaar BRJu 
	--	INNER JOIN (SELECT BRJ.Meetpunt
	--									, BRJ.Jaar
	--									, BRJ.IsHydroJaar
	--									, MAX(CASE WHEN fPM.meting_TAW = BRJ.EerstePeilMetingWID THEN BRJ.ReprPeriodeEerstePeilMeting
	--													WHEN fPM.meting_TAW = BRJ.LaatstePeilMetingWID THEN BRJ.ReprPeriodeLaatstePeilMeting
	--													ELSE 1 END)  as Repr
	--							FROM #tmpFactMENYPeilMetingJaar BRJ 
	--									INNER JOIN dbo.tblMeny_import fPM ON fPM.Meetpunt = BRJ.Meetpunt
	--									INNER JOIN dbo.DimTijd dT ON dT.Datum = fPM.dag
	--																		AND BRJ.Jaar = dT.HydroJaar
	--																		AND BRJ.IsHydroJaar = 1
	--							WHERE (fPm.Meetpunt = @Meetpunt OR @Meetpunt IS NULL) 
	--							--AND fPM.PeilmetingCategorie IS NULL
	--							AND BRJ.BRResultaatWID IS NULL
	--							--AND fPm.[PeilmetingStatusCode] NOT IN ('DEL', 'INV')
	--							GROUP BY BRJ.Meetpunt
	--									, BRJ.Jaar
	--									, BRJ.IsHydroJaar
	--							HAVING MAX(ReprPeriode) > @MaxReprPeriode
	--				) tmp ON tmp.Meetpunt = BRJu.Meetpunt
	--								AND tmp.Jaar = BRJu.Jaar
	--								AND tmp.IsHydroJaar = BRJu.IsHydroJaar
	--WHERE BRJu.BRResultaatWID IS NULL

	--UPDATE BRJu
	--SET BRJu.BRResultaatWID = 3
	--FROM #tmpFactMENYPeilMetingJaar BRJu 
	--	INNER JOIN (SELECT BRJ.Meetpunt
	--									, BRJ.Jaar
	--									, BRJ.IsHydroJaar
	--									, MAX(CASE WHEN fPM.meting_TAW = BRJ.EerstePeilMetingWID THEN BRJ.ReprPeriodeEerstePeilMeting
	--													WHEN fPM.meting_TAW = BRJ.LaatstePeilMetingWID THEN BRJ.ReprPeriodeLaatstePeilMeting
	--													ELSE fPM.ReprPeriode END)  as Repr
	--							FROM #tmpFactMENYPeilMetingJaar BRJ 
	--									INNER JOIN dbo.tblMeny_import fPM ON fPM.Meetpunt = BRJ.Meetpunt
	--									INNER JOIN dbo.DimTijd dT ON dT.Datum = fPM.dag
	--																		AND BRJ.Jaar = dT.Jaar
	--																		AND BRJ.IsHydroJaar = 0
	--							WHERE fPm.[PeilmetingStatusCode] NOT IN ('DEL', 'INV') 
	--							AND fPM.PeilmetingCategorie IS NULL
	--							AND BRJ.BRResultaatWID IS NULL
	--							AND (fPm.Meetpunt = @Meetpunt OR @Meetpunt IS NULL)
	--							GROUP BY BRJ.Meetpunt
	--									, BRJ.Jaar
	--									, BRJ.IsHydroJaar
	--							HAVING MAX(ReprPeriode) > @MaxReprPeriode
	--				) tmp ON tmp.Meetpunt = BRJu.Meetpunt
	--								AND tmp.Jaar = BRJu.Jaar
	--								AND tmp.IsHydroJaar = BRJu.IsHydroJaar
	--WHERE BRJu.BRResultaatWID IS NULL


	If @IsSilent = 0
	PRINT 'Einde Representatieve periode groter dan x dagen'

	/*histogram maken van representatieve periodes*/
	--If @IsSilent = 0
	--PRINT 'Start Representatieve histogram maken'
	
	--If (@MetHistoGram = 1 )
	--BEGIN
	--INSERT @ReprHisto (MeetpuntWID, Jaar, IsHydroJaar, ReprPeriode, Nbr)
	--SELECT BRJ.Meetpunt
	--	, BRJ.Jaar
	--	, BRJ.IsHydroJaar 
	--	--, fPM.ReprPeriode
	--	, CASE WHEN fPM.meting_TAW = BRJ.EerstePeilMetingWID THEN BRJ.ReprPeriodeEerstePeilMeting 
	--		WHEN fPM.meting_TAW = BRJ.LaatstePeilMetingWID THEN BRJ.ReprPeriodeLaatstePeilMeting
	--		ELSE fpm.ReprPeriode END as ReprPeriode
	--	, Count(*) as Nbr

	--FROM #tmpFactMENYPeilMetingJaar BRJ
	--		INNER JOIN dbo.tblMeny_import fPM ON fPM.Meetpunt = BRJ.Meetpunt
	--		INNER JOIN dbo.DimTijd dT ON dT.Datum = fPM.dag
	--										AND BRJ.Jaar = CASE WHEN BRJ.IsHydroJaar = 1 THEN dT.HydroJaar ELSE dt.Jaar END  
	--GROUP BY BRJ.Meetpunt
	--	, BRJ.Jaar
	--	, BRJ.IsHydroJaar 
	--	, CASE WHEN fPM.meting_TAW = BRJ.EerstePeilMetingWID THEN BRJ.ReprPeriodeEerstePeilMeting 
	--		WHEN fPM.meting_TAW = BRJ.LaatstePeilMetingWID THEN BRJ.ReprPeriodeLaatstePeilMeting
	--		ELSE fpm.ReprPeriode END;
	
	----effectieve uitvoering van de controle
	--If @IsSilent = 0
	--PRINT 'Update representatieve histogram Criteria'
	--UPDATE rh
	--	SET rh.ReprPeriodeCheck = CASE WHEN rh.ReprPeriode > @MaxReprPeriode THEN 0 ELSE 1 END
	--FROM @ReprHisto rh;
	
	--If @IsSilent = 0
	--PRINT 'Update representatieve periode Criteria'
	--/*UPDATE BRJ
	--	SET BRJ.BRResultaatWID = CASE WHEN Ctrl.Jaar IS NOT NULL THEN 3 ELSE NULL END
	--FROM #tmpFactMENYPeilMetingJaar BRJ
	--INNER JOIN ( SELECT rh.Meetpunt
	--				, rh.Jaar
	--				, rh.IsHydroJaar
	--				, Count(*) as NbrFailedChecksReprPeriode
	--			FROM @ReprHisto rh
	--			WHERE rh.ReprPeriodeCheck = 0
	--			GROUP BY rh.Meetpunt
	--				, rh.Jaar
	--				, rh.IsHydroJaar
	--			) Ctrl ON Ctrl.Meetpunt = BRJ.Meetpunt
	--						AND Ctrl.Jaar = BRJ.Jaar
	--						AND Ctrl.IsHydroJaar = BRJ.IsHydroJaar
	--WHERE BRJ.BRResultaatWID IS NULL;
	--*/
	
	--UPDATE BRJ
	--	SET BRJ.RepresentatievePeriodeHistogram = Hist.Histo 
	--FROM #tmpFactMENYPeilMetingJaar BRJ
	--INNER JOIN (SELECT rh.Meetpunt 
	--				, rh.Jaar 
	--				, rh.IsHydroJaar 
	--				, CAST ( N'<Meetpunt WID="' + Convert(Nvarchar(100), rh.Meetpunt) + '" Jaar="' + CONVERT(Nvarchar(100), rh.Jaar) + '" IsHydroJaar="' + Convert(Nvarchar(100), rh.IsHydroJaar) + '">' + 
	--					dbo.Concatenate(0, N'<RepresentatievePeriodeInDagen Lengte="' + CONVERT(Nvarchar(4000), rh.ReprPeriode) + '" Frequentie="' + CONVERT(Nvarchar(4000), rh.Nbr ) + '" IsBinnenLimiet="' + CONVERT(Nvarchar(4000), rh.ReprPeriodeCheck ) + '"/>' + char(10) + char(13),'')  +
	--					N'</Meetpunt>' AS xml ) as Histo

	--			FROM @ReprHisto rh --with (index (NC_1)) 
	--			WHERE 1=1
	--			GROUP BY rh.Meetpunt  
	--				, rh.Jaar 
	--				, rh.IsHydroJaar 
	--			) Hist ON Hist.Meetpunt = BRJ.Meetpunt
	--				AND Hist.Jaar = BRJ.Jaar
	--				AND Hist.IsHydroJaar = BRJ.IsHydroJaar;
	--END
	----Cleanup histo
	--DELETE rh
	--FROM  @ReprHisto rh ;
	
	If @IsSilent = 0
	PRINT 'Einde Representatieve histogram maken & cleanup'
 

	/*All is well*/
	If @IsSilent = 0
	Print 'Start Alle OK Metingen aanduiden'

	UPDATE BRJu
		SET BRJu.BRResultaatWID = 0
	FROM #tmpFactMENYPeilMetingJaar BRJu 
	WHERE BRJu.BRResultaatWID IS NULL;
	
	If @IsSilent = 0
	Print 'Einde Alle OK Metingen aanduiden'
	
	If @IsSilent = 0
	PRINT 'Begin metingen opzoeken'
	

		
		If @IsSilent = 0
		PRINT 'BEGIN zoek alle eerste hg3 peilmetingen mTaw';
			INSERT INTO @XG3 (Meetpunt, simulatienr, hydrojaar, IsmTaW, one_Datum, one_Waarde )
			SELECT Meetpunt, simulatienr, HydroJaar, CONVERT(bit, 1) as mTaw, Datum, Waarde
			FROM ( SELECT dte.HydroJaar				as hydrojaar
						, fPM.Meetpunt			as Meetpunt
						, fPM.simulatienr		as simulatienr
						--, fPM.dag				as DatumKey
						, dte.Datum					as Datum
						--, fPM.meting_TAW			as PeilMetingWID
						, fPM.meting_TAW					as Waarde
						, ROW_NUMBER () OVER (PARTITION By dte.HydroJaar , fPM.Meetpunt, fPM.simulatienr ORDER BY fPM.meting_TAW Desc, fPM.dag ASC) AS [Nbr]
					FROM dbo.tblMeny_import  fPM --with (index (IN_Switch_tblMeny_import_GHG))
							INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
							INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
																		AND BRJ.simulatienr = fPM.simulatienr
																		AND BRJ.Jaar = dte.HydroJaar
																		AND BRJ.IsHydroJaar = 1
					WHERE fPM.meting_TAW IS NOT NULL
					--AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
					--AND fPM.[MetingTypeWID] IN (@HandTypeWID, @DiverTypeWID)
					AND BRJ.BRResultaatWID = 0
					--AND fPM.PeilmetingCategorieCode IS NULL
					AND (fPM.Meetpunt = @Meetpunt OR @Meetpunt IS NULL)
					AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
					)Eerste
			WHERE Eerste.Nbr = 1;
		If @IsSilent = 0
		PRINT 'EINDE zoek alle eerste hg3 peilmetingen mTaw';

		If @IsSilent = 0
		PRINT 'BEGIN zoek alle tweede hg3 peilmetingen mTaw';
			UPDATE t
			SET --t.two_DatumKey = Andere.DatumKey,
				t.two_Datum = Andere.Datum
				--, t.two_PeilMetingWID = Andere.meting_TAW
				, t.two_Waarde = Andere.Waarde
			FROM (SELECT dte.HydroJaar								as hydrojaar
					, fPM.Meetpunt								as Meetpunt
					, fPM.simulatienr							as simulatienr 
					--, fPM.dag									as DatumKey
					, dte.Datum										as Datum
					--, fPM.meting_TAW								as PeilMetingWID
					, fPM.meting_TAW										as [Waarde] 
					, ROW_NUMBER () OVER (PARTITION By dte.HydroJaar , fPM.Meetpunt, fPM.simulatienr ORDER BY fPM.meting_TAW DESC, fPM.dag ASC) AS [Nbr]
				FROM dbo.tblMeny_import  fPM --with (index (IN_Switch_tblMeny_import_GHG))
						INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
						INNER JOIN @XG3 GHG_mTaw ON GHG_mTaw.Meetpunt = fPM.Meetpunt
														AND GHG_mTaw.simulatienr = fPM.simulatienr
														AND GHG_mTaw.hydrojaar = dte.HydroJaar
														AND GHG_mTaw.IsmTaw = 1
						INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
																		AND BRJ.simulatienr = fPM.simulatienr
																		AND BRJ.Jaar = dte.HydroJaar
																		AND BRJ.IsHydroJaar = 1
				WHERE fPM.meting_TAW IS NOT NULL
				--AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
				--AND fPM.[MetingTypeWID] IN (@HandTypeWID, @DiverTypeWID)
				AND BRJ.BRResultaatWID = 0
				AND ( fPM.Meetpunt = @Meetpunt OR @Meetpunt IS NULL )
				AND Abs(DateDiff (dd,GHG_mTaw.one_Datum, dte.Datum)) >= @GHG_Range
				AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
				--AND GHG_mTaw.one_PeilMetingWID <> fPM.meting_TAW
				) Andere
				INNER JOIN @XG3 t ON t.Meetpunt = Andere.Meetpunt
												AND t.simulatienr = Andere.simulatienr
												AND t.hydrojaar = Andere.HydroJaar
												AND t.IsmTaw = 1
			WHERE Andere.Nbr = 1;
		If @IsSilent = 0
		PRINT 'EINDE zoek alle tweede hg3 peilmetingen mTaw';

		If @IsSilent = 0
		PRINT 'BEGIN zoek alle derde hg3 peilmetingen mTaw';
			UPDATE t 
			SET --t.tree_DatumKey = Andere.DatumKey,
				 t.tree_Datum = Andere.Datum
				--, t.tree_PeilMetingWID = Andere.meting_TAW
				, t.tree_Waarde = Andere.Waarde
			FROM (SELECT dte.HydroJaar							as hydrojaar
						, fPM.Meetpunt						as Meetpunt
						, fPM.simulatienr					as simulatienr
						--, fPM.dag							as DatumKey
						, dte.Datum								as Datum
						--, fPM.meting_TAW						as PeilMetingWID
						, fPM.meting_TAW								as Waarde
						, ROW_NUMBER () OVER (PARTITION By dte.HydroJaar , fPM.Meetpunt, fPM.simulatienr ORDER BY fPM.meting_TAW DESC, fPM.dag ASC) AS [Nbr]
					FROM dbo.tblMeny_import  fPM --with (index (IN_Switch_tblMeny_import_GHG))
							INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
							INNER JOIN @XG3 GHG_mTaw_one ON GHG_mTaw_one.Meetpunt = fPM.Meetpunt
																		AND GHG_mTaw_one.simulatienr = fPM.simulatienr
																		AND GHG_mTaw_one.hydrojaar = dte.HydroJaar
																		AND GHG_mTaw_one.IsmTaw = 1
							INNER JOIN @XG3 GHG_mTaw_two ON GHG_mTaw_two.Meetpunt = fPM.Meetpunt
																		AND GHG_mTaw_two.simulatienr = fPM.simulatienr
																		AND GHG_mTaw_two.hydrojaar = dte.HydroJaar
																		AND GHG_mTaw_two.IsmTaw = 1
							INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
																							AND BRJ.simulatienr = fPM.simulatienr
																							AND BRJ.Jaar = dte.HydroJaar
																							AND BRJ.IsHydroJaar = 1
					WHERE fPM.meting_TAW IS NOT NULL
					--AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
					--AND fPM.[MetingTypeWID] IN (@HandTypeWID, @DiverTypeWID)
					AND BRJ.BRResultaatWID = 0
					AND (fPM.Meetpunt = @Meetpunt OR @Meetpunt IS NULL )
					AND Abs(DateDiff (dd,GHG_mTaw_one.one_Datum, dte.Datum)) >= @GHG_Range
					AND Abs(DateDiff (dd,GHG_mTaw_two.two_Datum, dte.Datum)) >= @GHG_Range
					AND Abs(DateDiff (dd,GHG_mTaw_two.two_Datum, GHG_mTaw_one.one_Datum)) >= @GHG_Range
					AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
					--AND GHG_mTaw_one.one_PeilMetingWID <> fPM.meting_TAW
					--AND GHG_mTaw_two.two_PeilMetingWID <> fPM.meting_TAW
					) Andere
					INNER JOIN @XG3 t ON t.Meetpunt = Andere.Meetpunt
												AND t.simulatienr = Andere.simulatienr
												AND t.hydrojaar = Andere.HydroJaar
												AND t.IsmTaw = 1
				WHERE Andere.Nbr = 1;
		If @IsSilent = 0
		PRINT 'EINDE zoek alle derde hg3 peilmetingen mTaw';

		
		MERGE #tmpFactMENYPeilMetingJaar as trg
		USING (	SELECT t.[Meetpunt]
						, t.simulatienr
						, t.[hydrojaar]
						, ( t.one_Waarde + t.two_Waarde + t.tree_Waarde ) / 3.0 as [hg3_1]
						, t.one_Waarde		as PeilMeting1
						, t.two_Waarde		as PeilMeting2
						, t.tree_Waarde		as PeilMeting3
					FROM @XG3 t
					WHERE t.one_Waarde IS NOT NULL
					AND t.two_Waarde IS NOT NULL
					AND t.tree_Waarde IS NOT NULL
					AND t.IsmTaw = 1
					AND (t.Meetpunt = @Meetpunt OR @Meetpunt IS NULL )
					) src
			ON src.Meetpunt = trg.Meetpunt
			AND src.simulatienr = trg.simulatienr
			AND src.hydrojaar = trg.Jaar
			AND trg.IsHydroJaar = 1
		WHEN MATCHED THEN UPDATE
			SET trg.hg3mTAWPeilMeting1 = src.PeilMeting1
				, trg.hg3mTAWPeilMeting2 = src.PeilMeting2
				, trg.hg3mTAWPeilMeting3 = src.PeilMeting3
		WHEN NOT MATCHED BY SOURCE  THEN UPDATE
			SET trg.hg3mTAWPeilMeting1 = NULL
				, trg.hg3mTAWPeilMeting2 = NULL
				, trg.hg3mTAWPeilMeting3 = NULL ;
		If @IsSilent = 0
		PRINT 'EINDE Zoek Alle peilmetingen nodig voor hg3 mTAW HydroJaar';



		---Alle lege Records van een foutmelding voorzien
		If @IsSilent = 0
		PRINT 'BEGIN Alle lege records mTAW voorzien van foutboodschap HydroJaar';
		UPDATE BR
			SET BR.hg3mTAWFout = @SpreidingFout
		FROM #tmpFactMENYPeilMetingJaar BR
		WHERE 1=1
		AND (BR.hg3mTAWPeilMeting1 IS NULL 
			OR BR.hg3mTAWPeilMeting2 IS NULL
			OR BR.hg3mTAWPeilMeting3 IS NULL)
		AND ( BR.Meetpunt  = @Meetpunt OR @Meetpunt IS NULL )
		AND BR.IsHydroJaar = 1
		AND BR.BRResultaatWID = 0;
		If @IsSilent = 0
		PRINT 'EINDE Alle lege records mTAW voorzien van foutboodschap HydroJaar';

		DELETE g 
		FROM @XG3 g;



		If @IsSilent = 0
		PRINT 'BEGIN Zoek Alle peilmetingen nodig voor GHG mMaaiveld HydroJaar';
		If @IsSilent = 0
		PRINT 'BEGIN zoek alle eerste hg3 peilmetingen maaiveld';
		--INSERT INTO @XG3 (Meetpunt, hydrojaar, IsmTaW, one_Datum, one_Waarde )
		--SELECT MeetpuntWID, HydroJaar, CONVERT(bit, 0) as mTaw, Datum, Waarde
		--	FROM ( SELECT dte.HydroJaar					as hydrojaar
		--					, fPM.Meetpunt			as Meetpunt
		--					--, fPM.dag				as DatumKey
		--					, dte.Datum					as Datum
		--					, fPM.meting_TAW			as PeilMetingWID
		--					, fPM.mMaaiveld				as Waarde 
		--					, ROW_NUMBER () OVER (PARTITION By dte.HydroJaar , fPM.Meetpunt ORDER BY fPM.mMaaiveld Desc, fPM.dag ASC, fPM.[MetingTypeWID] ASC) AS [Nbr]
		--				FROM dbo.tblMeny_import  fPM --with (index (IN_Switch_tblMeny_import_GHG))
		--						INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
		--						INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
		--																						AND BRJ.Jaar = dte.HydroJaar
		--																						AND BRJ.IsHydroJaar = 1
		--				WHERE fPM.mMaaiveld IS NOT NULL
		--				AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
		--				AND fPM.[MetingTypeWID] IN (@HandTypeWID, @DiverTypeWID)
		--				AND BRJ.BRResultaatWID = 0
		--				AND fPM.PeilmetingCategorieCode IS NULL
		--				AND (fPM.Meetpunt = @Meetpunt OR @Meetpunt IS NULL )
		--				)Eerste
		--		WHERE Eerste.Nbr = 1;
	If @IsSilent = 0
	PRINT 'EINDE zoek alle eerste hg3 peilmetingen maaiveld';

	If @IsSilent = 0
	PRINT 'BEGIN zoek alle tweede hg3 peilmetingen maaiveld';
			--UPDATE t
			--SET t.two_DatumKey = Andere.DatumKey
			--	, t.two_Datum = Andere.Datum
			--	, t.two_PeilMetingWID = Andere.meting_TAW
			--	, t.two_Waarde = Andere.Waarde
			--FROM (SELECT dte.HydroJaar								as hydrojaar
			--			, fPM.Meetpunt							as MeetpuntWID
			--			, fPM.dag								as DatumKey
			--			, dte.Datum									as Datum
			--			, fPM.meting_TAW							as PeilMetingWID
			--			, fPM.mMaaiveld								as Waarde 
			--			, ROW_NUMBER () OVER (PARTITION By dte.HydroJaar , fPM.Meetpunt ORDER BY fPM.mMaaiveld DESC, fPM.dag ASC, fPM.[MetingTypeWID] ASC) AS [Nbr]
			--		FROM dbo.tblMeny_import  fPM --with (index (IN_Switch_tblMeny_import_GHG))
			--				INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
			--				INNER JOIN @XG3 GHG_mMaaiVeld ON GHG_mMaaiVeld.Meetpunt = fPM.Meetpunt
			--																AND GHG_mMaaiVeld.hydrojaar = dte.HydroJaar
			--																AND IsmTaw = 0
			--				INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
			--																				AND BRJ.Jaar = dte.HydroJaar
			--																				AND BRJ.IsHydroJaar = 1
			--		WHERE fPM.mMaaiveld IS NOT NULL
			--		AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
			--		AND fPM.[MetingTypeWID] IN (@HandTypeWID, @DiverTypeWID)
			--		AND BRJ.BRResultaatWID = 0
			--		AND (fPM.Meetpunt  = @Meetpunt OR @Meetpunt IS NULL )
			--		AND Abs(DateDiff (dd,GHG_mMaaiVeld.one_Datum, dte.Datum)) >= @GHG_Range
			--		AND GHG_mMaaiVeld.one_PeilMetingWID <> fPM.meting_TAW
			--		) Andere
			--		INNER JOIN @XG3 t ON t.Meetpunt = Andere.Meetpunt
			--									AND t.hydrojaar = Andere.HydroJaar
			--									AND t.IsmTaw = 0
			--WHERE Andere.Nbr = 1;
	If @IsSilent = 0
	PRINT 'EINDE zoek alle tweede hg3 peilmetingen maaiveld';

	If @IsSilent = 0
	PRINT 'BEGIN zoek alle derde hg3 peilmetingen maaiveld';
			--UPDATE t 
			--	SET t.tree_DatumKey = Andere.DatumKey
			--		, t.tree_Datum = Andere.Datum
			--		, t.tree_PeilMetingWID = Andere.meting_TAW
			--		, t.tree_Waarde = Andere.Waarde
			--	FROM (SELECT dte.HydroJaar										as hydrojaar
			--				, fPM.Meetpunt									as MeetpuntWID
			--				, fPM.dag										as DatumKey
			--				, dte.Datum											as Datum
			--				, fPM.meting_TAW									as PeilMetingWID
			--				, fPM.mMaaiveld										as Waarde
			--				, ROW_NUMBER () OVER (PARTITION By dte.HydroJaar , fPM.Meetpunt ORDER BY fPM.mMaaiveld DESC, fPM.dag ASC, fPM.[MetingTypeWID] ASC) AS [Nbr]
			--			FROM dbo.tblMeny_import  fPM --with (index (IN_Switch_tblMeny_import_GHG))
			--					INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
			--					INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
			--																					AND BRJ.Jaar = dte.HydroJaar
			--																					AND BRJ.IsHydroJaar = 1
			--																					AND BRJ.BRResultaatWID = 0
			--					INNER JOIN @XG3 GHG_mMaaiVeld_one ON GHG_mMaaiVeld_one.Meetpunt = fPM.Meetpunt
			--															AND GHG_mMaaiVeld_one.hydrojaar = dte.HydroJaar
			--															AND GHG_mMaaiVeld_one.IsmTaw = 0
			--					INNER JOIN @XG3 GHG_mMaaiVeld_two ON GHG_mMaaiVeld_two.Meetpunt = fPM.Meetpunt
			--															AND GHG_mMaaiVeld_two.hydrojaar = dte.HydroJaar
			--															AND GHG_mMaaiVeld_two.IsmTaw = 0
			--			WHERE fPM.mMaaiveld IS NOT NULL
			--			AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
			--			AND fPM.[MetingTypeWID] IN (@HandTypeWID, @DiverTypeWID)
			--			--AND BRJ.BRResultaatWID = 0
			--			AND (fPM.Meetpunt  = @Meetpunt OR @Meetpunt IS NULL)
			--			AND Abs(DateDiff (dd,GHG_mMaaiVeld_one.one_Datum, dte.Datum)) >= @GHG_Range
			--			AND Abs(DateDiff (dd,GHG_mMaaiVeld_two.two_Datum, dte.Datum)) >= @GHG_Range
			--			AND Abs(DateDiff (dd,GHG_mMaaiVeld_two.two_Datum, GHG_mMaaiVeld_one.one_Datum)) >= @GHG_Range
			--			AND GHG_mMaaiVeld_one.one_PeilMetingWID <> fPM.meting_TAW
			--			AND GHG_mMaaiVeld_two.two_PeilMetingWID <> fPM.meting_TAW
			--			) Andere
			--			INNER JOIN @XG3 t ON t.Meetpunt = Andere.Meetpunt
			--									AND t.hydrojaar = Andere.HydroJaar
			--									AND t.IsmTaw = 0
			--		WHERE Andere.Nbr = 1
		If @IsSilent = 0
		PRINT 'EINDE zoek alle derde GHG peilmetingen';
		
		If @IsSilent = 0
		PRINT 'BEGIN mMaaiveld peilmetingen toevoegen';
		--MERGE #tmpFactMENYPeilMetingJaar as trg
		--USING (	SELECT t.[MeetpuntWID]
		--				, t.[hydrojaar]
		--				, ( t.one_Waarde + t.two_Waarde + t.tree_Waarde ) / 3.0 as [GHG_1]
		--				, t.one_PeilMetingWID		as PeilMetingWID1
		--				, t.two_PeilMetingWID		as PeilMetingWID2
		--				, t.tree_PeilMetingWID		as PeilMetingWID3
		--			FROM @XG3 t
		--			WHERE t.one_PeilMetingWID IS NOT NULL
		--			AND t.two_PeilMetingWID IS NOT NULL
		--			AND t.tree_PeilMetingWID IS NOT NULL
		--			AND t.IsmTaw = 0
		--			) src
		--	ON src.Meetpunt = trg.Meetpunt
		--	AND src.hydrojaar = trg.Jaar
		--	AND trg.IsHydroJaar = 1
		--WHEN MATCHED THEN UPDATE
		--	SET trg.hg3mMaaiVeldPeilMeting1 = src.meting_TAW1
		--		, trg.hg3mMaaiVeldPeilMeting2 = src.meting_TAW2
		--		, trg.hg3mMaaiVeldPeilMeting3 = src.meting_TAW3
		--WHEN NOT MATCHED BY SOURCE THEN UPDATE
		--	SET trg.hg3mMaaiVeldPeilMeting1 = NULL
		--		, trg.hg3mMaaiVeldPeilMeting2 = NULL
		--		, trg.hg3mMaaiVeldPeilMeting3 = NULL;
		If @IsSilent = 0
		PRINT 'EINDE mMaaiveld peilmetingen toevoegen';
		If @IsSilent = 0
		PRINT 'EINDE Zoek Alle peilmetingen nodig voor GHG mMaaiveld HydroJaar';


	If @IsSilent = 0
	PRINT 'BEGIN Clear GHG temp results ';
	DELETE g FROM @XG3 g ;
	If @IsSilent = 0
	PRINT 'EINDE Clear GHG temp results ';


		---Alle lege Records van een foutmelding voorzien
		If @IsSilent = 0
		PRINT 'BEGIN Alle lege records mMaaiveld voorzien van foutboodschap HydroJaar';
		--UPDATE BR
		--	SET BR.hg3mMaaiveldFout = @SpreidingFout
		--FROM #tmpFactMENYPeilMetingJaar BR
		--WHERE 1=1
		--AND (BR.hg3mMaaiVeldPeilMeting1 IS NULL 
		--	OR BR.hg3mMaaiVeldPeilMeting2 IS NULL
		--	OR BR.hg3mMaaiVeldPeilMeting3 IS NULL)
		--AND (BR.Meetpunt  = @Meetpunt)
		--AND BR.IsHydroJaar = 1
		--AND BR.BRResultaatWID = 0;
		If @IsSilent = 0
		PRINT 'EINDE Alle lege records mMaaiveld voorzien van foutboodschap HydroJaar';


----------------------------------------------------------------------------------------------------------------------------------------------


	/*GLG van mTAW*/
	If @IsSilent = 0
	PRINT 'BEGIN Zoek Alle peilmetingen nodig voor lg3 mTAW HydroJaar';
	SET @SpreidingFout 			= 'Metingen niet voldoende gespreid';

	If @IsSilent = 0
	PRINT 'BEGIN Clear lg3 mtaw temp results';
	delete g from @XG3 g;
	If @IsSilent = 0
	PRINT 'EINDE Clear lg3 mtaw temp results';
		
		If @IsSilent = 0
		PRINT 'BEGIN zoek alle eerste lg3 peilmetingen';
			INSERT INTO @XG3 (Meetpunt, simulatienr, hydrojaar, IsmTaW, one_Datum, one_Waarde )
			SELECT Meetpunt, simulatienr, HydroJaar, CONVERT(bit, 1) as mTaw, Datum, Waarde
			FROM ( SELECT dte.HydroJaar						as hydrojaar
							, fPM.simulatienr
							, fPM.Meetpunt				as Meetpunt
							--, fPM.dag					as DatumKey
							, dte.Datum						as Datum
							--, fPM.meting_TAW				as PeilMetingWID
							, fPM.meting_TAW						as Waarde
							, ROW_NUMBER () OVER (PARTITION By dte.HydroJaar , fPM.Meetpunt, fPM.simulatienr ORDER BY fPM.meting_TAW ASC, fPM.dag ASC) AS [Nbr]
							, 'one' as dbg
						FROM dbo.tblMeny_import  fPM --with (index (IN_Switch_tblMeny_import_GLG))
								INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
								INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
																								AND BRJ.simulatienr = fPM.simulatienr
																								AND BRJ.Jaar = dte.HydroJaar
																								AND BRJ.IsHydroJaar = 1
						WHERE fPM.meting_TAW IS NOT NULL
						--AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
						--AND fPM.[MetingTypeWID] IN (@HandTypeWID, @DiverTypeWID)
						AND BRJ.BRResultaatWID = 0
						--AND fPM.PeilmetingCategorieCode IS NULL
						AND (fPM.Meetpunt  = @Meetpunt OR @Meetpunt IS NULL)
						AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
						)Eerste
				WHERE Eerste.Nbr = 1;
		If @IsSilent = 0
		PRINT 'EINDE zoek alle eerste lg3 peilmetingen';

		If @IsSilent = 0
		PRINT 'BEGIN zoek alle tweede lg3 peilmetingen';
			UPDATE t
			SET --t.two_DatumKey = Andere.DatumKey,
				 t.two_Datum = Andere.Datum
				--, t.two_PeilMetingWID = Andere.meting_TAW
				, t.two_Waarde = Andere.Waarde
				FROM (SELECT dte.HydroJaar									as hydrojaar
							, fPM.simulatienr							as simulatienr
							, fPM.Meetpunt								as Meetpunt
							--, fPM.dag									as DatumKey
							, dte.Datum										as Datum
							--, fPM.meting_TAW								as PeilMetingWID
							, fPM.meting_TAW										as Waarde
							, ROW_NUMBER () OVER (PARTITION By dte.HydroJaar , fPM.Meetpunt, fPM.simulatienr ORDER BY fPM.meting_TAW ASC, fPM.dag ASC) AS [Nbr]
						FROM dbo.tblMeny_import fPM --with (index (IN_Switch_tblMeny_import_GLG))
								INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
								INNER JOIN @XG3 GLG_mTaw ON GLG_mTaw.Meetpunt = fPM.Meetpunt
														AND GLG_mTaw.simulatienr = fPM.simulatienr
														AND GLG_mTaw.hydrojaar = dte.HydroJaar
														AND GLG_mTaw.IsmTaw = 1
								--INNER JOIN GLG_mTaw_one ON GLG_mTaw_one.Meetpunt = fPM.Meetpunt
								--										AND GLG_mTaw_one.hydrojaar = dte.HydroJaar
								INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
																		AND BRJ.simulatienr = fPM.simulatienr
																		AND BRJ.Jaar = dte.HydroJaar
																		AND BRJ.IsHydroJaar = 1
						WHERE fPM.meting_TAW IS NOT NULL
						--AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
						--AND fPM.[MetingTypeWID] IN (@HandTypeWID, @DiverTypeWID)
						AND BRJ.BRResultaatWID = 0
						AND (fPM.Meetpunt  = @Meetpunt OR @Meetpunt IS NULL )
						AND Abs(DateDiff (dd,GLG_mTaw.one_Datum, dte.Datum)) >= @GLG_Range
						AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
						--AND GLG_mTaw.one_PeilMetingWID <> fPM.meting_TAW
						) Andere
						INNER JOIN @XG3 t ON t.Meetpunt = Andere.Meetpunt
												AND t.simulatienr =  Andere.simulatienr
												AND t.hydrojaar = Andere.HydroJaar
												AND t.IsmTaw = 1
					WHERE Andere.Nbr = 1;
		If @IsSilent = 0
		PRINT 'EINDE zoek alle tweede lg3 peilmetingen';

		If @IsSilent = 0
		PRINT 'BEGIN zoek alle derde lg3 peilmetingen';
			UPDATE t 
			SET --t.tree_DatumKey = Andere.DatumKey,
				 t.tree_Datum = Andere.Datum
				--, t.tree_PeilMetingWID = Andere.meting_TAW
				, t.tree_Waarde = Andere.Waarde
				FROM (SELECT dte.HydroJaar								as hydrojaar
							, fPM.simulatienr						as simulatienr
							, fPM.Meetpunt							as Meetpunt
							--, fPM.dag								as DatumKey
							, dte.Datum									as Datum
							--, fPM.meting_TAW							as PeilMetingWID
							, fPM.meting_TAW									as Waarde
							, ROW_NUMBER () OVER (PARTITION By dte.HydroJaar , fPM.Meetpunt, fPM.simulatienr ORDER BY fPM.meting_TAW ASC, fPM.dag ASC) AS [Nbr]
						FROM dbo.tblMeny_import fPM --with (index (IN_Switch_tblMeny_import_GLG))
								INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
								INNER JOIN @XG3 GLG_mTaw_one ON GLG_mTaw_one.Meetpunt = fPM.Meetpunt
																		AND GLG_mTaw_one.simulatienr = fPM.simulatienr
																		AND GLG_mTaw_one.hydrojaar = dte.HydroJaar
																		AND GLG_mTaw_one.IsmTaw = 1
								INNER JOIN @XG3 GLG_mTaw_two ON GLG_mTaw_two.Meetpunt = fPM.Meetpunt
																		AND GLG_mTaw_two.simulatienr = fPM.simulatienr
																		AND GLG_mTaw_two.hydrojaar = dte.HydroJaar
																		AND GLG_mTaw_two.IsmTaw = 1
								INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
																								AND BRJ.simulatienr = fPM.simulatienr
																								AND BRJ.Jaar = dte.HydroJaar
																								AND BRJ.IsHydroJaar = 1
						WHERE fPM.meting_TAW IS NOT NULL
						--AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
						--AND fPM.[MetingTypeWID] IN (@HandTypeWID, @DiverTypeWID)
						AND BRJ.BRResultaatWID = 0
						AND (fPM.Meetpunt  = @Meetpunt OR @Meetpunt IS NULL )
						AND Abs(DateDiff (dd,GLG_mTaw_one.one_Datum, dte.Datum)) >= @GLG_Range
						AND Abs(DateDiff (dd,GLG_mTaw_two.two_Datum, dte.Datum)) >= @GLG_Range
						AND Abs(DateDiff (dd,GLG_mTaw_two.two_Datum, GLG_mTaw_one.one_Datum)) >= @GLG_Range
						AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
						--AND GLG_mTaw_one.one_PeilMetingWID <> fPM.meting_TAW
						--AND GLG_mTaw_two.two_PeilMetingWID <> fPM.meting_TAW
						) Andere
						INNER JOIN @XG3 t ON t.Meetpunt = Andere.Meetpunt
												AND t.simulatienr = Andere.simulatienr
												AND t.hydrojaar = Andere.HydroJaar
												AND t.IsmTaw = 1
					WHERE Andere.Nbr = 1;
		If @IsSilent = 0
		PRINT 'EINDE zoek alle derde lg3 peilmetingen';

		MERGE #tmpFactMENYPeilMetingJaar as trg
		USING (	SELECT t.[Meetpunt]
						, t.simulatienr
						, t.[hydrojaar]
						, ( t.one_Waarde + t.two_Waarde + t.tree_Waarde ) / 3.0 as [lg3_1]
						, t.one_Waarde		as PeilMeting1
						, t.two_Waarde		as PeilMeting2
						, t.tree_Waarde		as PeilMeting3
					FROM @XG3 t
					WHERE t.one_Waarde IS NOT NULL
					AND t.two_Waarde IS NOT NULL
					AND t.tree_Waarde IS NOT NULL
					AND t.IsmTaw = 1
					) src
			ON src.Meetpunt = trg.Meetpunt
			AND src.simulatienr = trg.simulatienr
			AND src.hydrojaar = trg.Jaar
			AND trg.IsHydroJaar = 1
		WHEN MATCHED THEN UPDATE
			SET trg.lg3mTAWPeilMeting1 = src.PeilMeting1
				, trg.lg3mTAWPeilMeting2 = src.PeilMeting2
				, trg.lg3mTAWPeilMeting3 = src.PeilMeting3
		WHEN NOT MATCHED BY SOURCE THEN UPDATE
			SET trg.lg3mTAWPeilMeting1 = NULL
				, trg.lg3mTAWPeilMeting2 = NULL
				, trg.lg3mTAWPeilMeting3 = NULL ;
		If @IsSilent = 0
		PRINT 'EINDE Zoek Alle peilmetingen nodig voor lg3 mTAW HydroJaar';

		---Alle lege Records van een foutmelding voorzien
		If @IsSilent = 0
		PRINT 'BEGIN Alle lege records mTAW voorzien van foutboodschap HydroJaar';
		UPDATE BR
			SET BR.lg3mTAWFout = @SpreidingFout
		FROM #tmpFactMENYPeilMetingJaar BR
		WHERE 1=1
		AND (BR.lg3mTAWPeilMeting1 IS NULL 
			OR BR.lg3mTAWPeilMeting2 IS NULL
			OR BR.lg3mTAWPeilMeting3 IS NULL)
		AND (BR.Meetpunt  = @Meetpunt OR @Meetpunt IS NULL)
		AND BR.IsHydroJaar = 1
		AND BR.BRResultaatWID = 0;
		If @IsSilent = 0
		PRINT 'EINDE Alle lege records mTAW voorzien van foutboodschap HydroJaar';

	----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	/*GLG van mMaaiveld*/
		If @IsSilent = 0
		PRINT 'BEGIN Clear lg3 temp results mMaaiveld';
	DELETE g FROM @XG3 g;
	If @IsSilent = 0
	PRINT 'EINDE Clear lg3 temp results mMaaiveld';
		
		If @IsSilent = 0
		PRINT 'BEGIN Zoek Alle peilmetingen nodig voor lg3 mMaaiveld HydroJaar';
		If @IsSilent = 0
		PRINT 'BEGIN zoek alle eerste lg3 peilmetingen mMaaiveld';
		--INSERT INTO @XG3 (MeetpuntWID, hydrojaar, IsmTaW, one_DatumKey, one_Datum, one_PeilMetingWID, one_Waarde )
		--SELECT MeetpuntWID, HydroJaar, CONVERT(bit, 0) as mTaw, DatumKey, Datum, PeilMetingWID, Waarde
		--FROM ( SELECT dte.HydroJaar			as [hydrojaar]
		--				, fPM.Meetpunt 
		--				, fPM.dag					as DatumKey
		--				, dte.Datum					as Datum
		--				, fPM.meting_TAW
		--				, fPM.mMaaiveld as [Waarde] 
		--				, ROW_NUMBER () OVER (PARTITION By dte.HydroJaar , fPM.Meetpunt ORDER BY fPM.mMaaiveld ASC, fPM.dag ASC,fPM.[MetingTypeWID] ASC) AS [Nbr]
		--				, 'one' as dbg
		--			FROM dbo.tblMeny_import fPM --with (index (IN_Switch_tblMeny_import_GLG))
		--					INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
		--					INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
		--																					AND BRJ.Jaar = dte.HydroJaar
		--																					AND BRJ.IsHydroJaar = 1
		--			WHERE fPM.mMaaiveld IS NOT NULL
		--			AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
		--			AND fPM.[MetingTypeWID] IN (@HandTypeWID, @DiverTypeWID)
		--			AND BRJ.BRResultaatWID = 0
		--			AND fPM.PeilmetingCategorieCode IS NULL
		--			AND (fPM.Meetpunt  = @Meetpunt OR @Meetpunt IS NULL)
		--			)Eerste
		--	WHERE Eerste.Nbr = 1;
		If @IsSilent = 0
		PRINT 'EINDE zoek alle eerste lg3 peilmetingen mMaaiveld';

		If @IsSilent = 0
		PRINT 'BEGIN zoek alle tweede lg3 peilmetingen mMaaiveld';
			--UPDATE t
			--SET t.two_DatumKey = Andere.DatumKey
			--	, t.two_Datum = Andere.Datum
			--	, t.two_PeilMetingWID = Andere.meting_TAW
			--	, t.two_Waarde = Andere.Waarde
			--	FROM (SELECT dte.HydroJaar									as hydrojaar
			--				, fPM.Meetpunt								as MeetpuntWID
			--				, fPM.dag									as DatumKey
			--				, dte.Datum										as Datum
			--				, fPM.meting_TAW								as PeilMetingWID
			--				, fPM.mMaaiveld									as Waarde
			--				, ROW_NUMBER () OVER (PARTITION By dte.HydroJaar , fPM.Meetpunt ORDER BY fPM.mMaaiveld ASC, fPM.dag ASC,fPM.[MetingTypeWID] ASC) AS [Nbr]
			--			FROM dbo.tblMeny_import fPM --with (index (IN_Switch_tblMeny_import_GLG))
			--					INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
			--					INNER JOIN @XG3 GLG_mMaaiveld ON GLG_mMaaiveld.Meetpunt = fPM.Meetpunt
			--																	AND GLG_mMaaiveld.hydrojaar = dte.HydroJaar
			--																	AND GLG_mMaaiveld.IsmTaw = 0
			--					INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
			--																	AND BRJ.Jaar = dte.HydroJaar
			--																	AND BRJ.IsHydroJaar = 1
			--			WHERE fPM.mMaaiveld IS NOT NULL
			--			AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
			--			AND fPM.[MetingTypeWID] IN (@HandTypeWID, @DiverTypeWID)
			--			AND BRJ.BRResultaatWID = 0
			--			AND (fPM.Meetpunt  = @Meetpunt OR @Meetpunt IS NULL )
			--			AND Abs(DateDiff (dd,GLG_mMaaiveld.one_Datum, dte.Datum)) >= @GLG_Range
			--			AND GLG_mMaaiveld.one_PeilMetingWID <> fPM.meting_TAW
			--			) Andere
			--			INNER JOIN @XG3 t ON t.Meetpunt = Andere.Meetpunt
			--									AND t.hydrojaar = Andere.HydroJaar
			--									AND t.IsmTaw = 0
			--WHERE Andere.Nbr = 1;
		If @IsSilent = 0
		PRINT 'EINDE zoek alle tweede lg3 peilmetingen mMaaiveld';

		If @IsSilent = 0
		PRINT 'BEGIN zoek alle derde lg3 peilmetingen mMaaiveld';
			--UPDATE t 
			--	SET t.tree_DatumKey = Andere.DatumKey
			--		, t.tree_Datum = Andere.Datum
			--		, t.tree_PeilMetingWID = Andere.meting_TAW
			--		, t.tree_Waarde = Andere.Waarde
			--	FROM (SELECT dte.HydroJaar									as hydrojaar
			--				, fPM.Meetpunt								as MeetpuntWID
			--				, fPM.dag									as DatumKey
			--				, dte.Datum										as Datum
			--				, fPM.meting_TAW								as PeilMetingWID
			--				, fPM.mMaaiveld									as Waarde
			--				, ROW_NUMBER () OVER (PARTITION By dte.HydroJaar , fPM.Meetpunt ORDER BY fPM.mMaaiveld ASC, fPM.dag ASC,fPM.[MetingTypeWID] ASC) AS [Nbr]
			--			FROM dbo.tblMeny_import fPM --with (index (IN_Switch_tblMeny_import_GLG))
			--					INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
			--					INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
			--															AND BRJ.Jaar = dte.HydroJaar
			--															AND BRJ.IsHydroJaar = 1
			--					INNER JOIN @XG3 GLG_mMaaiveld_one ON GLG_mMaaiveld_one.Meetpunt = fPM.Meetpunt
			--															AND GLG_mMaaiveld_one.hydrojaar = dte.HydroJaar
			--															AND GLG_mMaaiveld_one.IsmTaw = 0
			--					INNER JOIN @XG3 GLG_mMaaiveld_two ON GLG_mMaaiveld_two.Meetpunt = fPM.Meetpunt
			--															AND GLG_mMaaiveld_two.hydrojaar = dte.HydroJaar
			--															AND GLG_mMaaiveld_two.IsmTaw = 0
			--			WHERE fPM.mMaaiveld IS NOT NULL
			--			AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
			--			AND fPM.[MetingTypeWID] IN (@HandTypeWID, @DiverTypeWID)
			--			AND BRJ.BRResultaatWID = 0
			--			AND (fPM.Meetpunt  = @Meetpunt OR @Meetpunt IS NULL)
			--			AND Abs(DateDiff (dd,GLG_mMaaiveld_one.one_Datum, dte.Datum)) >= @GLG_Range
			--			AND Abs(DateDiff (dd,GLG_mMaaiveld_two.two_Datum, dte.Datum)) >= @GLG_Range
			--			AND Abs(DateDiff (dd,GLG_mMaaiveld_two.two_Datum, GLG_mMaaiveld_one.one_Datum)) >= @GLG_Range
			--			AND GLG_mMaaiveld_one.one_PeilMetingWID <> fPM.meting_TAW
			--			AND GLG_mMaaiveld_two.two_PeilMetingWID <> fPM.meting_TAW
			--			) Andere
			--			INNER JOIN @XG3 t ON t.Meetpunt = Andere.Meetpunt
			--							AND t.hydrojaar = Andere.HydroJaar
			--							AND t.IsmTaw = 0
			--		WHERE Andere.Nbr = 1;
		If @IsSilent = 0
		PRINT 'EINDE zoek alle derde lg3 peilmetingen mMaaiveld';
		
		If @IsSilent = 0
		PRINT 'BEGIN mMaaiveld peilmetingen toevoegen';
		--MERGE #tmpFactMENYPeilMetingJaar as trg
		--USING (		SELECT t.[MeetpuntWID]
		--				, t.[hydrojaar]
		--				, ( t.one_Waarde + t.two_Waarde + t.tree_Waarde ) / 3 as [GHG_1]
		--				, t.one_PeilMetingWID		as PeilMetingWID1
		--				, t.two_PeilMetingWID		as PeilMetingWID2
		--				, t.tree_PeilMetingWID		as PeilMetingWID3
		--			FROM @XG3 t
		--			WHERE t.one_PeilMetingWID IS NOT NULL
		--			AND t.two_PeilMetingWID IS NOT NULL
		--			AND t.tree_PeilMetingWID IS NOT NULL
		--			AND t.IsmTaw = 0
		--			) src
		--	ON src.Meetpunt = trg.Meetpunt
		--	AND src.hydrojaar = trg.Jaar
		--	AND trg.IsHydroJaar = 1
		--WHEN MATCHED THEN UPDATE
		--	SET trg.lg3mMaaiVeldPeilMeting1 = src.meting_TAW1
		--		, trg.lg3mMaaiVeldPeilMeting2 = src.meting_TAW2
		--		, trg.lg3mMaaiVeldPeilMeting3 = src.meting_TAW3
		--WHEN NOT MATCHED BY SOURCE THEN UPDATE
		--	SET trg.lg3mMaaiVeldPeilMeting1 = NULL
		--		, trg.lg3mMaaiVeldPeilMeting2 = NULL
		--		, trg.lg3mMaaiVeldPeilMeting3 = NULL;
		If @IsSilent = 0
		PRINT 'EINDE mMaaiveld peilmetingen toevoegen';
		If @IsSilent = 0
		PRINT 'EINDE Zoek Alle peilmetingen nodig voor lg3 mMaaiveld HydroJaar';

	If @IsSilent = 0
	PRINT 'BEGIN Clear lg3 temp results ';
	DELETE g FROM @XG3 g;
	If @IsSilent = 0
	PRINT 'EINDE Clear lg3 temp results ';


		---Alle lege Records van een foutmelding voorzien
		If @IsSilent = 0
		PRINT 'BEGIN Alle lege records mMaaiveld voorzien van foutboodschap HydroJaar';
		--UPDATE BR
		--	SET BR.lg3mMaaiveldFout = @SpreidingFout
		--FROM #tmpFactMENYPeilMetingJaar BR
		--WHERE 1=1
		--AND (BR.lg3mMaaiVeldPeilMeting1 IS NULL 
		--	OR BR.lg3mMaaiVeldPeilMeting2 IS NULL
		--	OR BR.lg3mMaaiVeldPeilMeting3 IS NULL)
		--AND BR.IsHydroJaar = 1
		--AND BR.BRResultaatWID = 0;
		If @IsSilent = 0
		PRINT 'EINDE Alle lege records mMaaiveld voorzien van foutboodschap HydroJaar';

-----------------------------------------------------------------------------------------------------------------------------------------------------

	DECLARE @GegevenstekortFout nvarchar(50)	= 'Geen 3 metingen tussen 1 maart en 31 mei';
	SET @SpreidingFout = 'Metingen niet voldoende gespreid';

	If @IsSilent = 0
	PRINT 'BEGIN vg3 mTAW'
	--Minstens 3 metingen tussen xxxx-03-01 en xxxx-05-31
	If @IsSilent = 0
	PRINT 'BEGIN Minstens 3 metingen tussen xxxx-03-01 en xxxx-05-31'
	UPDATE BRu 
	SET BRu.vg3mTAWFout = @GegevenstekortFout
	FROM #tmpFactMENYPeilMetingJaar BRu 
		LEFT OUTER JOIN (	SELECT BR.Meetpunt
										, BR.simulatienr
										, BR.Jaar
										, Count(*) as Nbr
									FROM #tmpFactMENYPeilMetingJaar BR 
										INNER JOIN dbo.tblMeny_import fPM ON fPM.Meetpunt = BR.Meetpunt AND fPM.simulatienr = BR.simulatienr
										INNER JOIN dbo.DimTijd dT ON dT.Datum = fPM.dag
																AND dT.Maand_Nummer IN (3,4,5) AND dT.Jaar = BR.Jaar
									WHERE 1=1
									AND fPM.meting_TAW IS NOT NULL
									--AND fPM.MetingTypeWID  IN (@HandTypeWID, @DiverTypeWID)
									AND (fPM.Meetpunt  = @Meetpunt OR @Meetpunt IS NULL )
									AND BR.IsHydroJaar = 0
									AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
									GROUP BY BR.Meetpunt
										, BR.simulatienr
										, BR.Jaar
									HAVING Count(*) >= 3
							) Detail ON Detail.Meetpunt = BRu.Meetpunt
									AND Detail.simulatienr = BRu.simulatienr
									AND Detail.Jaar = BRu.Jaar
	WHERE Detail.Meetpunt IS NULL
	AND (BRu.Meetpunt = @Meetpunt OR @Meetpunt IS NULL );
	If @IsSilent = 0
	PRINT 'EINDE Minstens 3 metingen tussen xxxx-03-01 en xxxx-05-31';

	------------------------------------------------------------------------------------------------------------------------------------------

	If @IsSilent = 0
	PRINT 'BEGIN Clear vg3 mtaw temp results';
	DELETE g FROM @XG3 g;
	If @IsSilent = 0
	PRINT 'EINDE Clear vg3 mtaw temp results';

	If @IsSilent = 0
	PRINT 'BEGIN Zoek Alle peilmetingen nodig voor vg3 mTAW';
	If @IsSilent = 0
	PRINT 'BEGIN zoek alle eerste vg3 peilmetingen';
			INSERT INTO @XG3 (Meetpunt, simulatienr, hydrojaar, IsmTaW, one_Datum, one_Waarde )
			SELECT Meetpunt, simulatienr, Jaar, CONVERT(bit, 1) as mTaw,  Datum, Waarde
			FROM ( SELECT dte.Jaar																				as [Jaar]
							, fPM.simulatienr																as simulatienr
							, fPM.Meetpunt																	as Meetpunt
							--, fPM.dag																		as DatumKey
							, dte.Datum																			as Datum
							, Convert(Date,Convert(varchar(4),dTe.Jaar)+'-04-01')								as [HydroJaar_Eerste_Dag]
							, ABS(DATEDIFF(dd, dTe.Datum, Convert(Date,Convert(varchar(4),dTe.Jaar)+'-04-01'))) as Delta_one
							--, fPM.meting_TAW																	as PeilMetingWID
							, fPM.meting_TAW																			as [Waarde] 
							, ROW_NUMBER () OVER (PARTITION By dte.Jaar , fPM.Meetpunt, fPM.simulatienr ORDER BY ABS(DATEDIFF(dd, dTe.Datum, Convert(Date,Convert(varchar(4),dTe.Jaar)+'-04-01'))) ASC , fPM.dag ASC) AS [Nbr]
						FROM dbo.tblMeny_import  fPM 
								INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
								INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
																		AND BRJ.simulatienr =  fPM.simulatienr
																		AND BRJ.Jaar = dte.Jaar
																		AND BRJ.IsHydroJaar = 0
						WHERE fPM.meting_TAW IS NOT NULL
						AND dte.Maand_Nummer IN (3,4,5)
						--AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
						--AND fPM.MetingTypeWID  IN (@HandTypeWID, @DiverTypeWID)
						--AND fPM.PeilmetingCategorieCode IS NULL
						AND (fPM.Meetpunt = @Meetpunt OR @Meetpunt IS NULL )
						AND BRJ.vg3mTAWFout IS NULL
						AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
						)Eerste
				WHERE Eerste.Nbr = 1;
	If @IsSilent = 0
	PRINT 'EINDE zoek alle eerste vg3 peilmetingen';
	
	If @IsSilent = 0
	PRINT 'BEGIN zoek alle tweede vg3 peilmetingen';
			UPDATE t
			SET --t.two_DatumKey = Andere.DatumKey,
				 t.two_Datum = Andere.Datum
				--, t.two_PeilMetingWID = Andere.meting_TAW
				, t.two_Waarde = Andere.Waarde
				FROM (SELECT dte.Jaar										as [Jaar]
							, fPM.simulatienr							as simulatienr
							, fPM.Meetpunt								as Meetpunt
							--, fPM.dag									as DatumKey
							, dte.Datum										as Datum
							--, fPM.meting_TAW								as PeilMetingWID
							, fPM.meting_TAW										as [Waarde] 
							, ROW_NUMBER () OVER (PARTITION By dte.Jaar , fPM.Meetpunt, fPM.simulatienr ORDER BY ABS(DATEDIFF(dd, GVG_mTaw_one.one_Datum, dTe.Datum)) ASC, fPM.dag ASC) AS [Nbr]
						FROM dbo.tblMeny_import  fPM 
								INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
								INNER JOIN @XG3 GVG_mTaw_one ON GVG_mTaw_one.Meetpunt = fPM.Meetpunt
																AND GVG_mTaw_one.simulatienr = fPM.simulatienr
																AND GVG_mTaw_one.hydrojaar = dte.Jaar
																AND GVG_mTaw_one.IsmTaw = 1
								INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
																		AND BRJ.simulatienr = fPM.simulatienr
																		AND BRJ.Jaar = dte.Jaar
																		AND BRJ.IsHydroJaar = 0
						WHERE fPM.meting_TAW IS NOT NULL
						AND dte.Maand_Nummer IN (3,4,5)
						--AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
						--AND fPM.MetingTypeWID  IN (@HandTypeWID, @DiverTypeWID)
						AND (fPM.Meetpunt = @Meetpunt OR @Meetpunt IS NULL )
						AND Abs(DateDiff (dd,GVG_mTaw_one.one_Datum, dte.Datum)) >= @GVG_Range
						AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
						--AND GVG_mTaw_one.one_PeilMetingWID <> fPM.meting_TAW
						) Andere
						INNER JOIN @XG3 t ON t.Meetpunt = Andere.Meetpunt
												AND t.simulatienr =  Andere.simulatienr
												AND t.hydrojaar = Andere.Jaar
												AND t.IsmTaw = 1
					WHERE Andere.Nbr = 1;
		If @IsSilent = 0
		PRINT 'EINDE zoek alle tweede vg3 peilmetingen';

		If @IsSilent = 0
		PRINT 'BEGIN zoek alle derde vg3 peilmetingen';
			UPDATE t 
			SET --t.tree_DatumKey = Andere.DatumKey,
				 t.tree_Datum = Andere.Datum
				--, t.tree_PeilMetingWID = Andere.meting_TAW
				, t.tree_Waarde = Andere.Waarde
				FROM (SELECT dte.Jaar										as Jaar
							, fPM.simulatienr							as simulatienr
							, fPM.Meetpunt								as Meetpunt
							--, fPM.dag									as DatumKey
							, dte.Datum										as Datum
							--, fPM.meting_TAW								as PeilMetingWID
							, fPM.meting_TAW										as Waarde 
							, ROW_NUMBER () OVER (PARTITION By dte.Jaar , fPM.Meetpunt, fPM.simulatienr ORDER BY Abs(DateDiff (dd,GVG_mTaw_one.one_Datum, dte.Datum)) ASC
																																					, Abs(DateDiff (dd,GVG_mTaw_two.two_Datum, dte.Datum)) ASC
																																					, fPM.dag ASC
																																					) AS [Nbr]
						FROM dbo.tblMeny_import  fPM 
								INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
								INNER JOIN @XG3 GVG_mTaw_one ON GVG_mTaw_one.Meetpunt = fPM.Meetpunt
																		AND GVG_mTaw_one.simulatienr = fPM.simulatienr
																		AND GVG_mTaw_one.hydrojaar = dte.Jaar
																		AND GVG_mTaw_one.IsmTaw = 1
								INNER JOIN @XG3 GVG_mTaw_two ON GVG_mTaw_two.Meetpunt = fPM.Meetpunt
																		AND GVG_mTaw_two.simulatienr = fPM.simulatienr
																		AND GVG_mTaw_two.hydrojaar = dte.Jaar
																		AND GVG_mTaw_two.IsmTaw = 1

								INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
																		AND BRJ.simulatienr = fPM.simulatienr
																		AND BRJ.Jaar = dte.Jaar
																		AND BRJ.IsHydroJaar = 0
						WHERE fPM.meting_TAW IS NOT NULL
						AND dte.Maand_Nummer IN (3,4,5)
						--AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
						--AND fPM.MetingTypeWID  IN (@HandTypeWID, @DiverTypeWID)
						--AND fPM.PeilmetingCategorieCode IS NULL
						AND (fPM.Meetpunt = @Meetpunt OR @Meetpunt IS NULL )
						AND Abs(DateDiff (dd,GVG_mTaw_one.one_Datum, dte.Datum)) >= @GVG_Range
						AND Abs(DateDiff (dd,GVG_mTaw_two.two_Datum, dte.Datum)) >= @GVG_Range
						AND Abs(DateDiff (dd,GVG_mTaw_two.two_Datum, GVG_mTaw_one.one_Datum)) >= @GVG_Range
						AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
						--AND GVG_mTaw_one.one_PeilMetingWID <> fPM.meting_TAW
						--AND GVG_mTaw_two.two_PeilMetingWID <> fPM.meting_TAW
						) Andere
						INNER JOIN @XG3 t ON t.Meetpunt = Andere.Meetpunt
												AND t.simulatienr = Andere.simulatienr
												AND t.hydrojaar = Andere.Jaar
												AND t.IsmTaw = 1
					WHERE Andere.Nbr = 1;
		If @IsSilent = 0
		PRINT 'EINDE zoek alle derde vg3 peilmetingen';

		MERGE #tmpFactMENYPeilMetingJaar as trg
		USING (	SELECT t.Meetpunt
					, t.simulatienr
					, t.[hydrojaar]
					, t.one_Waarde		as PeilMeting1
					, t.two_Waarde		as PeilMeting2
					, t.tree_Waarde		as PeilMeting3
				FROM @XG3 t
				WHERE t.one_Waarde IS NOT NULL
				AND t.two_Waarde IS NOT NULL
				AND t.tree_Waarde IS NOT NULL
				AND t.IsmTaw = 1
				) src
			ON src.Meetpunt = trg.Meetpunt
			AND src.simulatienr = trg.simulatienr
			AND src.HydroJaar = trg.Jaar
			--AND trg.IsHydroJaar = 1
		WHEN MATCHED THEN UPDATE
			SET trg.vg3mTAWPeilMeting1 = src.PeilMeting1
				, trg.vg3mTAWPeilMeting2 = src.PeilMeting2
				, trg.vg3mTAWPeilMeting3 = src.PeilMeting3
		WHEN NOT MATCHED BY SOURCE THEN UPDATE
			SET trg.vg3mTAWPeilMeting1 = NULL
				, trg.vg3mTAWPeilMeting2 = NULL
				, trg.vg3mTAWPeilMeting3 = NULL;
	If @IsSilent = 0
	PRINT 'EINDE Zoek Alle peilmetingen nodig voor vg3 mTAW';

		-- Overige hebben een spreidingsprobleem
	If @IsSilent = 0
	PRINT 'BEGIN spreidingsprobleem tussen xxxx-03-01 en xxxx-05-31'
	UPDATE BRu 
		SET BRu.vg3mTAWFout = @SpreidingFout
	FROM #tmpFactMENYPeilMetingJaar BRu 
	WHERE BRu.vg3mTAWPeilMeting1 IS NULL 
	AND BRu.vg3mTAWPeilMeting2 IS NULL 
	AND BRu.vg3mTAWPeilMeting3 IS NULL 
	AND BRu.vg3mTAWFout IS NULL
	AND (Bru.Meetpunt = @Meetpunt OR @Meetpunt IS NULL )
	If @IsSilent = 0
	PRINT 'EINDE spreidingsprobleem tussen xxxx-03-01 en xxxx-05-31';
	
	If @IsSilent = 0
	PRINT 'EINDE vg3 mTAW'
------------------------------------------------------------------------------------------------------------------------------------
	If @IsSilent = 0
	PRINT 'BEGIN vg3 mMaaiVeld'

	If @IsSilent = 0
	PRINT 'BEGIN Clear vg3 temp results mMaaiveld';
	DELETE g FROM @XG3 g;
	If @IsSilent = 0
	PRINT 'EINDE Clear vg3 temp results mMaaiveld';

		--Minstens 3 metingen tussen xxxx-03-01 en xxxx-05-31
	If @IsSilent = 0
	PRINT 'BEGIN Minstens 3 metingen tussen xxxx-03-01 en xxxx-05-31'
	--UPDATE BRu 
	--	SET BRu.vg3mMaaiveldFout = @GegevenstekortFout
	--FROM #tmpFactMENYPeilMetingJaar BRu 
	--	LEFT OUTER  JOIN (	SELECT BR.Meetpunt
	--							, BR.Jaar
	--							, Count(*) as Nbr
	--						FROM #tmpFactMENYPeilMetingJaar BR 
	--							INNER JOIN dbo.tblMeny_import fPM  ON fPM.Meetpunt = BR.Meetpunt
	--							INNER JOIN dbo.DimTijd dT ON dT.Datum = fPM.dag
	--														AND dT.Maand_Nummer IN (3,4,5) AND dT.Jaar = BR.Jaar
	--						WHERE 1=1
	--						AND fPM.mMaaiVeld IS NOT NULL
	--						AND fPM.MetingTypeWID  IN (@HandTypeWID, @DiverTypeWID)
	--						AND (BR.Meetpunt = @Meetpunt OR @Meetpunt IS NULL )
	--						AND BR.IsHydroJaar = 0
	--						GROUP BY BR.Meetpunt
	--							, BR.Jaar
	--						HAVING COUNT(*) >= 3
	--						) Detail ON Detail.Meetpunt = BRu.Meetpunt
	--								AND Detail.Jaar = BRu.Jaar
	--WHERE Detail.Meetpunt IS NULL
	--AND (BRu.Meetpunt = @Meetpunt ) ;
	If @IsSilent = 0
	PRINT 'EINDE Minstens 3 metingen tussen xxxx-03-01 en xxxx-05-31';

	------------------------------------------------------------------------------------------------------------------------------------------

	If @IsSilent = 0
	PRINT 'BEGIN Zoek Alle peilmetingen nodig voor vg3 mMaaiveld ';
	If @IsSilent = 0
	PRINT 'BEGIN zoek alle eerste vg3 peilmetingen mMaaiVeld';
			--INSERT INTO @XG3 (MeetpuntWID, hydrojaar, IsmTaW, one_DatumKey, one_Datum, one_PeilMetingWID, one_Waarde )
			--SELECT MeetpuntWID, Jaar, CONVERT(bit, 0) as mTaw, DatumKey, Datum, PeilMetingWID, Waarde
			--FROM ( SELECT dte.Jaar																										as Jaar
			--				, fPM.Meetpunt																							as MeetpuntWID 
			--				, fPM.dag																								as DatumKey
			--				, dte.Datum																									as Datum
			--				, Convert(Date,Convert(varchar(4),dTe.Jaar)+'-04-01')														as HydroJaar_Eerste_Dag
			--				, ABS(DATEDIFF(dd, dTe.Datum, Convert(Date,Convert(varchar(4),dTe.Jaar)+'-04-01')))							as Delta_one
			--				, fPM.meting_TAW																							as PeilMetingWID
			--				, fPM.mMaaiVeld																								as Waarde 
			--				, ROW_NUMBER () OVER (PARTITION By dte.Jaar , fPM.Meetpunt ORDER BY ABS(DATEDIFF(dd, dTe.Datum, Convert(Date,Convert(varchar(4),dTe.Jaar)+'-04-01'))) ASC , fPM.dag ASC, fPM.MetingTypeWID ASC) AS [Nbr]
			--			FROM dbo.tblMeny_import  fPM 
			--					INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
			--					INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
			--																					AND BRJ.Jaar = dte.Jaar
			--																					AND BRJ.IsHydroJaar = 0
			--			WHERE fPM.mMaaiVeld IS NOT NULL
			--			AND dte.Maand_Nummer IN (3,4,5)
			--			AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
			--			AND fPM.MetingTypeWID  IN (@HandTypeWID, @DiverTypeWID)
			--			AND fPM.PeilmetingCategorieCode IS NULL
			--			AND (fPM.Meetpunt  = @Meetpunt OR @Meetpunt IS NULL )
			--			AND BRJ.vg3mMaaiveldFout IS NULL
			--			)Eerste
			--	WHERE Eerste.Nbr = 1;
	If @IsSilent = 0
	PRINT 'EINDE zoek alle eerste vg3 peilmetingen mMaaiVeld';

	If @IsSilent = 0
	PRINT 'BEGIN zoek alle tweede vg3 peilmetingen mMaaiVeld';
			--UPDATE t
			--SET t.two_DatumKey = Andere.DatumKey
			--	, t.two_Datum = Andere.Datum
			--	, t.two_PeilMetingWID = Andere.meting_TAW
			--	, t.two_Waarde = Andere.Waarde
			--	FROM (SELECT dte.Jaar											as Jaar
			--				, fPM.Meetpunt									as MeetpuntWID
			--				, fPM.dag										as DatumKey
			--				, dte.Datum											as Datum
			--				, fPM.meting_TAW									as PeilMetingWID
			--				, fPM.meting_TAW											as Waarde 
			--				, ROW_NUMBER () OVER (PARTITION By dte.Jaar , fPM.Meetpunt ORDER BY ABS(DATEDIFF(dd, GVG_mMaaiVeld_one.one_Datum, dTe.Datum)) ASC, fPM.dag ASC, fPM.MetingTypeWID ASC) AS [Nbr]
			--			FROM dbo.tblMeny_import  fPM 
			--					INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
			--					INNER JOIN @XG3 GVG_mMaaiVeld_one ON GVG_mMaaiVeld_one.Meetpunt = fPM.Meetpunt
			--													AND GVG_mMaaiVeld_one.hydrojaar = dte.Jaar
			--													AND GVG_mMaaiVeld_one.IsmTaw = 0
			--					INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
			--																					AND BRJ.Jaar = dte.Jaar
			--																					AND BRJ.IsHydroJaar = 0
			--			WHERE fPM.mMaaiVeld IS NOT NULL
			--			AND dte.Maand_Nummer IN (3,4,5)
			--			AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
			--			AND fPM.MetingTypeWID  IN (@HandTypeWID, @DiverTypeWID)
			--			AND (fPM.Meetpunt  = @Meetpunt OR @Meetpunt IS NULL )
			--			AND Abs(DateDiff (dd,GVG_mMaaiVeld_one.one_Datum, dte.Datum)) >= @GVG_Range
			--			AND GVG_mMaaiVeld_one.one_PeilMetingWID <> fPM.meting_TAW
			--			) Andere
			--			INNER JOIN @XG3 t ON t.Meetpunt = Andere.Meetpunt
			--									AND t.hydrojaar = Andere.Jaar
			--									AND t.IsmTaw = 0
			--		WHERE Andere.Nbr = 1;
	If @IsSilent = 0
	PRINT 'EINDE zoek alle tweede vg3 peilmetingen mMaaiVeld';

	If @IsSilent = 0
	PRINT 'BEGIN zoek alle derde vg3 peilmetingen mMaaiVeld';
			--UPDATE t 
			--	SET t.tree_DatumKey = Andere.DatumKey
			--		, t.tree_Datum = Andere.Datum
			--		, t.tree_PeilMetingWID = Andere.meting_TAW
			--		, t.tree_Waarde = Andere.Waarde
			--	FROM (SELECT dte.Jaar									as Jaar
			--				, fPM.Meetpunt							as MeetpuntWID
			--				, fPM.dag								as DatumKey
			--				, dte.Datum									as Datum
			--				, fPM.meting_TAW							as PeilMetingWID
			--				, fPM.meting_TAW									as Waarde
			--				, ROW_NUMBER () OVER (PARTITION By dte.Jaar , fPM.Meetpunt ORDER BY Abs(DateDiff (dd,GVG_mMaaiVeld_one.one_Datum, dte.Datum)) ASC
			--																					, Abs(DateDiff (dd,GVG_mMaaiVeld_two.two_Datum, dte.Datum)) ASC
			--																					,  fPM.dag ASC
			--																					, fPM.MetingTypeWID ASC) AS [Nbr]
			--			FROM dbo.tblMeny_import  fPM 
			--					INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
			--					INNER JOIN @XG3 GVG_mMaaiVeld_one ON GVG_mMaaiVeld_one.Meetpunt = fPM.Meetpunt
			--															AND GVG_mMaaiVeld_one.hydrojaar = dte.Jaar
			--															AND GVG_mMaaiVeld_one.IsmTaw = 0
			--					INNER JOIN @XG3 GVG_mMaaiVeld_two ON GVG_mMaaiVeld_two.Meetpunt = fPM.Meetpunt
			--															AND GVG_mMaaiVeld_two.hydrojaar = dte.Jaar
			--															AND GVG_mMaaiVeld_two.IsmTaw = 0



			--					INNER JOIN #tmpFactMENYPeilMetingJaar BRJ ON BRJ.Meetpunt = fPM.Meetpunt
			--																					AND BRJ.Jaar = dte.Jaar
			--																					AND BRJ.IsHydroJaar = 0
			--			WHERE fPM.mMaaiVeld IS NOT NULL
			--			AND dte.Maand_Nummer IN (3,4,5)
			--			AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
			--			AND fPM.MetingTypeWID  IN (@HandTypeWID, @DiverTypeWID)
			--			AND fPM.PeilmetingCategorieCode IS NULL
			--			AND (fPM.Meetpunt  = @Meetpunt OR @Meetpunt IS NULL)
			--			AND Abs(DateDiff (dd,GVG_mMaaiVeld_one.one_Datum, dte.Datum)) >= @GVG_Range
			--			AND Abs(DateDiff (dd,GVG_mMaaiVeld_two.two_Datum, dte.Datum)) >= @GVG_Range
			--			AND Abs(DateDiff (dd,GVG_mMaaiVeld_two.two_Datum, GVG_mMaaiVeld_one.one_Datum)) >= @GVG_Range
			--			AND GVG_mMaaiVeld_one.one_PeilMetingWID <> fPM.meting_TAW
			--			AND GVG_mMaaiVeld_two.two_PeilMetingWID <> fPM.meting_TAW
			--			) Andere
			--			INNER JOIN @XG3 t ON t.Meetpunt = Andere.Meetpunt
			--									AND t.hydrojaar = Andere.Jaar
			--									AND t.IsmTaw = 0
			--		WHERE Andere.Nbr = 1;
	If @IsSilent = 0
	PRINT 'EINDE zoek alle derde vg3 peilmetingen mMaaiVeld';
					
		
		--MERGE [dbo].[FactBRPeilMetingJaar] as trg
		--MERGE #tmpFactMENYPeilMetingJaar as trg
		--USING (	
		--				SELECT t.[Meetpunt]
		--				, t.[hydrojaar]
		--				, t.one_Waarde		as PeilMeting1
		--				, t.two_Waarde		as PeilMeting2
		--				, t.tree_Waarde		as PeilMeting3
		--			FROM @XG3 t
		--			WHERE t.one_Waarde IS NOT NULL
		--			AND t.two_Waarde IS NOT NULL
		--			AND t.tree_Waarde IS NOT NULL
		--			AND t.IsmTaw = 0
		--			) src
		--	ON src.Meetpunt = trg.Meetpunt
		--	AND src.[hydrojaar] = trg.Jaar
		--	--AND trg.IsHydroJaar = 1
		--WHEN MATCHED THEN UPDATE
		--	SET trg.vg3mMaaiVeldPeilMeting1 = src.meting_TAW1
		--		, trg.vg3mMaaiVeldPeilMeting2 = src.meting_TAW2
		--		, trg.vg3mMaaiVeldPeilMeting3 = src.meting_TAW3
		--WHEN NOT MATCHED BY SOURCE THEN UPDATE
		--	SET trg.vg3mMaaiVeldPeilMeting1 = NULL
		--		, trg.vg3mMaaiVeldPeilMeting2 = NULL
		--		, trg.vg3mMaaiVeldPeilMeting3 = NULL;
	If @IsSilent = 0
	PRINT 'EINDE Zoek Alle peilmetingen nodig voor vg3 mMaaiveld';

	If @IsSilent = 0
	PRINT 'BEGIN Clear vg3 temp results mMaaiveld';
	DELETE g FROM @XG3 g;

	If @IsSilent = 0
	PRINT 'EINDE Clear vg3 temp results mMaaiveld';


		-- Overige hebben een spreidingsprobleem
	If @IsSilent = 0
	PRINT 'BEGIN spreidingsprobleem tussen xxxx-03-01 en xxxx-05-31'
	--UPDATE BRu 
	--	SET BRu.vg3mMaaiveldFout = @SpreidingFout
	--FROM #tmpFactMENYPeilMetingJaar BRu 
	--WHERE BRu.vg3mMaaiVeldPeilMeting1 IS NULL 
	--AND BRu.vg3mMaaiVeldPeilMeting2 IS NULL 
	--AND BRu.vg3mMaaiVeldPeilMeting3 IS NULL 
	--AND BRu.vg3mMaaiveldFout IS NULL
	--AND (Bru.Meetpunt  = @Meetpunt OR @Meetpunt IS NULL)
	--If @IsSilent = 0
	PRINT 'EINDE spreidingsprobleem tussen xxxx-03-01 en xxxx-05-31';
	
	If @IsSilent = 0
	PRINT 'EINDE vg3 mMaaiVeld'

	If @IsSilent = 0
	PRINT 'Summary data';

	If @IsSilent = 0
	PRINT 'BEGIN zoek gg3 peilmeting mTaw';
		INSERT INTO @XG3 (Meetpunt, simulatienr, hydrojaar, IsmTaW, one_Waarde )
		SELECT Meetpunt, simulatienr, HydroJaar, CONVERT(bit, 1) as mTaw, Mean
		FROM ( SELECT dte.HydroJaar				as hydrojaar
					--, BRJ.BRPeilMetingJaarWID as chek
					, fPM.simulatienr		as simulatienr
					, fPM.Meetpunt			as Meetpunt
					--, fPM.dag				as DatumKey
					--, dte.Datum					as Datum
					--, fPM.meting_TAW			as PeilMetingWID
					--, fPM.meting_TAW					as Waarde
					, avg(fPM.meting_TAW) AS [Mean]
				FROM dbo.tblMeny_import  fPM --with (index (IN_Switch_tblMeny_import_GHG))
						INNER JOIN dbo.DimTijd dte ON dte.Datum = fPM.dag 
						INNER JOIN #tmpFactMENYPeilMetingJaar  BRJ ON BRJ.Meetpunt = fPM.Meetpunt
																	AND BRJ.simulatienr =  fPM.simulatienr
																	AND BRJ.Jaar = dte.HydroJaar
																	AND BRJ.IsHydroJaar = 1
				WHERE fPM.meting_TAW IS NOT NULL
				--AND fPM.PeilmetingStatusCode NOT IN ('INV', 'DEL')
				--AND fPM.[MetingTypeWID] IN (@HandTypeWID, @DiverTypeWID)
				AND BRJ.BRResultaatWID = 0
				--AND fPM.PeilmetingCategorieCode IS NULL
				AND (fPM.Meetpunt = @Meetpunt OR @Meetpunt IS NULL)
				AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
				GROUP BY fPM.Meetpunt, fPM.simulatienr, HydroJaar
				)Eerste
		--WHERE Eerste.Nbr = 1;
	If @IsSilent = 0
	PRINT 'EINDE zoek gg3 peilmeting mTaw';

		
	MERGE #tmpFactMENYPeilMetingJaar as trg
	USING (	SELECT t.[Meetpunt]
					, t.simulatienr
					, t.[hydrojaar]
					, t.one_Waarde		as PeilMeting1
					--, t.two_Waarde		as PeilMeting2
					--, t.tree_Waarde		as PeilMeting3
				FROM @XG3 t
				WHERE t.one_Waarde IS NOT NULL
				--AND t.two_Waarde IS NOT NULL
				--AND t.tree_Waarde IS NOT NULL
				AND t.IsmTaw = 1
				AND (t.Meetpunt = @Meetpunt OR @Meetpunt IS NULL )
				) src
		ON src.Meetpunt = trg.Meetpunt
		AND src.simulatienr =  trg.simulatienr
		AND src.hydrojaar = trg.Jaar
		AND trg.IsHydroJaar = 1
	WHEN MATCHED THEN UPDATE
		SET trg.gg3mTAWPeilMeting = src.PeilMeting1
			--, trg.hg3mTAWPeilMeting2 = src.PeilMeting2
			--, trg.hg3mTAWPeilMeting3 = src.PeilMeting3
	WHEN NOT MATCHED BY SOURCE  THEN UPDATE
		SET trg.gg3mTAWPeilMeting = NULL;
			--, trg.hg3mTAWPeilMeting2 = NULL
			--, trg.hg3mTAWPeilMeting3 = NULL ;
	If @IsSilent = 0
	PRINT 'EINDE Zoek de peilmeting voor gg3 mTAW HydroJaar';



	---Alle lege Records van een foutmelding voorzien
	If @IsSilent = 0
	PRINT 'BEGIN Alle lege records mTAW voorzien van foutboodschap HydroJaar';
	UPDATE BR
		SET BR.gg3mTAWFout = @SpreidingFout
	FROM #tmpFactMENYPeilMetingJaar BR
	WHERE 1=1
	AND (BR.gg3mTAWPeilMeting IS NULL 
		--OR BR.hg3mTAWPeilMeting2 IS NULL
		--OR BR.hg3mTAWPeilMeting3 IS NULL
		)
	AND ( BR.Meetpunt  = @Meetpunt OR @Meetpunt IS NULL )
	AND BR.IsHydroJaar = 1
	AND BR.BRResultaatWID = 0;
	If @IsSilent = 0
	PRINT 'EINDE Alle lege records mTAW voorzien van foutboodschap HydroJaar';

	DELETE g 
	FROM @XG3 g;

	/*
	MERGE #tmpFactMENYPeilMetingJaar trg 
	USING (	SELECT summ.Meetpunt
					, summ.Jaar
					, summ.IsHydroJaar
					, summ.meting_TAW
					, summ.MaxmTAWPeilmeting
					, summ.MinmTAWPeilmeting
					, summ.MaxmMaaiveldPeilmeting
					, summ.MinmMaaiveldPeilmeting
			FROM (SELECT BRJ.Meetpunt
					, BRJ.Jaar
					, BRJ.IsHydroJaar
					, fPM.meting_TAW
					, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fPM.meting_TAW DESC ) as MaxmTAWPeilmeting
					, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fPM.meting_TAW ASC ) as MinmTAWPeilmeting
					, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fpm.mMaaiveld DESC ) as MaxmMaaiveldPeilmeting
					, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fpm.mMaaiveld ASC ) as MinmMaaiveldPeilmeting
				FROM #tmpFactMENYPeilMetingJaar BRJ
				INNER JOIN dbo.tblMeny_import fpm ON fpm.Meetpunt = BRJ.Meetpunt
												AND BRJ.IsHydroJaar = 0
				INNER JOIN dbo.DimTijd dt ON dT.Datum = fPM.dag 
										AND dt.Jaar = BRJ.Jaar
				WHERE 1=1
				AND fPM.MetingTypeWID IN (@HandTypeWID, @DiverTypeWID)
				) summ
			WHERE summ.MaxmMaaiveldPeilmeting = 1
			OR summ.MinmTAWPeilmeting = 1 
			OR summ.MaxmMaaiveldPeilmeting = 1 
			OR summ.MinmMaaiveldPeilmeting = 1
		) src
	ON trg.Meetpunt = src.Meetpunt
	AND trg.Jaar = src.Jaar
	AND trg.IsHydroJaar = src.IsHydroJaar
	WHEN MATCHED THEN UPDATE
		set trg.[MinJmTAWPeilmeting] = CASE WHEN src.MinmTAWPeilmeting = 1 THEN src.meting_TAW ELSE trg.[MinJmTAWPeilmeting] END
			, trg.[MaxJmTAWPeilmeting] = CASE WHEN src.MaxmTAWPeilmeting = 1 THEN src.meting_TAW ELSE trg.[MaxJmTAWPeilmeting] END
			, trg.[MinJmMaaiveldPeilmeting] = CASE WHEN src.MinmMaaiveldPeilmeting = 1 THEN src.meting_TAW ELSE trg.[MinJmMaaiveldPeilmeting] END
			, trg.[MaxJmMaaiveldPeilmeting] = CASE WHEN src.MaxmMaaiveldPeilmeting = 1 THEN src.meting_TAW ELSE trg.[MaxJmMaaiveldPeilmeting] END
	;*/





	--update brj
	--set brj.[MaxJmMaaiveldPeilmeting] = summ.meting_TAW 
	--FROM  #tmpFactMENYPeilMetingJaar brj
	--INNER JOIN (SELECT summ.Meetpunt
	--				, summ.Jaar
	--				, summ.IsHydroJaar
	--				, summ.meting_TAW
	--				--, summ.MaxmTAWPeilmeting
	--				--, summ.MinmTAWPeilmeting
	--				, summ.MaxmMaaiveldPeilmeting
	--				--, summ.MinmMaaiveldPeilmeting
	--			FROM (SELECT BRJ.Meetpunt
	--					, BRJ.Jaar
	--					, BRJ.IsHydroJaar
	--					, fPM.meting_TAW
	--				--	, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fPM.meting_TAW DESC ) as MaxmTAWPeilmeting
	--				--	, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fPM.meting_TAW ASC ) as MinmTAWPeilmeting
	--					, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fpm.mMaaiveld DESC ) as MaxmMaaiveldPeilmeting
	--				--	, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fpm.mMaaiveld ASC ) as MinmMaaiveldPeilmeting
	--				FROM #tmpFactMENYPeilMetingJaar BRJ
	--				INNER JOIN dbo.tblMeny_import fpm ON fpm.Meetpunt = BRJ.Meetpunt
	--												AND BRJ.IsHydroJaar = 1
	--				INNER JOIN dbo.DimTijd dt ON dT.Datum = fPM.dag 
	--										AND dt.HydroJaar = BRJ.Jaar
	--				WHERE 1=1
	--				AND fPM.MetingTypeWID IN (@HandTypeWID, @DiverTypeWID)
	--				) summ
	--			WHERE summ.MaxmMaaiveldPeilmeting = 1
	--		) summ ON summ.Meetpunt = brj.Meetpunt
	--				AND summ.Jaar = brj.Jaar
	--				AND summ.IsHydroJaar = brj.IsHydroJaar

		
	--update brj
	--set brj.[MinJmMaaiveldPeilmeting] = summ.meting_TAW 
	--FROM  #tmpFactMENYPeilMetingJaar brj
	--INNER JOIN (SELECT summ.Meetpunt
	--				, summ.Jaar
	--				, summ.IsHydroJaar
	--				, summ.meting_TAW
	--				--, summ.MaxmTAWPeilmeting
	--				--, summ.MinmTAWPeilmeting
	--				--, summ.MaxmMaaiveldPeilmeting
	--				, summ.MinmMaaiveldPeilmeting
	--			FROM (SELECT BRJ.Meetpunt
	--					, BRJ.Jaar
	--					, BRJ.IsHydroJaar
	--					, fPM.meting_TAW
	--					--, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fPM.meting_TAW DESC ) as MaxmTAWPeilmeting
	--					--, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fPM.meting_TAW ASC ) as MinmTAWPeilmeting
	--					--, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fpm.mMaaiveld DESC ) as MaxmMaaiveldPeilmeting
	--					, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fpm.mMaaiveld ASC ) as MinmMaaiveldPeilmeting
	--				FROM #tmpFactMENYPeilMetingJaar BRJ
	--				INNER JOIN dbo.tblMeny_import fpm ON fpm.Meetpunt = BRJ.Meetpunt
	--												AND BRJ.IsHydroJaar = 1
	--				INNER JOIN dbo.DimTijd dt ON dT.Datum = fPM.dag 
	--										AND dt.HydroJaar = BRJ.Jaar
	--				WHERE 1=1
	--				AND fPM.MetingTypeWID IN (@HandTypeWID, @DiverTypeWID)
	--				) summ
	--			WHERE summ.MinmMaaiveldPeilmeting = 1
	--		) summ ON summ.Meetpunt = brj.Meetpunt
	--				AND summ.Jaar = brj.Jaar
	--				AND summ.IsHydroJaar = brj.IsHydroJaar


	update brj
	set brj.[MaxJmTAWPeilmeting] = summ.meting_TAW 
	FROM  #tmpFactMENYPeilMetingJaar brj 
	INNER JOIN (SELECT summ.Meetpunt
					, summ.simulatienr
					, summ.Jaar
					, summ.IsHydroJaar
					, summ.meting_TAW
					, summ.MaxmTAWPeilmeting
					--, summ.MinmTAWPeilmeting
					--, summ.MaxmMaaiveldPeilmeting
					--, summ.MinmMaaiveldPeilmeting
				FROM (SELECT BRJ.Meetpunt
						, BRJ.simulatienr
						, BRJ.Jaar
						, BRJ.IsHydroJaar
						, fPM.meting_TAW
						, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.simulatienr, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fPM.meting_TAW DESC ) as MaxmTAWPeilmeting
						--, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fPM.meting_TAW ASC ) as MinmTAWPeilmeting
						--, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fpm.mMaaiveld DESC ) as MaxmMaaiveldPeilmeting
						--, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fpm.mMaaiveld ASC ) as MinmMaaiveldPeilmeting
					FROM #tmpFactMENYPeilMetingJaar BRJ
					INNER JOIN dbo.tblMeny_import fpm ON fpm.Meetpunt = BRJ.Meetpunt
													AND fPM.simulatienr = BRJ.simulatienr
													AND BRJ.IsHydroJaar = 1
					INNER JOIN dbo.DimTijd dt ON dT.Datum = fPM.dag 
											AND dt.HydroJaar = BRJ.Jaar
					WHERE 1=1
					--AND fPM.MetingTypeWID IN (@HandTypeWID, @DiverTypeWID)
					AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
					AND BRJ.BRResultaatWID = 0
					) summ
				WHERE summ.MaxmTAWPeilmeting = 1
			) summ ON summ.Meetpunt = brj.Meetpunt
					AND summ.simulatienr = brj.simulatienr
					AND summ.Jaar = brj.Jaar
					AND summ.IsHydroJaar = brj.IsHydroJaar


	update brj
	set brj.[MinJmTAWPeilmeting] = summ.meting_TAW 
	FROM  #tmpFactMENYPeilMetingJaar brj 
	INNER JOIN (SELECT summ.Meetpunt
					, summ.simulatienr
					, summ.Jaar
					, summ.IsHydroJaar
					, summ.meting_TAW
					--, summ.MaxmTAWPeilmeting
					, summ.MinmTAWPeilmeting
					--, summ.MaxmMaaiveldPeilmeting
					--, summ.MinmMaaiveldPeilmeting
				FROM (SELECT BRJ.Meetpunt
						, BRJ.simulatienr
						, BRJ.Jaar
						, BRJ.IsHydroJaar
						, fPM.meting_TAW
						--, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fPM.meting_TAW DESC ) as MaxmTAWPeilmeting
						, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.simulatienr, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fPM.meting_TAW ASC ) as MinmTAWPeilmeting
						--, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fpm.mMaaiveld DESC ) as MaxmMaaiveldPeilmeting
						--, ROW_NUMBER() OVER(Partition By BRJ.Meetpunt, BRJ.Jaar, BRJ.IsHydroJaar ORDER BY fpm.mMaaiveld ASC ) as MinmMaaiveldPeilmeting
					FROM #tmpFactMENYPeilMetingJaar BRJ
					INNER JOIN dbo.tblMeny_import fpm ON fpm.Meetpunt = BRJ.Meetpunt
													AND fpm.simulatienr = BRJ.simulatienr
													AND BRJ.IsHydroJaar = 1
					INNER JOIN dbo.DimTijd dt ON dT.Datum = fPM.dag 
											AND dt.HydroJaar = BRJ.Jaar
					WHERE 1=1
					--AND fPM.MetingTypeWID IN (@HandTypeWID, @DiverTypeWID)
					AND (fPm.is_veldmeting >= 0) -- uitsluiten van gesimuleerde metingen indien er een veldmeting is binnen een referentieperiode (gesteld op 14 dagen)
					AND BRJ.BRResultaatWID = 0
					) summ
				WHERE summ.MinmTAWPeilmeting = 1
			) summ ON summ.Meetpunt = brj.Meetpunt
					AND summ.simulatienr =  brj.simulatienr
					AND summ.Jaar = brj.Jaar
					AND summ.IsHydroJaar = brj.IsHydroJaar;


	IF @MetHistoGram = 1 
	BEGIN 
		SET NOCOUNT OFF
		SELECT [BRPeilMetingJaarWID]   ,
				[Meetpunt]   ,
				[simulatienr]	,
				[Jaar]   ,
				[IsHydroJaar]   ,
				[EerstePeilMetingWID]  ,
				[ReprPeriodeEerstePeilMeting]  ,
				[LaatstePeilMetingWID]  ,
				[ReprPeriodeLaatstePeilMeting]  ,
				[BRResultaatWID]  ,
				[hg3mTAWPeilMeting1]  ,
				[hg3mTAWPeilMeting2]  ,
				[hg3mTAWPeilMeting3]  ,
				[hg3mTAWFout]  ,
				[hg3mMaaiVeldPeilMeting1]  ,
				[hg3mMaaiVeldPeilMeting2]  ,
				[hg3mMaaiVeldPeilMeting3]  ,
				[hg3mMaaiveldFout]  ,
				[lg3mTAWPeilMeting1]  ,
				[lg3mTAWPeilMeting2]  ,
				[lg3mTAWPeilMeting3]  ,
				[lg3mTAWFout]  ,
				[lg3mMaaiVeldPeilMeting1]  ,
				[lg3mMaaiVeldPeilMeting2]  ,
				[lg3mMaaiVeldPeilMeting3]  ,
				[lg3mMaaiveldFout]  ,
				[vg3mTAWPeilMeting1]  ,
				[vg3mTAWPeilMeting2]  ,
				[vg3mTAWPeilMeting3]  ,
				[vg3mTAWFout]  ,
				[gg3mTAWPeilMeting]  ,
				[gg3mTAWFout]  ,
				[gg3mMaaiveldPeilMeting]  ,
				[gg3mMaaiveldFout]  ,
				[vg3mMaaiVeldPeilMeting1]  ,
				[vg3mMaaiVeldPeilMeting2]  ,
				[vg3mMaaiVeldPeilMeting3]  ,
				[vg3mMaaiveldFout]  ,
				[MinJmTAWPeilmeting]  ,
				[MaxJmTAWPeilmeting]  ,
				[MinJmMaaiveldPeilmeting]  ,
				[MaxJmMaaiveldPeilmeting]  ,
				[ParamMinAantalMetingen]  ,
				[MaxRepresentatievePeriode]  ,
				[GHG_Range]  ,
				[GLG_Range]  ,
				[GVG_Range]  ,
				[GG_Range]	,
				[RepresentatievePeriodeHistogram] 
		FROM #tmpFactMENYPeilMetingJaar
		ORDER BY Jaar, Ishydrojaar;
	END
	ELSE 
	BEGIN
		SET NOCOUNT OFF
		SELECT [BRPeilMetingJaarWID]   ,
				[Meetpunt]   ,
				[simulatienr]	,
				[Jaar]   ,
				[IsHydroJaar]   ,
				[EerstePeilMetingWID]  ,
				[ReprPeriodeEerstePeilMeting]  ,
				[LaatstePeilMetingWID]  ,
				[ReprPeriodeLaatstePeilMeting]  ,
				[BRResultaatWID]  ,
				[hg3mTAWPeilMeting1]  ,
				[hg3mTAWPeilMeting2]  ,
				[hg3mTAWPeilMeting3]  ,
				[hg3mTAWFout]  ,
				[hg3mMaaiVeldPeilMeting1]  ,
				[hg3mMaaiVeldPeilMeting2]  ,
				[hg3mMaaiVeldPeilMeting3]  ,
				[hg3mMaaiveldFout]  ,
				[lg3mTAWPeilMeting1]  ,
				[lg3mTAWPeilMeting2]  ,
				[lg3mTAWPeilMeting3]  ,
				[lg3mTAWFout]  ,
				[lg3mMaaiVeldPeilMeting1]  ,
				[lg3mMaaiVeldPeilMeting2]  ,
				[lg3mMaaiVeldPeilMeting3]  ,
				[lg3mMaaiveldFout]  ,
				[vg3mTAWPeilMeting1]  ,
				[vg3mTAWPeilMeting2]  ,
				[vg3mTAWPeilMeting3]  ,
				[vg3mTAWFout]  ,
				[gg3mTAWPeilMeting]  ,
				[gg3mTAWFout]  ,
				[gg3mMaaiveldPeilMeting]  ,
				[gg3mMaaiveldFout]  ,
				[vg3mMaaiVeldPeilMeting1]  ,
				[vg3mMaaiVeldPeilMeting2]  ,
				[vg3mMaaiVeldPeilMeting3]  ,
				[vg3mMaaiveldFout]  ,
				[MinJmTAWPeilmeting]  ,
				[MaxJmTAWPeilmeting]  ,
				[MinJmMaaiveldPeilmeting]  ,
				[MaxJmMaaiveldPeilmeting]  ,
				[ParamMinAantalMetingen]  ,
				[MaxRepresentatievePeriode]  ,
				[GHG_Range]  ,
				[GLG_Range]  ,
				[GVG_Range]  ,
				[GG_Range]	,
				CONVERT(xml,null) as [RepresentatievePeriodeHistogram]
		FROM #tmpFactMENYPeilMetingJaar
		ORDER BY Jaar, Ishydrojaar;
	END
--END

--drop table if exists test
--select *
--INTO test
--FROM  #tmpFactMENYPeilMetingJaar brj 

-- berekenen van waarden t.o.v. het maaiveld (indien mTAW van het maaiveld bekend is)
UPDATE fpeilen
SET hg3mMaaiveldPeilMeting1 = iif(hg3mTAWPeilMeting1 is null, null, hg3mTAWPeilMeting1 - TAWMaaiveld)
 , hg3mMaaiveldPeilMeting2 = iif(hg3mTAWPeilMeting2 is null, null, hg3mTAWPeilMeting2 - TAWMaaiveld)
 , hg3mMaaiveldPeilMeting3 = iif(hg3mTAWPeilMeting3 is null, null, hg3mTAWPeilMeting3 - TAWMaaiveld)
 , lg3mMaaiveldPeilMeting1 = iif(lg3mTAWPeilMeting1 is null, null, lg3mTAWPeilMeting1 - TAWMaaiveld)
 , lg3mMaaiveldPeilMeting2 = iif(lg3mTAWPeilMeting2 is null, null, lg3mTAWPeilMeting2 - TAWMaaiveld)
 , lg3mMaaiveldPeilMeting3 = iif(lg3mTAWPeilMeting3 is null, null, lg3mTAWPeilMeting3 - TAWMaaiveld)
 , vg3mMaaiveldPeilMeting1 = iif(vg3mTAWPeilMeting1 is null, null, vg3mTAWPeilMeting1 - TAWMaaiveld)
 , vg3mMaaiveldPeilMeting2 = iif(vg3mTAWPeilMeting2 is null, null, vg3mTAWPeilMeting2 - TAWMaaiveld)
 , vg3mMaaiveldPeilMeting3 = iif(vg3mTAWPeilMeting3 is null, null, vg3mTAWPeilMeting3 - TAWMaaiveld)
 , gg3mMaaiveldPeilMeting = iif(gg3mTAWPeilMeting is null, null, gg3mTAWPeilMeting - TAWMaaiveld)
 , minjmMaaiveldPeilMeting = iif(minjmTAWPeilMeting is null, null, minjmTAWPeilMeting - TAWMaaiveld)
 , maxjmMaaiveldPeilMeting = iif(maxjmTAWPeilMeting is null, null, maxjmTAWPeilMeting - TAWMaaiveld)
FROM #tmpFactMENYPeilMetingJaar fpeilen inner join (SELECT MeetpuntCode, ISNULL(AVG(PeilpuntTAWMaaiveld), - 99) AS TAWMaaiveld
														FROM D0025_00_Watina.report.vw_Peilpunt
														GROUP BY MeetpuntCode HAVING ISNULL(AVG(PeilpuntTAWMaaiveld), - 99) >-99) m 
ON fpeilen.meetpunt = m.MeetpuntCode;

-- tabel FactMENYPeilMetingJaar_Flaven bijwerken
MERGE FactMENYPeilMetingJaar_Flaven as trg
USING (  SELECT * FROM #tmpFactMENYPeilMetingJaar					
			) src
ON (src.Meetpunt = trg.Meetpunt 
AND src.Jaar = trg.Jaar
AND src.IsHydroJaar = trg.IsHydroJaar
AND src.simulatienr = trg.simulatienr)
WHEN MATCHED THEN UPDATE
	SET	 trg.[BRResultaatWID] 				= src.[BRResultaatWID] 			
		,trg.hg3mTAWPeilMeting1 			= src.hg3mTAWPeilMeting1 		
		,trg.hg3mTAWPeilMeting2 			= src.hg3mTAWPeilMeting2 		
		,trg.hg3mTAWPeilMeting3 			= src.hg3mTAWPeilMeting3 		
		,trg.hg3mTAWFout					= src.hg3mTAWFout				
		,trg.hg3mMaaiVeldPeilMeting1		= src.hg3mMaaiVeldPeilMeting1	
		,trg.hg3mMaaiveldPeilMeting2		= src.hg3mMaaiveldPeilMeting2	
		,trg.hg3mMaaiveldPeilMeting3		= src.hg3mMaaiveldPeilMeting3	
		,trg.hg3mMaaiveldFout 				= src.hg3mMaaiveldFout 			
		,trg.lg3mTAWPeilMeting1 			= src.lg3mTAWPeilMeting1 		
		,trg.lg3mTAWPeilMeting2 			= src.lg3mTAWPeilMeting2 		
		,trg.lg3mTAWPeilMeting3 			= src.lg3mTAWPeilMeting3 		
		,trg.lg3mTAWFout 					= src.lg3mTAWFout 				
		,trg.lg3mMaaiveldPeilMeting1 		= src.lg3mMaaiveldPeilMeting1 
		,trg.lg3mMaaiveldPeilMeting2 		= src.lg3mMaaiveldPeilMeting2 
		,trg.lg3mMaaiveldPeilMeting3 		= src.lg3mMaaiveldPeilMeting3 
		,trg.lg3mMaaiveldFout 				= src.lg3mMaaiveldFout 			
		,trg.vg3mTAWPeilMeting1 			= src.vg3mTAWPeilMeting1 		
		,trg.vg3mTAWPeilMeting2 			= src.vg3mTAWPeilMeting2 		
		,trg.vg3mTAWPeilMeting3 			= src.vg3mTAWPeilMeting3 		
		,trg.vg3mTAWFout 					= src.vg3mTAWFout 				
		,trg.gg3mTAWPeilMeting 				= src.gg3mTAWPeilMeting 			
		,trg.gg3mTAWFout 					= src.gg3mTAWFout 				
		,trg.gg3mMaaiveldPeilMeting 		= src.gg3mMaaiveldPeilMeting 			
		,trg.gg3mMaaiveldFout 				= src.gg3mMaaiveldFout 		
		,trg.vg3mMaaiveldPeilMeting1 		= src.vg3mMaaiveldPeilMeting1 
		,trg.vg3mMaaiveldPeilMeting2 		= src.vg3mMaaiveldPeilMeting2 
		,trg.vg3mMaaiveldPeilMeting3 		= src.vg3mMaaiveldPeilMeting3 
		,trg.vg3mMaaiveldFout 				= src.vg3mMaaiveldFout 			
		,trg.MinJmTAWPeilmeting				= src.MinJmTAWPeilmeting	
		,trg.MaxJmTAWPeilmeting				= src.MaxJmTAWPeilmeting	
		,trg.MinJmMaaiveldPeilmeting		= src.MinJmMaaiveldPeilmeting	
		,trg.MaxJmMaaiveldPeilmeting		= src.MaxJmMaaiveldPeilmeting
		,trg.ParamMinAantalMetingen 		= src.ParamMinAantalMetingen 	
		,trg.MaxRepresentatievePeriode 		= src.MaxRepresentatievePeriode 	
		,trg.GHG_Range 						= src.GHG_Range 					
		,trg.GLG_Range 						= src.GLG_Range 					
		,trg.GVG_Range 						= src.GVG_Range 					
WHEN NOT MATCHED BY TARGET THEN 
	INSERT (Meetpunt, Jaar, IsHydrojaar, simulatienr, BRResultaatWID , hg3mTAWPeilMeting1 , hg3mTAWPeilMeting2 , hg3mTAWPeilMeting3 , hg3mTAWFout, hg3mMaaiVeldPeilMeting1, hg3mMaaiveldPeilMeting2, hg3mMaaiveldPeilMeting3, hg3mMaaiveldFout , lg3mTAWPeilMeting1 , lg3mTAWPeilMeting2 , lg3mTAWPeilMeting3 , lg3mTAWFout , lg3mMaaiveldPeilMeting1 , lg3mMaaiveldPeilMeting2 , lg3mMaaiveldPeilMeting3 , lg3mMaaiveldFout , vg3mTAWPeilMeting1 , vg3mTAWPeilMeting2 , vg3mTAWPeilMeting3 , vg3mTAWFout , gg3mTAWPeilMeting , gg3mTAWFout , gg3mMaaiveldPeilMeting , gg3mMaaiveldFout , vg3mMaaiveldPeilMeting1 , vg3mMaaiveldPeilMeting2 , vg3mMaaiveldPeilMeting3 , vg3mMaaiveldFout , MinJmTAWPeilmeting, MaxJmTAWPeilmeting, MinJmMaaiveldPeilmeting, MaxJmMaaiveldPeilmeting, ParamMinAantalMetingen , MaxRepresentatievePeriode , GHG_Range , GLG_Range , GVG_Range  )
	VALUES (src.Meetpunt, src.Jaar, src.IsHydrojaar, src.simulatienr, src.BRResultaatWID , src.hg3mTAWPeilMeting1 , src.hg3mTAWPeilMeting2 , src.hg3mTAWPeilMeting3 , src.hg3mTAWFout, src.hg3mMaaiVeldPeilMeting1, src.hg3mMaaiveldPeilMeting2, src.hg3mMaaiveldPeilMeting3, src.hg3mMaaiveldFout , src.lg3mTAWPeilMeting1 , src.lg3mTAWPeilMeting2 , src.lg3mTAWPeilMeting3 , src.lg3mTAWFout , src.lg3mMaaiveldPeilMeting1 , src.lg3mMaaiveldPeilMeting2 , src.lg3mMaaiveldPeilMeting3 , src.lg3mMaaiveldFout , src.vg3mTAWPeilMeting1 , src.vg3mTAWPeilMeting2 , src.vg3mTAWPeilMeting3 , src.vg3mTAWFout , src.gg3mTAWPeilMeting , src.gg3mTAWFout , src.gg3mMaaiveldPeilMeting , src.gg3mMaaiveldFout, src.vg3mMaaiveldPeilMeting1 , src.vg3mMaaiveldPeilMeting2 , src.vg3mMaaiveldPeilMeting3 , src.vg3mMaaiveldFout , src.MinJmTAWPeilmeting, src.MaxJmTAWPeilmeting, src.MinJmMaaiveldPeilmeting, src.MaxJmMaaiveldPeilmeting, src.ParamMinAantalMetingen , src.MaxRepresentatievePeriode , src.GHG_Range , src.GLG_Range , src.GVG_Range );

-- toevoegen van xg3-waarden aan tbl_xg3
use D0136_00_Flaven
MERGE tbl_xg3 as trg
	USING (  SELECT 
			iif(max(fpeilen.hg3mMaaiveldPeilMeting1) is null, NULL, avg((fpeilen.hg3mMaaiveldPeilMeting1 + fpeilen.hg3mMaaiveldPeilMeting2 + fpeilen.hg3mMaaiveldPeilMeting3)/3)) as HG3_std
			, iif(max(fpeilen.lg3mMaaiveldPeilMeting1) is null, NULL, avg((fpeilen.lg3mMaaiveldPeilMeting1 + fpeilen.lg3mMaaiveldPeilMeting2 + fpeilen.lg3mMaaiveldPeilMeting3)/3)) as LG3_std
			, iif(max(fpeilen.vg3mMaaiveldPeilMeting1) is null, NULL, avg((fpeilen.vg3mMaaiveldPeilMeting1 + fpeilen.vg3mMaaiveldPeilMeting2 + fpeilen.vg3mMaaiveldPeilMeting3)/3)) as VG3_std
			, iif(max(fpeilen.gg3mMaaiveldPeilMeting) is null, NULL, avg(fpeilen.gg3mMaaiveldPeilMeting)) as GG3_std
			, iif(max(fpeilen.MinJmMaaiveldPeilMeting) is null, NULL, avg(fpeilen.MinJmMaaiveldPeilMeting)) as MinJ_std
			, iif(max(fpeilen.MaxJmMaaiveldPeilMeting) is null, NULL, avg(fpeilen.MaxJmMaaiveldPeilMeting)) as MaxJ_std
			, iif(max(fpeilen.hg3mMaaiveldPeilMeting1) is null, NULL, avg((iif( fpeilen.hg3mMaaiveldPeilMeting1 > 0, 0, fpeilen.hg3mMaaiveldPeilMeting1) + iif( fpeilen.hg3mMaaiveldPeilMeting2 > 0, 0, fpeilen.hg3mMaaiveldPeilMeting2) + iif( fpeilen.hg3mMaaiveldPeilMeting3 > 0, 0, fpeilen.hg3mMaaiveldPeilMeting3) ) /3)) as HG3_afgetopt
			, iif(max(fpeilen.lg3mMaaiveldPeilMeting1) is null, NULL, avg((iif( fpeilen.lg3mMaaiveldPeilMeting1 > 0, 0, fpeilen.lg3mMaaiveldPeilMeting1) + iif( fpeilen.lg3mMaaiveldPeilMeting2 > 0, 0, fpeilen.lg3mMaaiveldPeilMeting2) + iif( fpeilen.lg3mMaaiveldPeilMeting3 > 0, 0, fpeilen.lg3mMaaiveldPeilMeting3) ) /3)) as LG3_afgetopt
			, iif(max(fpeilen.vg3mMaaiveldPeilMeting1) is null, NULL, avg((iif( fpeilen.vg3mMaaiveldPeilMeting1 > 0, 0, fpeilen.vg3mMaaiveldPeilMeting1) + iif( fpeilen.vg3mMaaiveldPeilMeting2 > 0, 0, fpeilen.vg3mMaaiveldPeilMeting2) + iif( fpeilen.vg3mMaaiveldPeilMeting3 > 0, 0, fpeilen.vg3mMaaiveldPeilMeting3) ) /3)) as VG3_afgetopt
			, iif(max(fpeilen.gg3mMaaiveldPeilMeting) is null, NULL, avg(iif(fpeilen.gg3mMaaiveldPeilMeting > 0, 0, fpeilen.gg3mMaaiveldPeilMeting ))) as GG3_afgetopt
			, iif(max(fpeilen.MinJmMaaiveldPeilMeting) is null, NULL, avg(iif(fpeilen.MinJmMaaiveldPeilMeting > 0, 0, fpeilen.MinJmMaaiveldPeilMeting ))) as MinJ_afgetopt
			, iif(max(fpeilen.MaxJmMaaiveldPeilMeting) is null, NULL, avg(iif(fpeilen.MaxJmMaaiveldPeilMeting > 0, 0, fpeilen.MaxJmMaaiveldPeilMeting ))) as MaxJ_afgetopt
			, ParamMinAantalMetingen
			, MaxRepresentatievePeriode
			, GHG_Range
			, GVG_Range
			, GLG_Range	    
			, 1 as OokModelData 
			, Jaar
			, IsHydroJaar
			, Meetpunt
			FROM FactMENYPeilMetingJaar_Flaven fpeilen							
			group by Meetpunt, Jaar, IsHydroJaar, ParamMinAantalMetingen, MaxRepresentatievePeriode, GHG_Range, GVG_Range, GLG_Range
				) src
	ON (src.Meetpunt = trg.MeetpuntCode 
	AND src.Jaar = trg.Jaar
	AND src.IsHydroJaar = trg.IsHydroJaar
	AND src.ParamMinAantalMetingen = trg.MinAantalMetingen
	AND src.MaxRepresentatievePeriode = trg.MaxRepresentatievePeriode
	AND src.GHG_Range = trg.GHG_Range
	AND src.GLG_Range = trg.GLG_Range
	AND src.GVG_Range = trg.GVG_Range
	AND src.OokModelData = trg.OokModelData
	)
	WHEN MATCHED THEN UPDATE
		SET	 trg.HG3_std 			= src.HG3_std 			
			,trg.VG3_std			= src.VG3_std			
			,trg.LG3_std			= src.LG3_std			
			,trg.GG3_std			= src.GG3_std			
			,trg.minJ_std			= src.minJ_std			
			,trg.maxJ_std			= src.maxJ_std			
			,trg.HG3_afgetopt 		= src.HG3_afgetopt 	
			,trg.VG3_afgetopt		= src.VG3_afgetopt	
			,trg.LG3_afgetopt		= src.LG3_afgetopt	
			,trg.GG3_afgetopt		= src.GG3_afgetopt	
			,trg.minJ_afgetopt		= src.minJ_afgetopt	
			,trg.maxJ_afgetopt		= src.maxJ_afgetopt 		
	WHEN NOT MATCHED BY TARGET THEN 
		INSERT (MeetpuntCode, Jaar, IsHydrojaar, HG3_std , VG3_std, LG3_std, GG3_std, minJ_std, maxJ_std, HG3_afgetopt , VG3_afgetopt, LG3_afgetopt, GG3_afgetopt, minJ_afgetopt, maxJ_afgetopt, MinAantalMetingen , MaxRepresentatievePeriode , GHG_Range , GLG_Range , GVG_Range, OokModelData  )
		VALUES (src.Meetpunt, src.Jaar, src.IsHydrojaar, src.HG3_std , src.VG3_std, src.LG3_std, src.GG3_std, src.minJ_std, src.maxJ_std, src.HG3_afgetopt , src.VG3_afgetopt, src.LG3_afgetopt, src.GG3_afgetopt, src.minJ_afgetopt, src.maxJ_afgetopt, src.ParamMinAantalMetingen , src.MaxRepresentatievePeriode , src.GHG_Range , src.GLG_Range , src.GVG_Range, src.OokModeldata );
drop table if exists #tmpFactMENYPeilMetingJaar