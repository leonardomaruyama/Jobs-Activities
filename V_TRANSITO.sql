SELECT
       DOCCOMPRA,
       ITEMDOC,
       NREQ,
       ITEM,
       MATERIAL,
       UN,
       CENTRO_RECEP,
       CENTRO_FORNE,
       DEPOSITO,
       MATDESC,
       EMPRESA,
       DTREMESSA,
       SUM(TRANSITO) AS TRANSITO,
       SUM(TRANSITO_TRANSF) AS TRANSITO_TRANSF,
       SUM(MONTANTEMI) AS MONTANTEMI,
       SUM(VLIQUIDO) AS VLIQUIDO 
FROM
       ( SELECT   DISTINCT   
                  A.EBELN AS DOCCOMPRA,
                  C.EBELP AS ITEMDOC,
                  B.BANFN AS NREQ,
                  B.BNFPO AS ITEM,
                  B.MATNR AS MATERIAL,
                  D.MAKTX AS MATDESC,
                  B.MEINS AS UN,
                  B.WERKS AS CENTRO_RECEP,
                  --E.BWART AS TP_MOVIMENTO,
                  A.RESWK AS CENTRO_FORNE,
                  A.BUKRS AS EMPRESA,
                  B.LGORT AS DEPOSITO,
                  TO_DATE(C.EINDT,'YYYYMMDD') AS DTREMESSA,
                  CASE WHEN E.BWART IN ('641','Z62', 'Z61', '863') THEN 0 ELSE CASE WHEN B.RETPO = 'X' THEN ((C.WAMNG * -1) - (C.WEMNG)) ELSE ((C.WAMNG) - (C.WEMNG)) END END AS TRANSITO,
                  0 AS TRANSITO_TRANSF,
                  (B.NETWR) AS VLIQUIDO,
                  (B.NETWR) AS MONTANTEMI

       FROM SAPR3.EKKO@ZLP A, SAPR3.EKPO@ZLP B, SAPR3.EKET@ZLP C, SAPR3.MAKT@ZLP D, SAPR3.EKBE@ZLP E 
       WHERE
          A.MANDT = '100' AND
          --B.WERKS IN ('LVAQ','PTX','ANRU','LV02','EPLT') AND
          B.BSTYP IN ('F', 'L') AND
          A.RESWK IS NOT NULL AND
          C.WAMNG <> C.WEMNG AND
          LENGTH(B.MATNR) > 6 AND
          C.WAMNG <> 0 AND
          B.STAPO <> 'X' AND
          D.SPRAS = 'P' AND
          A.MANDT = B.MANDT AND
          A.MANDT = C.MANDT AND
          A.MANDT = D.MANDT AND
          A.MANDT = E.MANDT AND
          A.EBELN = B.EBELN AND
          A.EBELN = C.EBELN AND
          A.EBELN = E.EBELN AND
          B.EBELP = C.EBELP AND
          B.MATNR = D.MATNR AND
          B.MATNR = E.MATNR AND
          B.EBELP = E.EBELP AND
          E.BWART <> ' '  AND B.MATNR BETWEEN '1000000' AND '2009999' AND B.ELIKZ<>'X'
       UNION ALL
       SELECT   DISTINCT   
                  A.EBELN AS DOCCOMPRA,
                  C.EBELP AS ITEMDOC,
                  B.BANFN AS NREQ,
                  B.BNFPO AS ITEM,
                  B.MATNR AS MATERIAL,
                  D.MAKTX AS MATDESC,
                  B.MEINS AS UN,
                  B.WERKS AS CENTRO_RECEP,
                  --E.BWART AS TP_MOVIMENTO,
                  A.RESWK AS CENTRO_FORNE,
                  A.BUKRS AS EMPRESA,
                  B.LGORT AS DEPOSITO,
                  TO_DATE(C.EINDT,'YYYYMMDD') AS DTREMESSA,
                  0 AS TRANSITO,
                  CASE WHEN E.BWART IN ('641','Z62') THEN CASE WHEN B.RETPO = 'X' THEN ((C.WAMNG * -1) - (C.WEMNG)) ELSE ((C.WAMNG) - (C.WEMNG)) END ELSE 0 END AS TRANSITO_TRANSF,
                  (B.NETWR) AS VLIQUIDO,
                  (B.NETWR) AS MONTANTEMI

       FROM SAPR3.EKKO@ZLP A, SAPR3.EKPO@ZLP B, SAPR3.EKET@ZLP C, SAPR3.MAKT@ZLP D, SAPR3.EKBE@ZLP E 
       WHERE
          A.MANDT = '100' AND
          --B.WERKS IN ('LVAQ','PTX','ANRU','LV02','EPLT') AND
          B.BSTYP IN ('F', 'L') AND
          A.RESWK IS NOT NULL AND
          C.WAMNG <> C.WEMNG AND
          LENGTH(B.MATNR) > 6 AND
          C.WAMNG <> 0 AND
          B.STAPO <> 'X' AND
          D.SPRAS = 'P' AND
          A.MANDT = B.MANDT AND
          A.MANDT = C.MANDT AND
          A.MANDT = D.MANDT AND
          A.MANDT = E.MANDT AND
          A.EBELN = B.EBELN AND
          A.EBELN = C.EBELN AND
          A.EBELN = E.EBELN AND
          B.EBELP = C.EBELP AND
          B.MATNR = D.MATNR AND
          B.MATNR = E.MATNR AND
          B.EBELP = E.EBELP AND
          E.BWART <> ' '  AND B.MATNR BETWEEN '1000000' AND '2009999' AND B.ELIKZ<>'X'
          )
         -- GROUP BY A.EBELN, C.EBELP, B.BANFN, B.BNFPO, B.MATNR, D.MAKTX, B.MEINS, B.WERKS, A.BUKRS, B.RETPO, B.LGORT, C.EINDT, E.BWART, A.RESWK

 GROUP BY DOCCOMPRA, ITEMDOC, NREQ, ITEM, MATERIAL, MATDESC, UN, EMPRESA, DEPOSITO, DTREMESSA, CENTRO_RECEP, CENTRO_FORNE