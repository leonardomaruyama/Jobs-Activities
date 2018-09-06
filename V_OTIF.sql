CREATE OR REPLACE VIEW V_OTIF1 AS
WITH
-- VBFAR=VBFA+VBRK
VBFAR AS (
  SELECT VBELV, CASE WHEN vbrk.FKDAT NOT IN (' ','00000000') THEN vbrk.FKDAT END AS FKDAT, INCO1 INCOTERM, VTWEG, vbrk.KUNAG
       , round(sum(vbfa.RFMNG*decode(vbfa.VBTYP_N, 'N', -1, 1))) SUM_RFMNG
       , round(sum(vbfa.RFMNG/DECODE(vbfa.MEINS, 'LB', 2.2046, 1)*decode(vbfa.VBTYP_N, 'N', -1, 1)
         )) as QTdEntregue
    FROM SAPR3.VBFA@ZLP VBFA, sapr3.vbrk@zlp vbrk
   WHERE VBTYP_N IN ('M', 'N') AND FKSTO <> 'X' AND SFAKN = ' '
         AND vbfa.vbeln=vbrk.vbeln(+)
         --AND vbfa.vbeln=vbkd.vbeln(+)
   GROUP BY VBELV,vbrk.FKDAT, INCO1, VTWEG, vbrk.KUNAG
),
VBFAR_ITEM AS (
  SELECT VBELV, POSNV, FKDAT
       , round(sum(vbfa.RFMNG*decode(vbfa.VBTYP_N, 'N', -1, 1))) SUM_RFMNG
       , round(sum(vbfa.RFMNG/DECODE(vbfa.MEINS, 'LB', 2.2046, 1)*decode(vbfa.VBTYP_N, 'N', -1, 1)
         )) as QTdEntregueItem
    FROM SAPR3.VBFA@ZLP VBFA, sapr3.vbrk@zlp vbrk
   WHERE VBTYP_N IN ('M', 'N') AND FKSTO <> 'X' AND SFAKN = ' '
         AND vbfa.vbeln=vbrk.vbeln(+)
   GROUP BY POSNV, VBELV,FKDAT
),
VBAK AS (
  SELECT a.VBELN, a.ERDAT, a.AUART, a.KUNNR, a.BUKRS_VF, a.VDATU,
      CASE a.AUART
          WHEN 'YCS' THEN 'TRIANGULADA'
          WHEN 'YUS1' THEN 'TRIANGULADA'
          WHEN 'YUS6' THEN 'TRIANGULADA'
          WHEN 'YCSN' THEN 'TRIANGULADA'
          ELSE 'DIRETA'
      END TPVENDAS,
      CASE a.BUKRS_VF
        WHEN 'BE01' THEN 'EUROPE'
        WHEN 'PTX' THEN 'US'
        ELSE 'BRAZIL'
      END PAISFAT,
      CASE WHEN a.AUART NOT IN ('YCS','YUS1','YUS6','YCSN') THEN
        CASE a.BUKRS_VF
          WHEN 'BE01' THEN 'EUROPE'
          WHEN 'PTX' THEN 'US'
          ELSE 'BRAZIL'
        END
      ELSE 'BRAZIL' END EXPSITE, b.INCO1 INCOTERM
  FROM sapr3.vbak@zlp a, sapr3.vbkd@zlp b
  WHERE a.vbeln = b.vbeln (+)
),
FORNECEDOR as
(
select b.*, a.lifnr, a.name1
  from
  (
  select distinct a.vbeln, d.vgbel, a.parvw, a.kunnr, d.empst, a.lifnr, c.name1
    from sapr3.vbpa@zlp a, sapr3.vbrp@zlp b, sapr3.lfa1@zlp c, sapr3.lips@zlp d
   where a.mandt = '100'
     and d.erdat >= to_char(add_months(sysdate,-24),'YYYYMMDD')
     and a.lifnr <> ' '
     and a.parvw in ('TR', 'SP')
     and a.vbeln = b.vgbel
     and a.vbeln = d.vbeln
     and a.lifnr = c.lifnr
     --and d.vgbel='0000909664'
  ) a,

  (
  select distinct a.vbeln, c.vgbel, a.parvw, a.kunnr, c.empst
    from sapr3.vbpa@zlp a, sapr3.vbrp@zlp b, sapr3.lips@zlp c
   where a.mandt = '100'
     and a.kunnr <> ' '
     and c.erdat >= to_char(add_months(sysdate,-24),'YYYYMMDD')
     and a.parvw in ('SH', 'WE')
     and a.vbeln = b.vgbel
     and a.vbeln = c.vbeln
     --and c.vgbel='0000909664'
  ) b

 where a.vbeln(+) = b.vbeln
   and a.vgbel(+) = b.vgbel
)
SELECT
      vbap.VBELN as doc,
      vbak.kunnr,
      fornecedor.kunnr cod_recebedor,
      fornecedor.lifnr cod_fornecedor,
      fornecedor.name1 fornecedor,
      FORNECEDOR.empst destino,
      vbap.POSNR,
      vbap.MATNR as Material,
      vbfar.fkdat as DTFATURA,
      vbfar.kunag,
      --vbfar.incoterm inco1,
      --vbak.INCOTERM inco2,
      vbap.ZBSTDK as DTDESEJADA,
      vbap.VSTEL,
      CASE WHEN CASE WHEN vbak.AUART <> 'YKBB' THEN vbfar.INCOTERM ELSE vbak.INCOTERM END <> ' '
        THEN CASE WHEN vbak.AUART <> 'YKBB' THEN vbfar.INCOTERM ELSE vbak.INCOTERM END ELSE vbkd.INCO1 END INCOTERM,
      vbfar.VTWEG,
      vbak.TPVENDAS,
      vbak.PAISFAT,
      vbak.EXPSITE,
      case when vbap.ZBSTDK_PRMT not in ('00000000','99991231') and vbap.ZBSTDK_PRMT is not null then vbap.ZBSTDK_PRMT else vbfar.fkdat end as DTPrometid,
      TO_DATE(case when vbap.ZBSTDK_PRMT not in ('00000000','99991231') and vbap.ZBSTDK_PRMT is not null then vbap.ZBSTDK_PRMT else vbfar.fkdat end, 'YYYYMMDD') DataPrometida,
      -----ONTIME---------
      (case when ( to_number(decode(vbap.ZBSTDK_PRMT, '00000000', NULL, '99991231',
                   NULL,

                   --DtFat
/*                 CASE WHEN to_date(vbfar.fkdat,'yyyymmdd') IS NULL AND vbak.AUART IN ('YKBB') THEN to_date(vbak.vdatu,'yyyymmdd') ELSE to_date(vbfar.fkdat,'yyyymmdd') END
                   - to_date(vbap.ZBSTDK_PRMT,'yyyymmdd')))) between -7 and 0 then 1 else 0 end) as ONTIME,
*/
                   --BillingDt
                   CASE WHEN vbfar.FKDAT NOT IN (' ','00000000') THEN to_date(vbfar.FKDAT,'yyyymmdd') ELSE to_date(vbak.VDATU,'yyyymmdd') END
                   - to_date(vbap.ZBSTDK_PRMT,'yyyymmdd'))))
                   between CASE WHEN vbak.AUART NOT IN ('ZLVT','ZLVD ') THEN -7 ELSE -365 END and
                   CASE WHEN (CASE WHEN vbak.AUART <> 'YKBB' THEN vbfar.INCOTERM ELSE vbak.INCOTERM END) IN ('FOB') AND vbfar.VTWEG IN ('BR')  THEN 1
                        WHEN (CASE WHEN vbak.AUART <> 'YKBB' THEN vbfar.INCOTERM ELSE vbak.INCOTERM END) IN ('EXW', 'FCA') AND vbak.EXPSITE IN ('BRAZIL') THEN 1
                        WHEN (CASE WHEN vbak.AUART <> 'YKBB' THEN vbfar.INCOTERM ELSE vbak.INCOTERM END) IN ('EXW', 'FCA') AND vbak.EXPSITE IN ('EUROPE') THEN 1
                        WHEN (CASE WHEN vbak.AUART <> 'YKBB' THEN vbfar.INCOTERM ELSE vbak.INCOTERM END) IN ('EXW', 'FCA', 'CL3', 'CCL') AND vbak.EXPSITE IN ('US') THEN 1
                   ELSE 0 END
                   then 1 else 0 end) as ONTIME,

      -----DIFERENCA DAS DATAS------
/*                to_number(decode(vbap.ZBSTDK_PRMT, '00000000', NULL, '99991231', NULL, CASE WHEN to_date(vbfar.fkdat,'yyyymmdd') IS NULL AND vbak.AUART IN ('YKBB') THEN to_date(vbak.vdatu,'yyyymmdd') ELSE to_date(vbfar.fkdat,'yyyymmdd') END - to_date(vbap.ZBSTDK_PRMT,'yyyymmdd'))) as DIF,*/

      --BillingDt
      CASE WHEN vbfar.FKDAT NOT IN (' ','00000000')
        THEN to_number(decode(vbap.ZBSTDK_PRMT, '00000000', NULL, '99991231', NULL, to_date(vbfar.FKDAT,'yyyymmdd') - to_date(DECODE(vbap.ZBSTDK_PRMT, '00000000', NULL, '99991231', NULL,vbap.ZBSTDK_PRMT),'yyyymmdd')))
       ELSE
         to_number(decode(vbap.ZBSTDK_PRMT, '00000000', NULL, '99991231', NULL, to_date(vbak.vdatu,'yyyymmdd') - to_date(DECODE(vbap.ZBSTDK_PRMT, '00000000', NULL, '99991231', NULL,vbap.ZBSTDK_PRMT),'yyyymmdd')))
       END
       as DIF,

      -- to_date(vbfar.fkdat,'yyyymmdd')

      -------------
/*                CASE WHEN to_date(vbfar.fkdat,'yyyymmdd') IS NULL AND vbak.AUART IN ('YKBB') THEN to_date(vbak.vdatu,'yyyymmdd') ELSE to_date(vbfar.fkdat,'yyyymmdd') END as Dtfat,*/

      --BillingDt
      CASE WHEN vbfar.FKDAT NOT IN (' ','00000000') THEN to_date(DECODE(vbfar.FKDAT, '00000000', NULL, '99991231', NULL,vbfar.FKDAT),'yyyymmdd') ELSE to_date(DECODE(vbak.vdatu, '00000000', NULL, '99991231', NULL, vbfar.FKDAT),'yyyymmdd') END as DTFAT,
      to_date(DECODE(vbap.ZBSTDK_PRMT, '00000000', NULL, '99991231', NULL, ZBSTDK),'yyyymmdd') as DTDESEJAD,
      ----DTPROMETIDA-----
      /*(case when vbap.ZBSTDK_PRMT = '00000000' then to_date(99991231,'yyyymmdd')
            else to_date(vbap.ZBSTDK_PRMT,'yyyymmdd') end) as DTPrometida,*/
      to_date(DECODE(vbap.ZBSTDK_PRMT, '00000000', NULL, '99991231', NULL, ZBSTDK_PRMT),'yyyymmdd') as DTPROMETIDA,
      --INFULL------
      CASE WHEN (case when sum(QTdEntregue) IS NULL AND vbak.AUART IN ('YKBB') THEN round(SUM(vbap.KWMENG)) ELSE sum(SUM_RFMNG) END) >= round(sum(vbap.ZKWMENG_PRMT))
         THEN 1 ELSE 0 END AS INFULL,
      --QTDENTREGUE----
       case when sum(QTdEntregue) IS NULL AND vbak.AUART IN ('YKBB') THEN SUM(vbap.KWMENG) ELSE sum(QTdEntregue) END as QTdEntregue,
        case when sum(QTdEntregueItem) IS NULL AND vbak.AUART IN ('YKBB') THEN SUM(vbap.KWMENG) ELSE sum(QTdEntregueItem) END as QTdEntregueItem,
      --------------
      round(sum(vbap.ZKWMENG_PRMT/DECODE(vbap.MEINS, 'LB', 2.2046, 1))) as QtdPrometida,
      'KG' as UN,
      vbak.BUKRS_VF,
      vbak.AUART,
      vbap.ZMOTIVO,
      vbkd.BSTKD,
      to_date(DECODE(vbkd.BSTDK_E, '00000000', NULL, '99991231', NULL, vbkd.BSTDK_E),'yyyymmdd') DT_ESTIMADA
      --vbfar.VBTYP_N,
      --vbfar.MEINS
 FROM
     sapr3.VBAP@zlp VBAP, VBAK,
     (SELECT A.VBELV, B.POSNV, MAX(A.FKDAT) AS FKDAT, A.INCOTERM, A.VTWEG, A.KUNAG,
             SUM(A.QTdEntregue) QTdEntregue,
             SUM(A.SUM_RFMNG) SUM_RFMNG,
             SUM(B.QTdEntregueItem) QTdEntregueItem FROM VBFAR A, VBFAR_ITEM B
      WHERE A.VBELV=B.VBELV
      GROUP BY A.VBELV, B.POSNV, A.INCOTERM, A.VTWEG, A.KUNAG) VBFAR,
      FORNECEDOR, sapr3.vbkd@zlp vbkd
WHERE
      VBAP.VBELN NOT IN ('0000248638')
      AND VBAP.VBELN=VBFAR.VBELV(+)
      AND VBAP.POSNR=VBFAR.POSNV(+)
      AND VBAP.VBELN=VBAK.VBELN(+)
      AND VBAP.VBELN=VBKD.VBELN(+)
      AND VBAP.VBELN=FORNECEDOR.VGBEL(+)
      --REMOVER ORDEM DE SINISTRO 0000248638
group by
      vbap.VBELN,
      vbak.kunnr,
      vbap.VSTEL,
      vbap.POSNR,
      vbap.MATNR,
      vbfar.fkdat,
      vbfar.kunag,
      vbfar.incoterm,
      vbap.ZBSTDK,
      vbap.ZBSTDK_PRMT,
      vbak.BUKRS_VF,
      vbak.AUART,
      vbap.ZMOTIVO,
      vbak.vdatu,
      vbfar.INCOTERM,
      vbak.INCOTERM,
      vbfar.VTWEG,
      vbak.TPVENDAS,
      vbak.PAISFAT,
      vbak.EXPSITE,
      FORNECEDOR.kunnr,
      fornecedor.lifnr,
      fornecedor.name1,
      FORNECEDOR.empst,
      vbkd.INCO1,
      vbkd.BSTKD,
      vbkd.BSTDK_E
;
